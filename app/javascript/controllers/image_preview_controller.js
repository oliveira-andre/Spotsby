import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "placeholder"]

  preview() {
    const file = this.inputTarget.files?.[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (event) => {
      this.previewTarget.src = event.target.result
      this.previewTarget.hidden = false
      if (this.hasPlaceholderTarget) this.placeholderTarget.hidden = true
    }
    reader.readAsDataURL(file)
  }
}
