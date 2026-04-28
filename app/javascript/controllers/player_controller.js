import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["audio", "playButton", "playIcon", "pauseIcon", "slider"]
  static outlets = ["modal"]

  connect() {
    if (!this.hasAudioTarget) return

    this.onTimeUpdate = this.onTimeUpdate.bind(this)
    this.onEnded = this.onEnded.bind(this)
    this.onPlay = this.showPauseIcon.bind(this)
    this.onPause = this.showPlayIcon.bind(this)

    this.audioTarget.addEventListener("timeupdate", this.onTimeUpdate)
    this.audioTarget.addEventListener("ended", this.onEnded)
    this.audioTarget.addEventListener("play", this.onPlay)
    this.audioTarget.addEventListener("pause", this.onPause)
  }

  disconnect() {
    if (!this.hasAudioTarget) return

    this.audioTarget.removeEventListener("timeupdate", this.onTimeUpdate)
    this.audioTarget.removeEventListener("ended", this.onEnded)
    this.audioTarget.removeEventListener("play", this.onPlay)
    this.audioTarget.removeEventListener("pause", this.onPause)
  }

  toggle() {
    if (!this.hasAudioTarget) return

    if (this.audioTarget.paused) {
      this.audioTarget.play()
    } else {
      this.audioTarget.pause()
    }
  }

  seek(event) {
    if (!this.hasAudioTarget || !this.audioTarget.duration) return

    const value = Number(event.target.value)
    this.audioTarget.currentTime = (value / 100) * this.audioTarget.duration
  }

  openDetails() {
    if (this.hasModalOutlet) this.modalOutlet.open()
  }

  onTimeUpdate() {
    if (!this.hasSliderTarget || !this.audioTarget.duration) return

    const percent = (this.audioTarget.currentTime / this.audioTarget.duration) * 100
    this.sliderTarget.value = percent
  }

  onEnded() {
    this.showPlayIcon()
    if (this.hasSliderTarget) this.sliderTarget.value = 0
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
