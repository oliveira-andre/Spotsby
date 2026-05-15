import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    target: String,
    delay: { type: Number, default: 700 }
  }

  connect() {
    const el = document.querySelector(this.targetValue)
    if (!el) return

    setTimeout(() => {
      const ctrl = this.application.getControllerForElementAndIdentifier(el, "modal")
      ctrl?.close()
    }, this.delayValue)
  }
}
