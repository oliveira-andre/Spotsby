import { Controller } from "@hotwired/stimulus"

// Pairs with @stimulus-components/clipboard on the same element. The clipboard
// controller handles the actual copy + tooltip text swap; this one toggles the
// `is-copied` class so the tooltip can flash green for the same duration.
export default class extends Controller {
  static values = { duration: { type: Number, default: 2000 } }

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
