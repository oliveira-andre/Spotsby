import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { breakpoint: { type: Number, default: 768 } }

  connect() {
    if (!("open" in this.element.dataset)) {
      this.setOpen(this.isDesktop())
    }
  }

  toggle() {
    this.setOpen(this.element.dataset.open !== "true")
  }

  close() {
    this.setOpen(false)
  }

  closeOnMobile() {
    if (!this.isDesktop()) this.setOpen(false)
  }

  setOpen(open) {
    this.element.dataset.open = open ? "true" : "false"
  }

  isDesktop() {
    return window.matchMedia(`(min-width: ${this.breakpointValue}px)`).matches
  }
}
