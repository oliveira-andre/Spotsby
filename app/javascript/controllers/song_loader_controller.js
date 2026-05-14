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
          autoplay: true
        }
      }))
    }

    if (this.slugValue && /^\/players(\/|$)/.test(window.location.pathname)) {
      window.history.replaceState({}, "", `/players/${this.slugValue}`)
    }

    this.element.remove()
  }
}
