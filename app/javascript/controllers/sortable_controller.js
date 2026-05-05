import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static values = {
    urlTemplate: String,
    delay: { type: Number, default: 100 }
  }

  connect() {
    this.sortable = Sortable.create(this.element, {
      animation: 150,
      delay: this.delayValue,
      delayOnTouchOnly: true,
      touchStartThreshold: 5,
      ghostClass: "sortable-ghost",
      chosenClass: "sortable-chosen",
      dragClass: "sortable-drag",
      forceFallback: true,
      onEnd: this.onEnd.bind(this)
    })
  }

  disconnect() {
    if (this.sortable) {
      this.sortable.destroy()
      this.sortable = null
    }
  }

  async onEnd(event) {
    if (event.oldIndex === event.newIndex) return

    const id = event.item.dataset.sortableId
    if (!id) return

    const url = this.urlTemplateValue.replace(":id", id)
    const body = new FormData()
    body.append("position", event.newIndex + 1)

    const token = document.querySelector('meta[name="csrf-token"]')?.content
    const headers = { "Accept": "application/json" }
    if (token) headers["X-CSRF-Token"] = token

    try {
      const response = await fetch(url, { method: "PATCH", headers, body })
      if (!response.ok) this.revert(event)
    } catch (_error) {
      this.revert(event)
    }
  }

  revert(event) {
    const list = event.from
    const items = Array.from(list.children)
    const moved = items.splice(event.newIndex, 1)[0]
    items.splice(event.oldIndex, 0, moved)
    items.forEach((item) => list.appendChild(item))
  }
}
