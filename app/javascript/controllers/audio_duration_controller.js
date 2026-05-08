import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["file", "duration"]

  read() {
    const file = this.fileTarget.files?.[0]
    if (!file) return

    const audio = document.createElement("audio")
    const url = URL.createObjectURL(file)

    audio.preload = "metadata"
    audio.src = url

    audio.onloadedmetadata = () => {
      URL.revokeObjectURL(url)
      this.durationTarget.value = Math.round(audio.duration * 1000)
    }

    audio.onerror = () => {
      URL.revokeObjectURL(url)
    }
  }
}
