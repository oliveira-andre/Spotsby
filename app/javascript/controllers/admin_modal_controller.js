import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]
  static values = { autoOpen: Boolean }

  connect() {
    if (this.autoOpenValue) requestAnimationFrame(() => this.open())
  }

  open() {
    this.element.classList.add("is-open")
    document.body.style.overflow = "hidden"
  }

  close() {
    this.element.classList.remove("is-open")
    document.body.style.overflow = ""
    const frame = this.element.closest("turbo-frame")
    if (frame) frame.innerHTML = ""
  }

  disconnect() {
    document.body.style.overflow = ""
  }
}
