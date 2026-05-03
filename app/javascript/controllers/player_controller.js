import { Controller } from "@hotwired/stimulus"

const FORCE_PLAY_KEY = "spotsby:force-play"

export default class extends Controller {
  static targets = ["playButton", "playIcon", "pauseIcon", "slider", "currentTime", "totalTime"]
  static outlets = ["modal", "now-playing"]
  static values = {
    songId: String,
    slug: String,
    name: String,
    authors: String,
    imageUrl: String,
    audioUrl: String
  }

  initialize() {
    this.onState = this.handleState.bind(this)
    this.onTimeUpdate = this.handleTimeUpdate.bind(this)
  }

  connect() {
    document.body.classList.add("is-big-player")
  }

  disconnect() {
    if (this.boundOutletElement) {
      this.boundOutletElement.removeEventListener("now-playing:state", this.onState)
      this.boundOutletElement.removeEventListener("now-playing:timeupdate", this.onTimeUpdate)
      this.boundOutletElement = null
    }
    document.body.classList.remove("is-big-player")
  }

  nowPlayingOutletConnected(outlet, element) {
    this.boundOutletElement = element
    element.addEventListener("now-playing:state", this.onState)
    element.addEventListener("now-playing:timeupdate", this.onTimeUpdate)

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
          imageUrl: this.imageUrlValue,
          audioUrl: this.audioUrlValue,
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

  nowPlayingOutletDisconnected(_outlet, element) {
    if (element === this.boundOutletElement) {
      element.removeEventListener("now-playing:state", this.onState)
      element.removeEventListener("now-playing:timeupdate", this.onTimeUpdate)
      this.boundOutletElement = null
    }
  }

  toggle() {
    if (this.hasNowPlayingOutlet) this.nowPlayingOutlet.toggle()
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
