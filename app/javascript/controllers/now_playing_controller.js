import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

const STORAGE_KEY = "spotsby:now-playing"
const REPEAT_KEY = "spotsby:repeat"
const NAV_STACK_KEY = "spotsby:nav-stack"
const NAV_STACK_MAX = 30
const HEARTBEAT_MS = 60_000

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

  initialize() {
    this.isActive = false
    this.swapping = false
    this.fragmentMode = false
    this.fullAudioUrl = null
    this.lastPersistedAt = 0
  }

  connect() {
    this.onPlay = this.handlePlay.bind(this)
    this.onPause = this.handlePause.bind(this)
    this.onTimeUpdate = this.handleTimeUpdate.bind(this)
    this.onEnded = this.handleEnded.bind(this)
    this.onLoadEvent = this.handleLoadEvent.bind(this)
    this.onDocumentClick = this.trackLastPage.bind(this)
    this.onActiveChanged = this.handleActiveChanged.bind(this)
    this.onRemoteState = this.handleRemoteState.bind(this)
    this.onPrefetchCanPlay = this.handlePrefetchCanPlay.bind(this)

    this.audioTarget.addEventListener("play", this.onPlay)
    this.audioTarget.addEventListener("pause", this.onPause)
    this.audioTarget.addEventListener("timeupdate", this.onTimeUpdate)
    this.audioTarget.addEventListener("ended", this.onEnded)
    if (this.hasPrefetchTarget) {
      this.prefetchTarget.addEventListener("canplaythrough", this.onPrefetchCanPlay)
    }
    this.element.addEventListener("now-playing:load", this.onLoadEvent)
    document.addEventListener("click", this.onDocumentClick, true)
    window.addEventListener("now-playing:active-changed", this.onActiveChanged)
    window.addEventListener("now-playing:remote-state", this.onRemoteState)

    // Read active state directly — active_device_controller may have already
    // dispatched its event before we attached the listener (Stimulus doesn't
    // guarantee strict DOM-order connection).
    this.syncIsActive()

    this.repeat = readRepeat()
    this.seedNavStack()
    this.restoreFromStorage()
    this.setupMediaSession()
    this.openCableSubscription()
  }

  syncIsActive() {
    const tracker = document.getElementById("now-playing-active-device")
    if (!tracker) return
    const sessionId = tracker.dataset.activeDeviceSessionIdValue
    const activeId = tracker.dataset.activeDeviceActiveIdValue
    this.isActive = !!sessionId && sessionId === activeId
  }

  disconnect() {
    this.audioTarget.removeEventListener("play", this.onPlay)
    this.audioTarget.removeEventListener("pause", this.onPause)
    this.audioTarget.removeEventListener("timeupdate", this.onTimeUpdate)
    this.audioTarget.removeEventListener("ended", this.onEnded)
    if (this.hasPrefetchTarget) {
      this.prefetchTarget.removeEventListener("canplaythrough", this.onPrefetchCanPlay)
    }
    this.element.removeEventListener("now-playing:load", this.onLoadEvent)
    document.removeEventListener("click", this.onDocumentClick, true)
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
      this.audioTarget.pause()
      this.audioTarget.removeAttribute("src")
      this.audioTarget.load()
    }
    if (!wasActive && next && this.state?.audioUrl && !this.audioTarget.src) {
      // Just became active; make sure audio is loaded so the next play click works.
      this.attachAudio(this.state)
    }
  }

  handleRemoteState(event) {
    if (this.isActive) return // active owns playback; ignore echo

    const playing = !!event.detail?.playing
    this.renderPlayIcon(playing)
    if (!this.isActive) return
    if (!this.audioTarget.src) return
    if (playing && this.audioTarget.paused) this.safePlay()
    if (!playing && !this.audioTarget.paused) this.audioTarget.pause()
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

  // ---------- Existing audio + nav stack logic (unchanged) ----------

  toggleRepeat() {
    this.repeat = !this.repeat
    writeRepeat(this.repeat)
    this.dispatch("repeat", { detail: { repeat: this.repeat } })
  }

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

    // Compare by id, not audioUrl — Active Storage signed URLs rotate per request.
    const sameSong = this.state?.id && detail.id && this.state.id === detail.id
    const shouldAutoplay = !!detail.autoplay

    this.loadMeta(detail, { sameSong })

    if (!this.isActive) {
      // Passive: show info only, do not load audio src.
      return
    }

    if (sameSong) {
      // restoreFromStorage hydrated state but didn't attach audio (isActive was false
      // when it ran). Attach now so the first user-gesture play has a source.
      if (!this.audioTarget.src) this.attachAudio(this.state)
      if (shouldAutoplay && this.audioTarget.paused) this.safePlay()
      return
    }
    this.attachAudio(this.state)
    if (shouldAutoplay) this.safePlay()
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

  attachAudio(data) {
    const savedTime = Number(data.currentTime) || 0
    const fragmentUrl = data.fragmentUrl
    const audioUrl = data.audioUrl
    if (!audioUrl) return

    // Fragment-first only when starting from the beginning. The fragment is from
    // t=0; using it mid-song would jump audibly. Resume from a saved position
    // goes straight to the full URL with #t= and accepts the brief load delay.
    if (fragmentUrl && savedTime < 1) {
      this.fragmentMode = true
      this.fullAudioUrl = audioUrl
      this.audioTarget.src = fragmentUrl
      this.audioTarget.load()
      if (this.hasPrefetchTarget) {
        this.prefetchTarget.src = audioUrl
        // preload="auto" causes the browser to start byte-Range-buffering now.
      }
    } else {
      this.fragmentMode = false
      this.fullAudioUrl = null
      this.audioTarget.src = savedTime > 1 ? `${audioUrl}#t=${savedTime}` : audioUrl
      this.audioTarget.load()
    }
  }

  handlePrefetchCanPlay() {
    if (!this.fragmentMode) return
    if (!this.fullAudioUrl) return

    const wasPlaying = !this.audioTarget.paused
    const pos = this.audioTarget.currentTime || 0
    this.swapping = true

    const onMetadata = () => {
      this.audioTarget.removeEventListener("loadedmetadata", onMetadata)
      try { this.audioTarget.currentTime = pos } catch (_) {}
      if (wasPlaying) this.safePlay()
    }
    const onPlaying = () => {
      this.audioTarget.removeEventListener("playing", onPlaying)
      this.swapping = false
      this.fragmentMode = false
    }

    this.audioTarget.addEventListener("loadedmetadata", onMetadata)
    this.audioTarget.addEventListener("playing", onPlaying)
    this.audioTarget.src = this.fullAudioUrl
    this.audioTarget.load()

    // If audio was paused (user paused mid-fragment), there will be no "playing"
    // event — clear the flags after a short tick so the next play works normally.
    if (!wasPlaying) {
      setTimeout(() => {
        this.audioTarget.removeEventListener("playing", onPlaying)
        this.swapping = false
        this.fragmentMode = false
      }, 250)
    }
  }

  loadSong(data) {
    this.loadMeta(data)
    this.attachAudio(data)
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

  setupMediaSession() {
    if ("audioSession" in navigator) {
      try { navigator.audioSession.type = "playback" } catch (_) { /* iOS only */ }
    }
    if (!("mediaSession" in navigator)) return

    navigator.mediaSession.setActionHandler("play", () => this.toggle())
    navigator.mediaSession.setActionHandler("pause", () => this.toggle())
    navigator.mediaSession.setActionHandler("seekto", (details) => {
      if (typeof details.seekTime === "number") this.audioTarget.currentTime = details.seekTime
    })
    navigator.mediaSession.setActionHandler("nexttrack", () => this.requestNext())
  }

  updateMediaSessionMetadata(data) {
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

  // ---------- User actions ----------

  toggle() {
    if (!this.state) return
    if (!this.isActive) {
      if (!this.someoneIsActive()) {
        // No active device anywhere — claim it and play locally.
        this.claimActive()
        if (!this.audioTarget.src && this.state.audioUrl) this.attachAudio(this.state)
        this.isActive = true
        this.safePlay()
        return
      }
      // Remote control: ask the active device to play/pause, don't play here.
      if (this.isShowingPlayIcon()) this.requestRemotePlay()
      else this.requestRemotePause()
      return
    }

    if (this.audioTarget.paused) {
      if (!this.audioTarget.src && this.state.audioUrl) this.attachAudio(this.state)
      this.safePlay()
      this.claimActive()
    } else {
      this.audioTarget.pause()
      this.announcePause()
    }
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
    this.requestAdvance("/players/next")
  }

  requestPrevious() {
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
    // User initiated seek: switch out of fragment mode immediately. The fragment
    // only covers t=0..15, so seeking anywhere meaningful needs the full audio.
    if (this.fragmentMode && this.fullAudioUrl && this.state?.durationMs) {
      const fullDuration = this.state.durationMs / 1000
      const targetTime = (Number(percent) / 100) * fullDuration
      this.swapping = true
      const onPlaying = () => {
        this.audioTarget.removeEventListener("playing", onPlaying)
        this.swapping = false
        this.fragmentMode = false
      }
      this.audioTarget.addEventListener("playing", onPlaying)
      this.audioTarget.src = `${this.fullAudioUrl}#t=${targetTime}`
      this.audioTarget.load()
      this.safePlay()
      return
    }
    if (!this.audioTarget.duration) return
    this.audioTarget.currentTime = (Number(percent) / 100) * this.audioTarget.duration
  }

  safePlay() {
    const result = this.audioTarget.play()
    if (result && typeof result.catch === "function") result.catch(() => {})
  }

  get isPlaying() {
    return !this.audioTarget.paused
  }

  get currentSong() {
    return this.state || null
  }

  // ---------- Audio element events ----------

  handlePlay() {
    if (this.swapping) return
    this.renderPlayIcon(true)
    if ("mediaSession" in navigator) navigator.mediaSession.playbackState = "playing"
    this.updateMediaSessionMetadata(this.state)
    this.dispatch("state", { detail: { playing: true } })
  }

  handlePause() {
    if (this.swapping) return
    this.renderPlayIcon(false)
    if ("mediaSession" in navigator) navigator.mediaSession.playbackState = "paused"
    this.dispatch("state", { detail: { playing: false } })
  }

  handleTimeUpdate() {
    if (this.swapping) return
    const { currentTime } = this.audioTarget
    // In fragmentMode, the audio element's duration is the fragment's (~15s).
    // The slider and lock-screen progress should reflect the full song duration
    // so the UX doesn't reveal the fragment.
    const reportedDuration = this.fragmentMode && this.state?.durationMs
      ? this.state.durationMs / 1000
      : this.audioTarget.duration

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

    if ("mediaSession" in navigator && Number.isFinite(reportedDuration) && reportedDuration > 0) {
      try {
        navigator.mediaSession.setPositionState({
          duration: reportedDuration,
          position: Math.min(currentTime, reportedDuration),
          playbackRate: this.audioTarget.playbackRate || 1
        })
      } catch (_) { /* some browsers throw on invalid state */ }
    }
    this.dispatch("timeupdate", { detail: { currentTime, duration: reportedDuration } })
  }

  handleEnded() {
    // If the fragment ended before the prefetcher signaled canplaythrough
    // (very slow network), force the swap rather than advancing to the next
    // song — the user expected to keep hearing the same song.
    if (this.fragmentMode && this.fullAudioUrl) {
      const fallbackPos = this.audioTarget.duration > 0
        ? Math.max(0, this.audioTarget.duration - 0.5)
        : 14.5
      this.swapping = true
      const onPlaying = () => {
        this.audioTarget.removeEventListener("playing", onPlaying)
        this.swapping = false
        this.fragmentMode = false
      }
      this.audioTarget.addEventListener("playing", onPlaying)
      this.audioTarget.src = this.fullAudioUrl
      this.audioTarget.load()
      const onMetadata = () => {
        this.audioTarget.removeEventListener("loadedmetadata", onMetadata)
        try { this.audioTarget.currentTime = fallbackPos } catch (_) {}
        this.safePlay()
      }
      this.audioTarget.addEventListener("loadedmetadata", onMetadata)
      return
    }

    this.dispatch("ended")
    if (!this.isActive) return // passive devices don't drive the queue forward
    if (this.repeat) {
      this.audioTarget.currentTime = 0
      this.safePlay()
      return
    }
    this.requestNext()
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
    // Don't pre-attach audio src — wait for the song_event partial to mount its
    // song_loader controller and fire now-playing:load with fresh fragmentUrl +
    // audioUrl + durationMs. That path routes through attachAudio which knows
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
