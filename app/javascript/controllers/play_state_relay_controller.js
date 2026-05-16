import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { playing: Boolean }

  connect() {
    window.dispatchEvent(new CustomEvent("now-playing:remote-state", {
      detail: { playing: this.playingValue }
    }))
  }
}
