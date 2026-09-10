// Browser playback through the page's <audio> element. Owns everything that is
// specific to playing in a browser: fragment-first starts, prefetching the full
// file, resuming with #t=, and recovering from expired storage URLs.
//
// The now-playing controller drives it through the same small interface that
// NativeBackend implements, and hears back through the delegate callbacks:
// onPlay, onPause, onTimeUpdate(currentTime, duration), onEnded.
export default class WebAudioBackend {
  constructor(audio, prefetch, delegate) {
    this.audio = audio
    this.prefetch = prefetch || null
    this.delegate = delegate
    this.state = null
    this.fragmentMode = false
    this.fullAudioUrl = null
    this.swapping = false
    this.recoveryAttempts = 0

    this.onPlay = this.handlePlay.bind(this)
    this.onPause = this.handlePause.bind(this)
    this.onTimeUpdate = this.handleTimeUpdate.bind(this)
    this.onEnded = this.handleEnded.bind(this)
    this.onError = this.handleError.bind(this)
    this.onPrefetchCanPlay = this.handlePrefetchCanPlay.bind(this)
  }

  get isNative() { return false }

  connect() {
    this.audio.addEventListener("play", this.onPlay)
    this.audio.addEventListener("pause", this.onPause)
    this.audio.addEventListener("timeupdate", this.onTimeUpdate)
    this.audio.addEventListener("ended", this.onEnded)
    this.audio.addEventListener("error", this.onError)
    if (this.prefetch) this.prefetch.addEventListener("canplaythrough", this.onPrefetchCanPlay)
  }

  disconnect() {
    this.audio.removeEventListener("play", this.onPlay)
    this.audio.removeEventListener("pause", this.onPause)
    this.audio.removeEventListener("timeupdate", this.onTimeUpdate)
    this.audio.removeEventListener("ended", this.onEnded)
    this.audio.removeEventListener("error", this.onError)
    if (this.prefetch) this.prefetch.removeEventListener("canplaythrough", this.onPrefetchCanPlay)
  }

  // ---------- State ----------

  get hasSource() { return !!this.audio.src }
  get paused() { return this.audio.paused }
  get currentTime() { return this.audio.currentTime }
  get playbackRate() { return this.audio.playbackRate || 1 }

  get duration() {
    // In fragmentMode the element's duration is the fragment's (~15s). Report
    // the full song so the slider and lock screen don't reveal the fragment.
    return this.fragmentMode && this.state?.durationMs
      ? this.state.durationMs / 1000
      : this.audio.duration
  }

  get volume() { return this.audio.volume }
  set volume(value) { this.audio.volume = value }
  get muted() { return this.audio.muted }
  set muted(value) { this.audio.muted = value }

  // ---------- Commands ----------

  load(state, { autoplay = false } = {}) {
    this.state = state
    this.attach(state)
    if (autoplay) this.play()
  }

  play() {
    const result = this.audio.play()
    if (result && typeof result.catch === "function") result.catch(() => {})
  }

  pause() {
    this.audio.pause()
  }

  // Drop the source entirely (this device stopped being the active one).
  detach() {
    this.audio.pause()
    this.audio.removeAttribute("src")
    this.audio.load()
  }

  seek(seconds) {
    try { this.audio.currentTime = seconds } catch (_) {}
  }

  seekToPercent(percent) {
    // User initiated seek: switch out of fragment mode immediately. The fragment
    // only covers t=0..15, so seeking anywhere meaningful needs the full audio.
    if (this.fragmentMode && this.fullAudioUrl && this.state?.durationMs) {
      const fullDuration = this.state.durationMs / 1000
      const targetTime = (Number(percent) / 100) * fullDuration
      this.swapping = true
      const onPlaying = () => {
        this.audio.removeEventListener("playing", onPlaying)
        this.swapping = false
        this.fragmentMode = false
      }
      this.audio.addEventListener("playing", onPlaying)
      this.audio.src = `${this.fullAudioUrl}#t=${targetTime}`
      this.audio.load()
      this.play()
      return
    }
    if (!this.audio.duration) return
    this.audio.currentTime = (Number(percent) / 100) * this.audio.duration
  }

  // Repeat is handled by the controller on `ended`; nothing to prepare here.
  setRepeat() {}

  // ---------- Loading ----------

  attach(data) {
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
      this.audio.src = fragmentUrl
      this.audio.load()
      if (this.prefetch) {
        this.prefetch.src = audioUrl
        // preload="auto" causes the browser to start byte-Range-buffering now.
      }
    } else {
      this.fragmentMode = false
      this.fullAudioUrl = null
      this.audio.src = savedTime > 1 ? `${audioUrl}#t=${savedTime}` : audioUrl
      this.audio.load()
    }
  }

  handlePrefetchCanPlay() {
    if (!this.fragmentMode) return
    if (!this.fullAudioUrl) return

    const wasPlaying = !this.audio.paused
    const pos = this.audio.currentTime || 0
    this.swapping = true

    const onMetadata = () => {
      this.audio.removeEventListener("loadedmetadata", onMetadata)
      try { this.audio.currentTime = pos } catch (_) {}
      if (wasPlaying) this.play()
    }
    const onPlaying = () => {
      this.audio.removeEventListener("playing", onPlaying)
      this.swapping = false
      this.fragmentMode = false
    }

    this.audio.addEventListener("loadedmetadata", onMetadata)
    this.audio.addEventListener("playing", onPlaying)
    this.audio.src = this.fullAudioUrl
    this.audio.load()

    // If audio was paused (user paused mid-fragment), there will be no "playing"
    // event — clear the flags after a short tick so the next play works normally.
    if (!wasPlaying) {
      setTimeout(() => {
        this.audio.removeEventListener("playing", onPlaying)
        this.swapping = false
        this.fragmentMode = false
      }, 250)
    }
  }

  // ---------- Element events ----------

  handlePlay() {
    if (this.swapping) return
    this.delegate.onPlay()
  }

  handlePause() {
    if (this.swapping) return
    this.delegate.onPause()
  }

  handleTimeUpdate() {
    if (this.swapping) return
    // Healthy playback — clear the recovery budget so a future stall gets a
    // fresh set of retries.
    this.recoveryAttempts = 0
    this.delegate.onTimeUpdate(this.audio.currentTime, this.duration)
  }

  handleEnded() {
    // If the fragment ended before the prefetcher signaled canplaythrough
    // (very slow network), force the swap rather than advancing to the next
    // song — the user expected to keep hearing the same song.
    if (this.fragmentMode && this.fullAudioUrl) {
      const fallbackPos = this.audio.duration > 0
        ? Math.max(0, this.audio.duration - 0.5)
        : 14.5
      this.swapping = true
      const onPlaying = () => {
        this.audio.removeEventListener("playing", onPlaying)
        this.swapping = false
        this.fragmentMode = false
      }
      this.audio.addEventListener("playing", onPlaying)
      this.audio.src = this.fullAudioUrl
      this.audio.load()
      const onMetadata = () => {
        this.audio.removeEventListener("loadedmetadata", onMetadata)
        try { this.audio.currentTime = fallbackPos } catch (_) {}
        this.play()
      }
      this.audio.addEventListener("loadedmetadata", onMetadata)
      return
    }

    this.delegate.onEnded()
  }

  handleError() {
    // The <audio> element caches the disk URL it resolved the redirect to as
    // currentSrc. That signed URL expires (ActiveStorage service_urls_expire_in,
    // 5 min), so a resume after a long pause — once the browser has evicted the
    // buffered range — re-requests an expired URL and 404s, stalling playback.
    // Re-attach from the permanent redirect URL (state.audioUrl) to mint a fresh
    // disk URL and resume from the saved position.
    if (!this.delegate.isActive || this.swapping) return
    if (!this.state?.audioUrl) return

    const err = this.audio.error
    // Ignore user-initiated aborts and a deliberately cleared src (no media).
    if (!err || err.code === MediaError.MEDIA_ERR_ABORTED) return
    if (this.recoveryAttempts >= 3) return // give up rather than hammer the server

    this.recoveryAttempts += 1
    this.recover()
  }

  recover() {
    const resumeAt = Number(this.state.currentTime) || this.audio.currentTime || 0
    // Recovery always uses the full audio; the fragment is only for t=0 starts.
    this.fragmentMode = false
    this.fullAudioUrl = null
    this.audio.src = resumeAt > 1 ? `${this.state.audioUrl}#t=${resumeAt}` : this.state.audioUrl
    this.audio.load()
    // The error almost always surfaces on a resume attempt, so play through.
    this.play()
  }
}
