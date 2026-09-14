import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

// Moves the big player's header into the native navigation bar so the device
// selector and the song details button sit on the same line as the native
// back button. Mounted on `.player__header`; only loads inside the app.
//
// The device selector partial is replaced by a turbo stream whenever the
// active device changes, so the header is watched for DOM changes and the
// native side gets a fresh snapshot each time.
export default class extends BridgeComponent {
  static component = "player-header"
  static targets = ["details"]

  connect() {
    super.connect()
    // The native bar items replace this row.
    this.element.style.display = "none"

    this.observer = new MutationObserver(() => this.scheduleSync())
    this.observer.observe(this.element, { childList: true, subtree: true })
    this.sync()
  }

  disconnect() {
    this.observer?.disconnect()
    clearTimeout(this.syncTimer)
    this.send("disconnect")
    super.disconnect()
  }

  scheduleSync() {
    clearTimeout(this.syncTimer)
    this.syncTimer = setTimeout(() => this.sync(), 50)
  }

  sync() {
    this.send("connect", {
      devices: this.devices(),
      hasDetails: this.hasDetailsTarget
    }, (message) => this.handleReply(message.data))
  }

  // Mirrors what the web partial shows: the toggle is the device on the
  // button, the others are the ones you can switch playback to.
  devices() {
    const toggle = this.element.querySelector(".now-playing-devices__toggle")
    if (!toggle) return null

    const items = Array.from(this.element.querySelectorAll(".now-playing-devices__button")).map((button) => ({
      sessionId: button.dataset.bridgeSessionId,
      label: button.querySelector(".now-playing-devices__label")?.textContent.trim() || "",
      active: button.dataset.bridgeActive === "true"
    }))

    return {
      label: toggle.querySelector(".now-playing-devices__label")?.textContent.trim() || "",
      active: toggle.dataset.bridgeActive === "true",
      items
    }
  }

  handleReply(data) {
    if (!data) return

    if (data.action === "details") {
      this.detailsTarget?.click()
    } else if (data.action === "device" && data.sessionId) {
      const button = this.element.querySelector(
        `.now-playing-devices__button[data-bridge-session-id="${CSS.escape(data.sessionId)}"]`
      )
      button?.click()
    }
  }
}
