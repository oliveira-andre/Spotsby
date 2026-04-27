import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "backdrop"]

  open() {
    this.element.dataset.sidebarOpen = "true"
    document.body.style.overflow = "hidden"
  }

  close() {
    this.element.dataset.sidebarOpen = "false"
    document.body.style.overflow = ""
  }

  toggle() {
    if (this.element.dataset.sidebarOpen === "true") {
      this.close()
    } else {
      this.open()
    }
  }
}
