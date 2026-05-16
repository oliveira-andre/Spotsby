import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list"]

  toggle(event) {
    if (!this.hasListTarget) return
    const expanded = !this.listTarget.hidden
    this.listTarget.hidden = expanded
    event.currentTarget.setAttribute("aria-expanded", String(!expanded))
  }
}
