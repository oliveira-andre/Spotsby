import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["input", "results", "browse", "history"]
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
    const query = this.inputTarget.value.trim()

    if (query === "") {
      if (this.controller) this.controller.abort()
      this.showHistory()
      return
    }

    this.timeout = setTimeout(() => this.performSearch(query), this.debounceValue)
  }

  async performSearch(query) {
    if (this.controller) this.controller.abort()
    this.controller = new AbortController()

    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("q", query)

    try {
      const response = await fetch(url, {
        headers: { "Accept": "text/vnd.turbo-stream.html" },
        signal: this.controller.signal
      })

      if (!response.ok) return

      const stream = await response.text()
      Turbo.renderStreamMessage(stream)
      this.showResults()
    } catch (error) {
      if (error.name !== "AbortError") throw error
    }
  }

  showBrowse() {
    this.resultsTarget.hidden = true
    this.resultsTarget.innerHTML = ""
    if (this.hasHistoryTarget) this.historyTarget.hidden = true
    this.browseTarget.hidden = false
  }

  showResults() {
    this.browseTarget.hidden = true
    if (this.hasHistoryTarget) this.historyTarget.hidden = true
    this.resultsTarget.hidden = false
  }

  showHistory() {
    if (!this.hasHistoryTarget) {
      this.showBrowse()
      return
    }
    this.resultsTarget.hidden = true
    this.resultsTarget.innerHTML = ""
    this.browseTarget.hidden = true
    this.historyTarget.hidden = false
  }
}
