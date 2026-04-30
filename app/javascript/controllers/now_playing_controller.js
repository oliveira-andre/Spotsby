import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "spotsby:now-playing"
const LAST_PAGE_KEY = "spotsby:last-page"
const PLAYER_PATH_PREFIX = "/players/"

export default class extends Controller {
  static targets = [
    "audio",
    "link",
    "image",
    "imagePlaceholder",
    "name",
    "authors",
    "playButton",
    "playIcon",
    "pauseIcon"
  ]

  connect() {
    this.onPlay = this.handlePlay.bind(this)
    this.onPause = this.handlePause.bind(this)
    this.onTimeUpdate = this.handleTimeUpdate.bind(this)
    this.onEnded = this.handleEnded.bind(this)
    this.onLoadEvent = this.handleLoadEvent.bind(this)
    this.onDocumentClick = this.trackLastPage.bind(this)

    this.audioTarget.addEventListener("play", this.onPlay)
    this.audioTarget.addEventListener("pause", this.onPause)
    this.audioTarget.addEventListener("timeupdate", this.onTimeUpdate)
    this.audioTarget.addEventListener("ended", this.onEnded)
    this.element.addEventListener("now-playing:load", this.onLoadEvent)
    document.addEventListener("click", this.onDocumentClick, true)

    this.restoreFromStorage()
  }

  disconnect() {
    this.audioTarget.removeEventListener("play", this.onPlay)
    this.audioTarget.removeEventListener("pause", this.onPause)
    this.audioTarget.removeEventListener("timeupdate", this.onTimeUpdate)
    this.audioTarget.removeEventListener("ended", this.onEnded)
    this.element.removeEventListener("now-playing:load", this.onLoadEvent)
    document.removeEventListener("click", this.onDocumentClick, true)
  }

  trackLastPage(event) {
    const link = event.target.closest("a[href][data-turbo-stream]")
    if (!link) return

    let url
    try {
      url = new URL(link.href, window.location.origin)
    } catch (_) {
      return
    }
    if (url.origin !== window.location.origin) return
    if (url.pathname.startsWith(PLAYER_PATH_PREFIX)) return

    try {
      sessionStorage.setItem(LAST_PAGE_KEY, url.pathname + url.search + url.hash)
    } catch (_) {
      // storage unavailable — ignore
    }
  }

  handleLoadEvent(event) {
    const detail = event.detail || {}
    const { audioUrl, autoplay = true } = detail
    if (!audioUrl) return

    if (this.state && this.state.audioUrl === audioUrl) {
      if (autoplay && this.audioTarget.paused) this.safePlay()
      return
    }

    this.loadSong(detail)
    if (autoplay) this.safePlay()
  }

  loadSong(data) {
    this.state = {
      id: data.id,
      slug: data.slug,
      name: data.name,
      authors: data.authors,
      imageUrl: data.imageUrl,
      audioUrl: data.audioUrl
    }
    this.renderMeta(this.state)
    this.audioTarget.src = data.audioUrl
    this.audioTarget.load()
    this.persist()
    this.show()
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
  }

  toggle() {
    if (!this.audioTarget.src) return
    if (this.audioTarget.paused) this.safePlay()
    else this.audioTarget.pause()
  }

  seekToPercent(percent) {
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

  handlePlay() {
    if (this.hasPlayIconTarget) this.playIconTarget.hidden = true
    if (this.hasPauseIconTarget) this.pauseIconTarget.hidden = false
    if (this.hasPlayButtonTarget) this.playButtonTarget.setAttribute("aria-label", "Pause")
    this.dispatch("state", { detail: { playing: true } })
  }

  handlePause() {
    if (this.hasPlayIconTarget) this.playIconTarget.hidden = false
    if (this.hasPauseIconTarget) this.pauseIconTarget.hidden = true
    if (this.hasPlayButtonTarget) this.playButtonTarget.setAttribute("aria-label", "Play")
    this.dispatch("state", { detail: { playing: false } })
  }

  handleTimeUpdate() {
    this.dispatch("timeupdate", {
      detail: {
        currentTime: this.audioTarget.currentTime,
        duration: this.audioTarget.duration
      }
    })
  }

  handleEnded() {
    this.dispatch("ended")
  }

  show() {
    this.element.hidden = false
    document.body.classList.add("has-minimal-player")
  }

  hide() {
    this.element.hidden = true
    document.body.classList.remove("has-minimal-player")
  }

  persist() {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(this.state))
    } catch (_) {
      // storage unavailable — ignore
    }
  }

  restoreFromStorage() {
    let raw
    try {
      raw = localStorage.getItem(STORAGE_KEY)
    } catch (_) {
      this.hide()
      return
    }
    if (!raw) {
      this.hide()
      return
    }

    let data
    try {
      data = JSON.parse(raw)
    } catch (_) {
      this.hide()
      return
    }
    if (!data || !data.audioUrl) {
      this.hide()
      return
    }

    this.state = data
    this.renderMeta(data)
    this.audioTarget.src = data.audioUrl
    this.audioTarget.load()
    this.show()
  }
}
