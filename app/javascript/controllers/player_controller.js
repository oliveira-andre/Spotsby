import { Controller } from "@hotwired/stimulus"

const FORCE_PLAY_KEY = "spotsby:force-play"

export default class extends Controller {
  static targets = ["playButton", "playIcon", "pauseIcon", "slider", "currentTime", "totalTime", "repeatButton", "volumeSlider", "volumeHighIcon", "volumeLowIcon", "volumeMuteIcon"]
  static outlets = ["modal", "now-playing"]
  static values = {
    songId: String,
    slug: String,
    name: String,
    authors: String,
    album: String,
    imageUrl: String,
    imageContentType: String,
    audioUrl: String,
    fragmentUrl: String,
    durationMs: Number
  }

  initialize() {
    this.onState = this.handleState.bind(this)
    this.onTimeUpdate = this.handleTimeUpdate.bind(this)
    this.onRepeat = this.handleRepeat.bind(this)
    this.onVolume = this.handleVolume.bind(this)
  }

  connect() {
    document.body.classList.add("is-big-player")
  }

  disconnect() {
    if (this.boundOutletElement) {
      this.boundOutletElement.removeEventListener("now-playing:state", this.onState)
      this.boundOutletElement.removeEventListener("now-playing:timeupdate", this.onTimeUpdate)
      this.boundOutletElement.removeEventListener("now-playing:repeat", this.onRepeat)
      this.boundOutletElement.removeEventListener("now-playing:volume", this.onVolume)
      this.boundOutletElement = null
    }
    document.body.classList.remove("is-big-player")
  }

  nowPlayingOutletConnected(outlet, element) {
    this.boundOutletElement = element
    element.addEventListener("now-playing:state", this.onState)
    element.addEventListener("now-playing:timeupdate", this.onTimeUpdate)
    element.addEventListener("now-playing:repeat", this.onRepeat)
    element.addEventListener("now-playing:volume", this.onVolume)
    this.applyRepeatState(outlet.repeat)
    this.applyVolumeState(outlet.volumePercent, outlet.isMuted)

    let autoplay = outlet.isPlaying
    try {
      if (sessionStorage.getItem(FORCE_PLAY_KEY) === "1") {
        autoplay = true
        sessionStorage.removeItem(FORCE_PLAY_KEY)
      }
    } catch (_) { /* storage unavailable — ignore */ }

    if (this.audioUrlValue) {
      element.dispatchEvent(new CustomEvent("now-playing:load", {
        detail: {
          id: this.songIdValue,
          slug: this.slugValue,
          name: this.nameValue,
          authors: this.authorsValue,
          album: this.albumValue,
          imageUrl: this.imageUrlValue,
          imageContentType: this.imageContentTypeValue,
          audioUrl: this.audioUrlValue,
          fragmentUrl: this.fragmentUrlValue,
          durationMs: this.durationMsValue,
          autoplay
        }
      }))
    }

    if (autoplay) this.showPauseIcon()
    else this.showPlayIcon()
  }

  prepareAdvance() {
    try {
      sessionStorage.setItem(FORCE_PLAY_KEY, "1")
    } catch (_) { /* storage unavailable — ignore */ }
  }

  requestNext() {
    if (this.hasNowPlayingOutlet) this.nowPlayingOutlet.requestNext()
  }

  requestPrevious() {
    if (this.hasNowPlayingOutlet) this.nowPlayingOutlet.requestPrevious()
  }

  nowPlayingOutletDisconnected(_outlet, element) {
    if (element === this.boundOutletElement) {
      element.removeEventListener("now-playing:state", this.onState)
      element.removeEventListener("now-playing:timeupdate", this.onTimeUpdate)
      element.removeEventListener("now-playing:repeat", this.onRepeat)
      element.removeEventListener("now-playing:volume", this.onVolume)
      this.boundOutletElement = null
    }
  }

  toggle() {
    if (this.hasNowPlayingOutlet) this.nowPlayingOutlet.toggle()
  }

  toggleRepeat() {
    if (this.hasNowPlayingOutlet) this.nowPlayingOutlet.toggleRepeat()
  }

  handleRepeat(event) {
    this.applyRepeatState(event.detail?.repeat)
  }

  applyRepeatState(on) {
    if (!this.hasRepeatButtonTarget) return
    this.repeatButtonTarget.classList.toggle("is-active", !!on)
    this.repeatButtonTarget.setAttribute("aria-label", on ? "Turn off repeat" : "Turn on repeat")
    this.repeatButtonTarget.setAttribute("aria-pressed", String(!!on))
  }

  changeVolume(event) {
    if (this.hasNowPlayingOutlet) this.nowPlayingOutlet.setVolume(event.target.value)
  }

  toggleMute() {
    if (this.hasNowPlayingOutlet) this.nowPlayingOutlet.toggleMute()
  }

  handleVolume(event) {
    this.applyVolumeState(Math.round((event.detail?.volume ?? 0) * 100), event.detail?.muted)
  }

  applyVolumeState(percent, muted) {
    const value = Number.isFinite(percent) ? percent : 100
    if (this.hasVolumeSliderTarget) this.volumeSliderTarget.value = value
    const effective = muted ? 0 : value

    if (this.hasVolumeHighIconTarget) this.volumeHighIconTarget.hidden = muted || effective < 50
    if (this.hasVolumeLowIconTarget) this.volumeLowIconTarget.hidden = muted || effective === 0 || effective >= 50
    if (this.hasVolumeMuteIconTarget) this.volumeMuteIconTarget.hidden = !muted && effective !== 0
  }

  seek(event) {
    if (this.hasNowPlayingOutlet) this.nowPlayingOutlet.seekToPercent(event.target.value)
  }

  openDetails() {
    if (this.hasModalOutlet) this.modalOutlet.open()
  }

  handleState(event) {
    if (event.detail?.playing) this.showPauseIcon()
    else this.showPlayIcon()
  }

  handleTimeUpdate(event) {
    const { currentTime, duration } = event.detail || {}
    if (!duration) return
    if (this.hasSliderTarget) this.sliderTarget.value = (currentTime / duration) * 100
    if (this.hasCurrentTimeTarget) this.currentTimeTarget.textContent = this.formatTime(currentTime)
    if (this.hasTotalTimeTarget) this.totalTimeTarget.textContent = this.formatTime(duration)
  }

  formatTime(seconds) {
    if (!Number.isFinite(seconds) || seconds < 0) return "0:00"
    const total = Math.floor(seconds)
    const m = Math.floor(total / 60)
    const s = total % 60
    return `${m}:${String(s).padStart(2, "0")}`
  }

  showPlayIcon() {
    if (this.hasPlayIconTarget) this.playIconTarget.hidden = false
    if (this.hasPauseIconTarget) this.pauseIconTarget.hidden = true
    if (this.hasPlayButtonTarget) this.playButtonTarget.setAttribute("aria-label", "Play")
  }

  showPauseIcon() {
    if (this.hasPlayIconTarget) this.playIconTarget.hidden = true
    if (this.hasPauseIconTarget) this.pauseIconTarget.hidden = false
    if (this.hasPlayButtonTarget) this.playButtonTarget.setAttribute("aria-label", "Pause")
  }
}
