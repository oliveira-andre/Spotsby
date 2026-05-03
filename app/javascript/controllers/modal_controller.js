import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]
  static values = { autoOpen: Boolean }

  connect() {
    if (this.autoOpenValue) this.open()
  }

  open() {
    if (!this.element.hasAttribute("hidden")) return

    this.element.removeAttribute("hidden")
    void this.element.offsetWidth
    this.element.classList.add("is-open")
  }

  close() {
    if (this.element.hasAttribute("hidden")) return

    this.element.classList.remove("is-open")

    const onEnd = (event) => {
      if (event.propertyName !== "transform") return
      this.element.setAttribute("hidden", "")
      this.panelTarget.removeEventListener("transitionend", onEnd)
    }
    this.panelTarget.addEventListener("transitionend", onEnd)
  }

  toggle() {
    if (this.element.hasAttribute("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }
}
