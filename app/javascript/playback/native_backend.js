// Playback through the native app (Hotwire Native). Commands go to the
// `bridge--player` Stimulus controller mounted on the same element; the app
// answers with `native-player:state` events, which are mirrored here and
// turned into the same delegate callbacks WebAudioBackend uses.
//
// The app owns the truth about what is loaded and playing. Several web views
// (one per native tab) share one app player, so this backend never assumes it
// is the only page talking to it.
export default class NativeBackend {
  constructor(element, application, delegate) {
    this.element = element
    this.application = application
    this.delegate = delegate
    this.native = { song: null, playing: false, position: 0, duration: 0, repeat: false }
    this.onState = this.handleState.bind(this)
  }

  get isNative() { return true }

  connect() {
    this.element.addEventListener("native-player:state", this.onState)
  }

  disconnect() {
    this.element.removeEventListener("native-player:state", this.onState)
  }

  get bridge() {
    return this.application.getControllerForElementAndIdentifier(this.element, "bridge--player")
  }

  // ---------- State (mirror of the app's) ----------

  get hasSource() { return !!this.native.song }
  get paused() { return !this.native.playing }
  get currentTime() { return this.native.position || 0 }
  get playbackRate() { return 1 }

  get duration() {
    if (this.native.duration) return this.native.duration
    return (Number(this.native.song?.durationMs) || 0) / 1000
  }

  // Volume is the hardware volume in the app; nothing to control from the page.
  get volume() { return 1 }
  set volume(_value) {}
  get muted() { return false }
  set muted(_value) {}

  // ---------- Commands ----------

  // `explicit` marks a song the user chose on this page (opened the big player).
  // Without it, a load that doesn't autoplay is the page seed — the last song in
  // history, rendered on every page — and must not replace what the app is
  // already playing. In that case the page adopts the app's song instead.
  load(state, { autoplay = false, explicit = false } = {}) {
    const current = this.native.song
    if (current && !autoplay && !explicit && String(current.id) !== String(state.id)) {
      this.delegate.onSongChanged(current)
      return
    }

    this.bridge?.load({
      id: String(state.id),
      slug: state.slug || null,
      name: state.name || null,
      authors: state.authors || null,
      album: state.album || null,
      imageUrl: state.imageUrl || null,
      audioUrl: state.audioUrl,
      durationMs: Number(state.durationMs) || 0,
      position: Number(state.currentTime) || 0,
      autoplay: !!autoplay,
      repeat: !!this.delegate.repeat
    })
  }

  play() { this.bridge?.play() }
  pause() { this.bridge?.pause() }
  detach() { this.bridge?.pause() }
  seek(seconds) { this.bridge?.seek(seconds) }

  seekToPercent(percent) {
    const duration = this.duration
    if (!duration) return
    this.seek((Number(percent) / 100) * duration)
  }

  setRepeat(on) { this.bridge?.setRepeat(on) }
  next() { this.bridge?.next() }
  previous() { this.bridge?.previous() }

  // ---------- State pushes from the app ----------

  handleState(event) {
    const next = event.detail || {}
    const prev = this.native
    this.native = {
      song: next.song || null,
      playing: !!next.playing,
      position: Number(next.position) || 0,
      duration: Number(next.duration) || 0,
      repeat: !!next.repeat
    }

    if (this.native.song) {
      const known = this.delegate.state
      if (!known || String(known.id) !== String(this.native.song.id)) {
        this.delegate.onSongChanged(this.native.song)
      }
    } else if (prev.song) {
      this.delegate.onCleared()
    }

    if (this.native.playing !== prev.playing) {
      if (this.native.playing) this.delegate.onPlay()
      else this.delegate.onPause()
    }

    if (this.native.song) this.delegate.onTimeUpdate(this.native.position, this.duration)
    if (next.error) this.delegate.onError(next.error)
  }
}
