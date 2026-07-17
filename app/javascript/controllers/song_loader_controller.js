import { Controller } from "@hotwired/stimulus"

const FORCE_PLAY_KEY = "spotsby:force-play"

export default class extends Controller {
  static values = {
    selector: { type: String, default: "#minimal-player" },
    id: String,
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

  connect() {
    const target = document.querySelector(this.selectorValue)
    if (target && this.audioUrlValue) {
      target.dispatchEvent(new CustomEvent("now-playing:load", {
        detail: {
          id: this.idValue,
          slug: this.slugValue,
          name: this.nameValue,
          authors: this.authorsValue,
          album: this.albumValue,
          imageUrl: this.imageUrlValue,
          imageContentType: this.imageContentTypeValue,
          audioUrl: this.audioUrlValue,
          fragmentUrl: this.fragmentUrlValue,
          durationMs: this.durationMsValue,
          autoplay: this.shouldAutoplay(target)
        }
      }))
    }

    if (this.slugValue && /^\/players(\/|$)/.test(window.location.pathname)) {
      window.history.replaceState({}, "", `/players/${this.slugValue}`)
    }

    this.element.remove()
  }

  shouldAutoplay(target) {
    const tracker = document.getElementById("now-playing-active-device")
    const sessionId = document.querySelector('meta[name="session-id"]')?.content
    const activeId = tracker?.dataset.activeDeviceActiveIdValue
    const isCurrentDevice = !!sessionId && sessionId === activeId
    if (!isCurrentDevice) return false

    // Set by submitForm right before /players/next|previous is posted. Needed
    // because by the time this mount runs, audio.paused is true (the `ended`
    // event already fired), so the "is it already playing" heuristic alone
    // misses the advance case on pages without #player.
    try {
      if (sessionStorage.getItem(FORCE_PLAY_KEY) === "1") {
        sessionStorage.removeItem(FORCE_PLAY_KEY)
        return true
      }
    } catch (_) { /* storage unavailable — ignore */ }

    const audio = target.querySelector("audio")
    return !!audio && !audio.paused
  }
}
