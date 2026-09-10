import { Controller } from "@hotwired/stimulus"

// Overlay modal for the admin add/edit forms.
//
// In the app the same markup is a full page inside a native modal (see
// `body.admin-sheet`), so there is nothing to open, and closing means asking
// the app to dismiss the modal and refresh the list underneath.
export default class extends Controller {
  static targets = ["panel"]
  static values = { autoOpen: Boolean }

  connect() {
    if (this.native) return
    if (this.autoOpenValue) requestAnimationFrame(() => this.open())
  }

  get native() {
    return document.documentElement.classList.contains("hotwire-native")
  }

  open() {
    if (this.native) return
    this.element.classList.add("is-open")
    document.body.style.overflow = "hidden"
  }

  close() {
    if (this.native) {
      window.Turbo.visit("/refresh_historical_location")
      return
    }
    this.element.classList.remove("is-open")
    document.body.style.overflow = ""
    const frame = this.element.closest("turbo-frame")
    if (frame) frame.innerHTML = ""
  }

  disconnect() {
    document.body.style.overflow = ""
  }
}
