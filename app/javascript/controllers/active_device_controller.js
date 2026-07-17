import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { activeId: String }

  connect() {
    const active = this.sessionIdValue && this.activeIdValue === this.sessionIdValue
    const mySessionId = document.querySelector('meta[name="session-id"]')?.content
    const active = !!mySessionId && this.activeIdValue === mySessionId
    window.dispatchEvent(new CustomEvent("now-playing:active-changed", {
      detail: { active }
    }))
  }
}
