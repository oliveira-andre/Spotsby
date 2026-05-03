import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "spotsby:now-playing"
const NAV_STACK_KEY = "spotsby:nav-stack"
const NAV_STACK_MAX = 30

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

    this.seedNavStack()
    this.restoreFromStorage()
  }

  seedNavStack() {
    let stack = readNavStack()
    const here = window.location.pathname + window.location.search + window.location.hash
    if (stack.length === 0 || stack[stack.length - 1] !== here) {
      stack.push(here)
      writeNavStack(stack)
    }
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
    let stack = readNavStack()
    if (stack[stack.length - 1] !== dest) stack.push(dest)
    if (stack.length > NAV_STACK_MAX) stack = stack.slice(-NAV_STACK_MAX)
    writeNavStack(stack)
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
    this.advanceToNext()
  }

  advanceToNext() {
    try {
      sessionStorage.setItem("spotsby:force-play", "1")
    } catch (_) { /* storage unavailable — ignore */ }

    const token = document.querySelector('meta[name="csrf-token"]')?.content
    const form = document.createElement("form")
    form.method = "post"
    form.action = "/players/next"
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
