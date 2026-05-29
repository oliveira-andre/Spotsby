import { Controller } from "@hotwired/stimulus"

// Pairs with @stimulus-components/clipboard on the same element. The clipboard
// controller handles the actual copy + tooltip text swap; this one toggles the
// `is-copied` class so the tooltip can flash green for the same duration.
export default class extends Controller {
  static targets = ["source"]
  static values = { duration: { type: Number, default: 2000 } }

  // Resolve a server-rendered path to an absolute URL on the client. Needed
  // because the player partial is also re-rendered via Turbo broadcasts (out
  // of request context), where url helpers fall back to a placeholder host.
  connect() {
    if (!this.hasSourceTarget) return
    const value = this.sourceTarget.value
    if (value.startsWith("/")) {
      this.sourceTarget.value = `${window.location.origin}${value}`
    }
  }

  flash() {
    this.element.classList.add("is-copied")
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.element.classList.remove("is-copied")
    }, this.durationValue)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
