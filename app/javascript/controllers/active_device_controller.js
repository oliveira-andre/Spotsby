import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { sessionId: String, activeId: String }

  connect() {
    const active = this.sessionIdValue && this.activeIdValue === this.sessionIdValue
    window.dispatchEvent(new CustomEvent("now-playing:active-changed", {
      detail: { active }
    }))
  }
}
