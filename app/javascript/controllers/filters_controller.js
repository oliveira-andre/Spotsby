import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  select(event) {
    const target = event.currentTarget
    const chips = this.element.querySelectorAll(".filters__chip")

    chips.forEach((chip) => {
      const isActive = chip === target
      chip.classList.toggle("is-active", isActive)
      chip.setAttribute("aria-selected", isActive ? "true" : "false")
    })
  }
}
