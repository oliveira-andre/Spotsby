import { Controller } from "@hotwired/stimulus"

// Cascades the album select based on the selected author. Each album <option>
// carries a data-author-id; when the author changes, options that don't match
// are hidden, and a stale selection is cleared.
export default class extends Controller {
  static targets = ["author", "album"]

  connect() {
    this.applyVisibility(false)
  }

  authorChanged() {
    this.applyVisibility(true)
  }

  applyVisibility(clearMismatch) {
    const authorId = this.authorTarget.value
    let cleared = false

    for (const option of this.albumTarget.options) {
      if (!option.value) continue
      const matches = !authorId || option.dataset.authorId === authorId
      option.hidden = !matches
      option.disabled = !matches
      if (!matches && option.selected && clearMismatch) {
        option.selected = false
        cleared = true
      }
    }

    if (cleared) {
      this.albumTarget.value = ""
      this.albumTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }
  }
}
