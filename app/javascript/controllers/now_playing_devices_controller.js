import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list"]

  initialize() {
    this.onActiveChanged = this.handleActiveChanged.bind(this)
  }

  connect() {
    this.lastSeenActiveId = this.currentActiveId()
    window.addEventListener("now-playing:active-changed", this.onActiveChanged)
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

  handleActiveChanged() {
    const next = this.currentActiveId()
    if (next === this.lastSeenActiveId) return
    this.lastSeenActiveId = next
    this.refresh()
  }

  refresh() {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    fetch("/now_playing/devices", {
      headers: {
        "X-CSRF-Token": token || "",
        "Accept": "text/vnd.turbo-stream.html"
      },
      credentials: "same-origin"
    }).then(async (response) => {
      if (response.ok && response.headers.get("content-type")?.includes("turbo-stream")) {
        const html = await response.text()
        if (window.Turbo?.renderStreamMessage) window.Turbo.renderStreamMessage(html)
      }
    }).catch(() => {})
  }

  currentActiveId() {
    return document.getElementById("now-playing-active-device")
      ?.dataset.activeDeviceActiveIdValue || null
  }
}
