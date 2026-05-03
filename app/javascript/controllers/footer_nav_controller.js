import { Controller } from "@hotwired/stimulus"

const ITEM_SELECTOR = ".footer-nav__item"
const ACTIVE_CLASS = "is-active"

export default class extends Controller {
  activate(event) {
    const item = event.target.closest(ITEM_SELECTOR)
    if (!item || !this.element.contains(item)) return

    this.element.querySelectorAll(ITEM_SELECTOR).forEach((el) => {
      el.classList.toggle(ACTIVE_CLASS, el === item)
    })
  }
}
