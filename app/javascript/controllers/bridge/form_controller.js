import { BridgeComponent, BridgeElement } from "@hotwired/hotwire-native-bridge"

// Moves a form's action buttons into the native navigation bar when the page
// is shown as a native modal (admin add/edit forms). Mounted on the
// `.admin-modal__actions` container: the `primary` target (Save, Continue,
// Done) becomes the right bar button, the `secondary` target (Cancel, Skip)
// the left one. Only loads inside the app.
export default class extends BridgeComponent {
  static component = "form"
  static targets = ["primary", "secondary"]

  connect() {
    super.connect()
    this.form = this.element.closest("form")
    this.onSubmitStart = () => this.send("submitDisabled")
    this.onSubmitEnd = () => this.send("submitEnabled")
    this.form?.addEventListener("turbo:submit-start", this.onSubmitStart)
    this.form?.addEventListener("turbo:submit-end", this.onSubmitEnd)

    // The native bar buttons replace these.
    this.element.style.display = "none"

    const primary = this.hasPrimaryTarget ? new BridgeElement(this.primaryTarget) : null
    const secondary = this.hasSecondaryTarget ? new BridgeElement(this.secondaryTarget) : null
    this.send("connect", {
      primaryTitle: primary?.title || null,
      primaryEnabled: !!primary && !this.primaryTarget.disabled,
      secondaryTitle: secondary?.title || null
    }, (message) => {
      if (message.data?.button === "secondary") this.secondaryTarget?.click()
      else this.primaryTarget?.click()
    })
  }

  disconnect() {
    this.form?.removeEventListener("turbo:submit-start", this.onSubmitStart)
    this.form?.removeEventListener("turbo:submit-end", this.onSubmitEnd)
    this.send("disconnect")
    super.disconnect()
  }
}
