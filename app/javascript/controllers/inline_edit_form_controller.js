import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cancel"]

  cancel(event) {
    event.preventDefault()
    if (this.hasCancelTarget) this.cancelTarget.click()
  }
}
