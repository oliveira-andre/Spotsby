import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "toggleBtn"]

  connect() {
    this.onActiveChanged = this.handleActiveChanged.bind(this)
    window.addEventListener("now-playing:active-changed", this.onActiveChanged)
    this.syncFromActiveDevice()
  }

  disconnect() {
    window.removeEventListener("now-playing:active-changed", this.onActiveChanged)
  }

  toggle(event) {
    if (!this.hasListTarget) return
    const expanded = !this.listTarget.hidden
    this.listTarget.hidden = expanded
    event.currentTarget.setAttribute("aria-expanded", String(!expanded))
  }

  handleActiveChanged(event) {
    this.applyActive(!!event.detail?.active)
  }

  syncFromActiveDevice() {
    const tracker = document.getElementById("now-playing-active-device")
    if (!tracker) return
    const sessionId = tracker.dataset.activeDeviceSessionIdValue
    const activeId = tracker.dataset.activeDeviceActiveIdValue
    this.applyActive(!!sessionId && sessionId === activeId)
  }

  applyActive(active) {
    if (!this.hasToggleBtnTarget) return
    this.toggleBtnTarget.classList.toggle("is-active", active)
  }
}
