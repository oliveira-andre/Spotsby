import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["playButton", "playIcon", "pauseIcon", "songRow"]
  static outlets = ["now-playing"]
  static values = {
    songIds: Array,
    firstId: String,
    firstSlug: String,
    firstName: String,
    firstAuthors: String,
    firstImageUrl: String,
    firstAudioUrl: String
  }

  initialize() {
    this.onState = this.handleState.bind(this)
  }

  nowPlayingOutletConnected(outlet, element) {
    this.boundOutletElement = element
    element.addEventListener("now-playing:state", this.onState)
    this.refresh(outlet, outlet.isPlaying)
  }

  nowPlayingOutletDisconnected(_outlet, element) {
    if (element === this.boundOutletElement) {
      element.removeEventListener("now-playing:state", this.onState)
      this.boundOutletElement = null
    }
    this.clearRows()
    this.showPlayIcon()
  }

  toggle() {
    if (!this.hasNowPlayingOutlet) return

    if (this.currentSongInAlbum(this.nowPlayingOutlet)) {
      this.nowPlayingOutlet.toggle()
      return
    }

    if (!this.firstAudioUrlValue) return

    this.boundOutletElement.dispatchEvent(new CustomEvent("now-playing:load", {
      detail: {
        id: this.firstIdValue,
        slug: this.firstSlugValue,
        name: this.firstNameValue,
        authors: this.firstAuthorsValue,
        imageUrl: this.firstImageUrlValue,
        audioUrl: this.firstAudioUrlValue,
        autoplay: true
      }
    }))
  }

  handleState(event) {
    if (!this.hasNowPlayingOutlet) return
    this.refresh(this.nowPlayingOutlet, !!event.detail?.playing)
  }

  refresh(outlet, playing) {
    const inAlbum = this.currentSongInAlbum(outlet)
    if (playing && inAlbum) this.showPauseIcon()
    else this.showPlayIcon()
    this.markRows(outlet, playing && inAlbum ? "playing" : (inAlbum ? "paused" : null))
  }

  markRows(outlet, mode) {
    const currentId = outlet?.currentSong?.id ? String(outlet.currentSong.id) : null
    this.songRowTargets.forEach((row) => {
      const isCurrent = mode && currentId && row.dataset.songId === currentId
      row.classList.toggle("is-selected", !!isCurrent)
      row.classList.toggle("is-playing", isCurrent && mode === "playing")
      row.classList.toggle("is-paused", isCurrent && mode === "paused")
    })
  }

  clearRows() {
    this.songRowTargets.forEach((row) => {
      row.classList.remove("is-selected", "is-playing", "is-paused")
    })
  }

  currentSongInAlbum(outlet) {
    const current = outlet?.currentSong
    if (!current || !current.id) return false
    return this.songIdsValue.includes(String(current.id))
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
