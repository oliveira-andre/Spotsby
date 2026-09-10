import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"
import WebAudioBackend from "playback/web_audio_backend"
import NativeBackend from "playback/native_backend"

const STORAGE_KEY = "spotsby:now-playing"
const REPEAT_KEY = "spotsby:repeat"
const VOLUME_KEY = "spotsby:volume"
const MUTED_KEY = "spotsby:muted"
const DEFAULT_VOLUME = 1
const NAV_STACK_KEY = "spotsby:nav-stack"
const NAV_STACK_MAX = 30
const HEARTBEAT_MS = 60_000

// The app advertises its bridge components in the user agent (same check the
// bridge library uses for `shouldLoad`). With a `player` component present,
// audio is played by the app and this controller only drives it.
const NATIVE_PLAYER = /bridge-components: \[[^\]]*\bplayer\b[^\]]*\]/.test(window.navigator.userAgent)

// Mini player + single owner of playback state for the page.
//
// Audio itself goes through a backend: WebAudioBackend (the <audio> element)
// in a browser, NativeBackend (the app's AVPlayer via the `player` bridge
// component) inside the iOS app. Everything above the backend — active-device
// sync, queue advancement in the browser, persistence, rendering — is shared.
export default class extends Controller {
  static targets = [
    "audio",
    "prefetch",
    "link",
    "image",
    "imagePlaceholder",
    "name",
    "authors",
    "playButton",
    "playIcon",
    "pauseIcon"
  ]

  // Other controllers reach this one as an outlet (the big player) and may do
  // so before connect() has run, so everything they read — the backend, the
  // repeat and volume preferences — is set up here, not in connect().
  initialize() {
    this.isActive = false
    this.isConnected = false
    this.pendingLoad = null
    this.lastPersistedAt = 0

    this.backend = NATIVE_PLAYER
      ? new NativeBackend(this.element, this.application, this)
      : new WebAudioBackend(this.audioTarget, this.hasPrefetchTarget ? this.prefetchTarget : null, this)
    this.repeat = readRepeat()
    this.applyVolume()

    this.onLoadEvent = this.handleLoadEvent.bind(this)
    this.onDocumentClick = this.trackLastPage.bind(this)
    this.onActiveChanged = this.handleActiveChanged.bind(this)
    this.onRemoteState = this.handleRemoteState.bind(this)
    this.onKeydown = this.handleKeydown.bind(this)

    // Kept for the life of the element: a load dispatched before connect()
    // is buffered and replayed once connected.
    this.element.addEventListener("now-playing:load", this.onLoadEvent)
    this.announcePendingLoaders()
  }

  // Song loaders that connected before this controller existed dispatched
  // into the void and kept their element; ask them again now that we listen.
  announcePendingLoaders() {
    document.querySelectorAll('[data-controller~="song-loader"]').forEach((el) => {
      this.application.getControllerForElementAndIdentifier(el, "song-loader")?.announce()
    })
  }

  connect() {
    this.backend.connect()

    document.addEventListener("click", this.onDocumentClick, true)
    document.addEventListener("keydown", this.onKeydown)
    window.addEventListener("now-playing:active-changed", this.onActiveChanged)
    window.addEventListener("now-playing:remote-state", this.onRemoteState)

    // Read active state directly — active_device_controller may have already
    // dispatched its event before we attached the listener (Stimulus doesn't
    // guarantee strict DOM-order connection).
    this.syncIsActive()

    this.backend.setRepeat(this.repeat)
    this.seedNavStack()
    this.restoreFromStorage()
    if (!this.backend.isNative) this.setupMediaSession()
    this.openCableSubscription()

    this.isConnected = true
    if (this.pendingLoad) {
      const detail = this.pendingLoad
      this.pendingLoad = null
      this.handleLoadEvent({ detail })
    }
  }

  syncIsActive() {
    const tracker = document.getElementById("now-playing-active-device")
    if (!tracker) return
    // This device's id is stable (meta tag); the tracker only names the active
    // session and gets broadcast-replaced identically on every device.
    const sessionId = document.querySelector('meta[name="session-id"]')?.content
    const activeId = tracker.dataset.activeDeviceActiveIdValue
    this.isActive = !!sessionId && sessionId === activeId
  }

  disconnect() {
    this.isConnected = false
    this.backend.disconnect()
    document.removeEventListener("click", this.onDocumentClick, true)
    document.removeEventListener("keydown", this.onKeydown)
    window.removeEventListener("now-playing:active-changed", this.onActiveChanged)
    window.removeEventListener("now-playing:remote-state", this.onRemoteState)

    if (this.heartbeatInterval) clearInterval(this.heartbeatInterval)
    if (this.cableSubscription) this.cableSubscription.unsubscribe()
  }

  // ---------- Cross-device sync ----------

  openCableSubscription() {
    try {
      const consumer = createConsumer()
      this.cableSubscription = consumer.subscriptions.create("NowPlayingChannel")
      this.heartbeatInterval = setInterval(() => {
        try { this.cableSubscription.perform("heartbeat") } catch (_) {}
      }, HEARTBEAT_MS)
    } catch (_) { /* websocket unavailable — ignore */ }
  }

  handleActiveChanged(event) {
    const next = !!event.detail?.active
    if (next === this.isActive) return

    const wasActive = this.isActive
    this.isActive = next

    if (wasActive && !next) {
      // Lost active — stop emitting audio.
      this.backend.detach()
    }
    if (!wasActive && next && this.state?.audioUrl && !this.backend.hasSource) {
      // Just became active; make sure audio is loaded so the next play click works.
      this.backend.load(this.state)
    }
  }

  handleRemoteState(event) {
    if (this.isActive) return // active owns playback; ignore echo

    const playing = !!event.detail?.playing
    this.renderPlayIcon(playing)
    if (!this.isActive) return
    if (!this.backend.hasSource) return
    if (playing && this.backend.paused) this.backend.play()
    if (!playing && !this.backend.paused) this.backend.pause()
  }

  claimActive() {
    return this.postRequest("/now_playing/play")
  }

  announcePause() {
    return this.postRequest("/now_playing/pause")
  }

  postRequest(url) {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    return fetch(url, {
      method: "POST",
      headers: {
        "X-CSRF-Token": token || "",
        "Accept": "text/vnd.turbo-stream.html"
      },
      credentials: "same-origin"
    }).then(async (response) => {
      if (response.ok && response.headers.get("content-type")?.includes("turbo-stream")) {
        const html = await response.text()
        if (window.Turbo?.renderStreamMessage) window.Turbo.renderStreamMessage(html)
      }
    }).catch(() => {})
  }

  // ---------- Keyboard ----------

  handleKeydown(event) {
    if (event.code !== "Space" && event.key !== " ") return
    // Don't hijack space while typing or when focus is on a clickable control
    // (the browser already maps space to "activate" there).
    const el = event.target
    if (el?.isContentEditable) return
    const tag = el?.tagName
    if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT") return
    if (el?.closest("button, a, [role='button'], [contenteditable='true']")) return
    if (!this.state) return

    event.preventDefault()
    this.toggle()
  }

  toggleRepeat() {
    this.repeat = !this.repeat
    writeRepeat(this.repeat)
    this.backend.setRepeat(this.repeat)
    this.dispatch("repeat", { detail: { repeat: this.repeat } })
  }

  // ---------- Volume ----------

  applyVolume() {
    this.backend.volume = readVolume()
    this.backend.muted = readMuted()
  }

  get volumePercent() {
    return Math.round(this.backend.volume * 100)
  }

  get isMuted() {
    return this.backend.muted
  }

  setVolume(percent) {
    const volume = clamp(Number(percent) / 100, 0, 1)
    this.backend.volume = volume
    // Sliding off zero implicitly unmutes; sliding to zero reads as muted.
    this.backend.muted = volume === 0
    writeVolume(volume)
    writeMuted(this.backend.muted)
    this.dispatch("volume", { detail: { volume, muted: this.backend.muted } })
  }

  toggleMute() {
    const muted = !this.backend.muted
    // Unmuting at zero volume would stay silent — restore a usable level.
    if (!muted && this.backend.volume === 0) {
      this.backend.volume = DEFAULT_VOLUME
      writeVolume(DEFAULT_VOLUME)
    }
    this.backend.muted = muted
    writeMuted(muted)
    this.dispatch("volume", { detail: { volume: this.backend.volume, muted } })
  }

  // ---------- Navigation stack (back link from the big player) ----------

  seedNavStack() {
    const here = window.location.pathname + window.location.search + window.location.hash
    if (isPlayerPath(here)) return

    let stack = readNavStack()
    if (stack.length === 0 || stack[stack.length - 1] !== here) {
      stack.push(here)
      writeNavStack(stack)
    }
  }

  trackLastPage(event) {
    const link = event.target.closest("a[href][data-turbo-stream]")
    if (!link) return
    const ctrls = (link.dataset.controller || "").split(/\s+/)
    if (ctrls.includes("back-link")) return

    let url
    try {
      url = new URL(link.href, window.location.origin)
    } catch (_) {
      return
    }
    if (url.origin !== window.location.origin) return

    const dest = url.pathname + url.search + url.hash
    if (isPlayerPath(dest)) return

    let stack = readNavStack()
    if (stack[stack.length - 1] !== dest) stack.push(dest)
    if (stack.length > NAV_STACK_MAX) stack = stack.slice(-NAV_STACK_MAX)
    writeNavStack(stack)
  }

  // ---------- Load / render ----------

  handleLoadEvent(event) {
    const detail = event.detail || {}
    const { audioUrl } = detail
    if (!audioUrl) return
    // Tell the loader its song was taken (see song_loader_controller).
    event.preventDefault?.()
    if (!this.isConnected) {
      this.pendingLoad = detail
      return
    }

    // Compare by id, not audioUrl — Active Storage signed URLs rotate per request.
    const sameSong = this.state?.id && detail.id && String(this.state.id) === String(detail.id)
    const shouldAutoplay = !!detail.autoplay

    this.loadMeta(detail, { sameSong })

    if (!this.isActive) {
      // Passive: show info only, do not load audio.
      return
    }

    if (sameSong && this.backend.hasSource) {
      if (shouldAutoplay && this.backend.paused) this.backend.play()
      return
    }
    // Either a new song, or restoreFromStorage hydrated state without attaching
    // audio (isActive was false when it ran). Load now so play has a source.
    this.backend.load(this.state, { autoplay: shouldAutoplay, explicit: !!detail.explicit })
  }

  loadMeta(data, { sameSong = false } = {}) {
    const preservedTime = sameSong ? (this.state?.currentTime || 0) : 0
    this.state = {
      id: data.id,
      slug: data.slug,
      name: data.name,
      authors: data.authors,
      album: data.album,
      imageUrl: data.imageUrl,
      imageContentType: data.imageContentType,
      audioUrl: data.audioUrl,
      fragmentUrl: data.fragmentUrl || null,
      durationMs: Number(data.durationMs) || 0,
      currentTime: preservedTime
    }
    this.renderMeta(this.state)
    this.updateMediaSessionMetadata(this.state)
    this.persist()
    this.show()
  }

  loadSong(data) {
    this.loadMeta(data)
    this.backend.load(this.state, { explicit: true })
  }

  renderMeta(data) {
    if (this.hasNameTarget) this.nameTarget.textContent = data.name || "Unknown"
    if (this.hasAuthorsTarget) this.authorsTarget.textContent = data.authors || "—"

    if (this.hasImageTarget) {
      if (data.imageUrl) {
        this.imageTarget.src = data.imageUrl
        this.imageTarget.hidden = false
        if (this.hasImagePlaceholderTarget) this.imagePlaceholderTarget.hidden = true
      } else {
        this.imageTarget.removeAttribute("src")
        this.imageTarget.hidden = true
        if (this.hasImagePlaceholderTarget) this.imagePlaceholderTarget.hidden = false
      }
    }

    if (this.hasLinkTarget) {
      const slug = data.slug || data.id
      this.linkTarget.href = slug ? `/players/${slug}` : "#"
    }

    this.updateDocumentTitle(data)
  }

  renderPlayIcon(playing) {
    if (this.hasPlayIconTarget) this.playIconTarget.hidden = playing
    if (this.hasPauseIconTarget) this.pauseIconTarget.hidden = !playing
    if (this.hasPlayButtonTarget) {
      this.playButtonTarget.setAttribute("aria-label", playing ? "Pause" : "Play")
    }
  }

  updateDocumentTitle(data) {
    const parts = [data?.name, data?.authors].filter((p) => p && p.length > 0)
    document.title = parts.length ? parts.join(" — ") : "Spotsby"
  }

  // ---------- MediaSession (browser only; the app uses Now Playing natively) ----------

  setupMediaSession() {
    if ("audioSession" in navigator) {
      try { navigator.audioSession.type = "playback" } catch (_) { /* iOS only */ }
    }
    if (!("mediaSession" in navigator)) return

    navigator.mediaSession.setActionHandler("play", () => this.toggle())
    navigator.mediaSession.setActionHandler("pause", () => this.toggle())
    navigator.mediaSession.setActionHandler("seekto", (details) => {
      if (typeof details.seekTime === "number") this.backend.seek(details.seekTime)
    })
    navigator.mediaSession.setActionHandler("nexttrack", () => this.requestNext())
  }

  updateMediaSessionMetadata(data) {
    if (this.backend.isNative) return
    if (!data || !("mediaSession" in navigator) || typeof MediaMetadata === "undefined") return

    const artwork = data.imageUrl
      ? [
          { src: data.imageUrl, sizes: "96x96", type: "image/jpeg" },
          { src: data.imageUrl, sizes: "192x192", type: "image/jpeg" },
          { src: data.imageUrl, sizes: "512x512", type: "image/jpeg" }
        ]
      : []

    navigator.mediaSession.metadata = new MediaMetadata({
      title: data.name || "Unknown",
      artist: data.authors || "Unknown",
      album: data.album || "",
      artwork
    })
  }

  setMediaSessionPlaybackState(state) {
    if (this.backend.isNative) return
    if ("mediaSession" in navigator) navigator.mediaSession.playbackState = state
  }

  setMediaSessionPosition(currentTime, duration) {
    if (this.backend.isNative) return
    if (!("mediaSession" in navigator) || !Number.isFinite(duration) || duration <= 0) return
    try {
      navigator.mediaSession.setPositionState({
        duration,
        position: Math.min(currentTime, duration),
        playbackRate: this.backend.playbackRate
      })
    } catch (_) { /* some browsers throw on invalid state */ }
  }

  // ---------- User actions ----------

  toggle() {
    if (!this.state) return
    if (!this.isActive) {
      if (!this.someoneIsActive()) {
        // No active device anywhere — claim it and play locally.
        this.claimActive()
        this.isActive = true
        this.ensureLoaded()
        this.backend.play()
        return
      }
      // Remote control: ask the active device to play/pause, don't play here.
      if (this.isShowingPlayIcon()) this.requestRemotePlay()
      else this.requestRemotePause()
      return
    }

    if (this.backend.paused) {
      this.ensureLoaded()
      this.backend.play()
      this.claimActive()
    } else {
      this.backend.pause()
      this.announcePause()
    }
  }

  ensureLoaded() {
    if (!this.backend.hasSource && this.state?.audioUrl) this.backend.load(this.state)
  }

  someoneIsActive() {
    const tracker = document.getElementById("now-playing-active-device")
    return !!tracker?.dataset.activeDeviceActiveIdValue
  }

  isShowingPlayIcon() {
    if (this.hasPauseIconTarget) return this.pauseIconTarget.hidden
    return true
  }

  requestRemotePlay() {
    return this.postRequest("/now_playing/play")
  }

  requestRemotePause() {
    return this.postRequest("/now_playing/pause")
  }

  requestNext() {
    if (this.backend.isNative) return this.backend.next()
    this.requestAdvance("/players/next")
  }

  requestPrevious() {
    if (this.backend.isNative) return this.backend.previous()
    this.requestAdvance("/players/previous")
  }

  requestAdvance(path) {
    this.submitForm(path)
  }

  submitForm(action) {
    try { sessionStorage.setItem("spotsby:force-play", "1") } catch (_) {}

    const token = document.querySelector('meta[name="csrf-token"]')?.content
    const form = document.createElement("form")
    form.method = "post"
    form.action = action
    form.style.display = "none"
    if (token) {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = "authenticity_token"
      input.value = token
      form.appendChild(input)
    }
    document.body.appendChild(form)
    form.requestSubmit()
  }

  seekToPercent(percent) {
    this.backend.seekToPercent(percent)
  }

  get isPlaying() {
    return !this.backend.paused
  }

  get currentSong() {
    return this.state || null
  }

  // ---------- Backend callbacks ----------

  onPlay() {
    this.renderPlayIcon(true)
    this.setMediaSessionPlaybackState("playing")
    this.updateMediaSessionMetadata(this.state)
    this.dispatch("state", { detail: { playing: true } })
  }

  onPause() {
    this.renderPlayIcon(false)
    this.setMediaSessionPlaybackState("paused")
    this.dispatch("state", { detail: { playing: false } })
  }

  onTimeUpdate(currentTime, duration) {
    // Persist currentTime so a fresh page load (audio element re-created) can
    // resume from where we left off. Throttle to ~1s to avoid hot writes.
    if (this.state) {
      this.state.currentTime = currentTime
      const now = Date.now()
      if (now - this.lastPersistedAt > 1000) {
        this.lastPersistedAt = now
        this.persist()
      }
    }

    this.setMediaSessionPosition(currentTime, duration)
    this.dispatch("timeupdate", { detail: { currentTime, duration } })
  }

  // Browser only: the app advances (or repeats) on its own when a track ends.
  onEnded() {
    this.dispatch("ended")
    if (!this.isActive) return // passive devices don't drive the queue forward
    if (this.repeat) {
      this.backend.seek(0)
      this.backend.play()
      return
    }
    this.requestNext()
  }

  // The app is playing a song this page doesn't know about yet: it advanced
  // while the page was frozen, or another tab picked a song. Adopt it, and if
  // this is the big player page, show that song instead of the stale one.
  onSongChanged(song) {
    this.loadMeta(song)

    const here = window.location.pathname
    if (!isPlayerPath(here) || !song.slug) return
    const target = `/players/${song.slug}`
    if (here === target) return
    window.Turbo?.visit(target, { action: "replace" })
  }

  onCleared() {
    this.state = null
    this.renderPlayIcon(false)
    this.hide()
  }

  onError(error) {
    this.renderPlayIcon(false)
    this.dispatch("error", { detail: error })
  }

  // ---------- UI show/hide + persistence ----------

  show() {
    this.element.hidden = false
    document.body.classList.add("has-minimal-player")
  }

  hide() {
    this.element.hidden = true
    document.body.classList.remove("has-minimal-player")
    document.title = "Spotsby"
  }

  persist() {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(this.state))
    } catch (_) { /* storage unavailable — ignore */ }
  }

  restoreFromStorage() {
    let raw
    try { raw = localStorage.getItem(STORAGE_KEY) } catch (_) { this.hide(); return }
    if (!raw) { this.hide(); return }

    let data
    try { data = JSON.parse(raw) } catch (_) { this.hide(); return }
    if (!data || !data.audioUrl) { this.hide(); return }

    this.state = data
    this.renderMeta(data)
    // Don't pre-attach audio — wait for the song_event partial to mount its
    // song_loader controller and fire now-playing:load with fresh fragmentUrl +
    // audioUrl + durationMs. That path routes through the backend which knows
    // when to play the fragment vs. resume with #t=savedTime.
    this.show()
  }
}

function readNavStack() {
  let raw
  try { raw = sessionStorage.getItem(NAV_STACK_KEY) } catch (_) { return [] }
  if (!raw) return []
  try {
    const parsed = JSON.parse(raw)
    return Array.isArray(parsed) ? parsed : []
  } catch (_) { return [] }
}

function writeNavStack(stack) {
  try { sessionStorage.setItem(NAV_STACK_KEY, JSON.stringify(stack)) } catch (_) {}
}

function isPlayerPath(path) {
  return /^\/players(\/|$|\?)/.test(path)
}

function readRepeat() {
  try { return localStorage.getItem(REPEAT_KEY) === "true" } catch (_) { return false }
}

function writeRepeat(on) {
  try { localStorage.setItem(REPEAT_KEY, on ? "true" : "false") } catch (_) {}
}

function readVolume() {
  let raw
  try { raw = localStorage.getItem(VOLUME_KEY) } catch (_) { return DEFAULT_VOLUME }
  if (raw === null) return DEFAULT_VOLUME
  const value = Number(raw)
  return Number.isFinite(value) ? clamp(value, 0, 1) : DEFAULT_VOLUME
}

function writeVolume(volume) {
  try { localStorage.setItem(VOLUME_KEY, String(volume)) } catch (_) {}
}

function readMuted() {
  try { return localStorage.getItem(MUTED_KEY) === "true" } catch (_) { return false }
}

function writeMuted(on) {
  try { localStorage.setItem(MUTED_KEY, on ? "true" : "false") } catch (_) {}
}

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value))
}
