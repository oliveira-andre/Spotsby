import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["playButton", "playIcon", "pauseIcon", "slider"]
  static outlets = ["modal", "now-playing"]
  static values = {
    songId: String,
    slug: String,
    name: String,
    authors: String,
    imageUrl: String,
    audioUrl: String
  }

  connect() {
    this.onState = this.handleState.bind(this)
    this.onTimeUpdate = this.handleTimeUpdate.bind(this)
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

    if (this.audioUrlValue) {
      element.dispatchEvent(new CustomEvent("now-playing:load", {
        detail: {
          id: this.songIdValue,
          slug: this.slugValue,
          name: this.nameValue,
          authors: this.authorsValue,
          imageUrl: this.imageUrlValue,
          audioUrl: this.audioUrlValue,
          autoplay: true
        }
      }))
    }

    if (outlet.isPlaying) this.showPauseIcon()
    else this.showPlayIcon()
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
    if (!this.hasSliderTarget) return
    const { currentTime, duration } = event.detail || {}
    if (!duration) return
    this.sliderTarget.value = (currentTime / duration) * 100
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
