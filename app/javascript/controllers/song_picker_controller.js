import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["input"]
  static values = { url: String, debounce: { type: Number, default: 250 } }

  connect() {
    this.timeout = null
    this.controller = null
  }

  disconnect() {
    clearTimeout(this.timeout)
    if (this.controller) this.controller.abort()
  }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.performSearch(), this.debounceValue)
  }

  async performSearch() {
    if (this.controller) this.controller.abort()
    this.controller = new AbortController()

    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("q", this.inputTarget.value.trim())

    try {
      const response = await fetch(url, {
        headers: { "Accept": "text/vnd.turbo-stream.html" },
        signal: this.controller.signal
      })
      if (!response.ok) return
      const stream = await response.text()
      Turbo.renderStreamMessage(stream)
    } catch (error) {
      if (error.name !== "AbortError") throw error
    }
  }
}
