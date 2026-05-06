import ColorPicker from "@stimulus-components/color-picker"

export default class extends ColorPicker {
  static targets = ["button", "input", "preview", "preset"]

  connect() {
    super.connect()
    this.syncPreview(this.inputTarget.value)
    this.syncPresets(this.inputTarget.value)
  }

  selectPreset(event) {
    event.preventDefault()
    const color = event.currentTarget.dataset.color
    if (!color) return

    this.inputTarget.value = color
    this.picker?.setColor(color, true)
    this.syncPreview(color)
    this.syncPresets(color)
  }

  openPicker(event) {
    event.preventDefault()
    this.picker?.show()
  }

  onSave(event) {
    super.onSave(event)
    this.syncPreview(this.inputTarget.value)
    this.syncPresets(this.inputTarget.value)
  }

  syncPreview(color) {
    if (this.hasPreviewTarget) {
      this.previewTarget.style.backgroundColor = color || "transparent"
    }
  }

  syncPresets(color) {
    if (!this.hasPresetTarget) return
    const normalized = (color || "").toLowerCase()
    this.presetTargets.forEach((chip) => {
      const matches = chip.dataset.color?.toLowerCase() === normalized
      chip.classList.toggle("is-active", matches)
    })
  }

  get swatches() {
    return []
  }
}
