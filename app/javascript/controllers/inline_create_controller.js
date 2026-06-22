import { Controller } from "@hotwired/stimulus"

// Create a record inline without leaving the surrounding form/modal. Generic
// by design — point it at any create endpoint via the `url`/`param` values.
//
//   data-controller="inline-create"
//   data-inline-create-url-value="/admin/authors/quick_create"
//   data-inline-create-param-value="author[name]"
//
// The endpoint must respond with a turbo_stream that, on success, appends the
// new record (e.g. a selected <option> to a companion multi-select that
// watches its own <select>); on failure (status 422) it updates the error
// target with validation messages.
export default class extends Controller {
  static targets = ["pickerView", "createView", "input", "submit", "error"]
  static values = {
    url: String,
    param: { type: String, default: "name" }
  }

  show(event) {
    event?.preventDefault()
    if (!this.hasCreateViewTarget || !this.hasPickerViewTarget) return
    this.clearError()
    this.pickerViewTarget.hidden = true
    this.createViewTarget.hidden = false
    if (this.hasInputTarget) {
      this.inputTarget.value = ""
      this.inputTarget.focus()
    }
  }

  hide(event) {
    event?.preventDefault()
    if (!this.hasCreateViewTarget || !this.hasPickerViewTarget) return
    this.createViewTarget.hidden = true
    this.pickerViewTarget.hidden = false
  }

  async submit(event) {
    event?.preventDefault()
    if (!this.urlValue || !this.hasInputTarget) return

    const value = this.inputTarget.value.trim()
    if (!value) { this.inputTarget.focus(); return }
    if (this.hasSubmitTarget) this.submitTarget.disabled = true

    try {
      const token = document.querySelector('meta[name="csrf-token"]')?.content
      const body = new FormData()
      body.append(this.paramValue, value)

      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: { "X-CSRF-Token": token || "", "Accept": "text/vnd.turbo-stream.html" },
        credentials: "same-origin",
        body
      })

      const html = await response.text()
      if (html && window.Turbo?.renderStreamMessage) window.Turbo.renderStreamMessage(html)

      if (response.ok) {
        // Success: the stream appended the new record; the companion
        // multi-select re-renders itself via its own MutationObserver.
        this.hide()
      } else if (this.hasInputTarget) {
        this.inputTarget.focus()
      }
    } catch (_) {
      /* network error — leave the form as-is so the user can retry */
    } finally {
      if (this.hasSubmitTarget) this.submitTarget.disabled = false
    }
  }

  clearError() {
    if (this.hasErrorTarget) this.errorTarget.innerHTML = ""
  }
}
