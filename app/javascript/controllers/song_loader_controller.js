import { Controller } from "@hotwired/stimulus"

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
    audioUrl: String
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
    const sessionId = tracker?.dataset.activeDeviceSessionIdValue
    const activeId = tracker?.dataset.activeDeviceActiveIdValue
    const isCurrentDevice = !!sessionId && sessionId === activeId
    if (!isCurrentDevice) return false

    const audio = target.querySelector("audio")
    return !!audio && !audio.paused
  }
}
