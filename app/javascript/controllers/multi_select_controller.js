import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "chips", "search", "dropdown", "options", "empty"]
  static values = {
    placeholder: { type: String, default: "Add item…" },
    emptyText: { type: String, default: "No matches" }
  }

  connect() {
    this.isOpen = false
    this.outsideClick = this.handleOutsideClick.bind(this)
    document.addEventListener("click", this.outsideClick)
    this.observeSelect()
    this.render()
  }

  disconnect() {
    document.removeEventListener("click", this.outsideClick)
    if (this.selectObserver) this.selectObserver.disconnect()
  }

  // Re-sync the UI when <option>s are added/removed externally (e.g. a
  // companion inline-create controller appends a freshly created record).
  observeSelect() {
    if (!this.hasSelectTarget || typeof MutationObserver === "undefined") return
    this.selectObserver = new MutationObserver(() => this.render())
    this.selectObserver.observe(this.selectTarget, { childList: true })
  }

  get options() {
    return Array.from(this.selectTarget.options).map(o => ({
      value: o.value,
      text: o.text,
      selected: o.selected
    }))
  }

  get selectedOptions() {
    return this.options.filter(o => o.selected)
  }

  get availableOptions() {
    const query = this.hasSearchTarget ? this.searchTarget.value.trim().toLowerCase() : ""
    return this.options.filter(o => {
      if (o.selected) return false
      if (!query) return true
      return o.text.toLowerCase().includes(query)
    })
  }

  setSelected(value, selected) {
    const opt = Array.from(this.selectTarget.options).find(o => o.value === value)
    if (!opt) return
    opt.selected = selected
    this.selectTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  toggleOption(event) {
    event.preventDefault()
    event.stopPropagation()
    const value = event.currentTarget.dataset.value
    this.setSelected(value, true)
    if (this.hasSearchTarget) this.searchTarget.value = ""
    this.render()
    if (this.hasSearchTarget) this.searchTarget.focus()
  }

  removeChip(event) {
    event.preventDefault()
    event.stopPropagation()
    const value = event.currentTarget.dataset.value
    this.setSelected(value, false)
    this.render()
  }

  search() {
    this.renderDropdown()
    this.open()
  }

  open() {
    if (this.isOpen) return
    this.isOpen = true
    this.dropdownTarget.hidden = false
  }

  close() {
    this.isOpen = false
    this.dropdownTarget.hidden = true
  }

  focusSearch() {
    this.open()
    this.renderDropdown()
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  render() {
    this.renderChips()
    this.renderDropdown()
  }

  renderChips() {
    const selected = this.selectedOptions
    this.chipsTarget.innerHTML = selected.map(o => `
      <span class="chip">
        <span class="chip__label">${this.escape(o.text)}</span>
        <button type="button"
                class="chip__remove"
                aria-label="Remove ${this.escape(o.text)}"
                data-action="click->multi-select#removeChip"
                data-value="${this.escape(o.value)}">&times;</button>
      </span>
    `).join("")
  }

  renderDropdown() {
    const available = this.availableOptions
    if (available.length === 0) {
      this.optionsTarget.innerHTML = `<div class="multi-select__empty">${this.escape(this.emptyTextValue)}</div>`
      return
    }
    this.optionsTarget.innerHTML = available.map(o => `
      <button type="button"
              class="multi-select__option"
              data-action="click->multi-select#toggleOption"
              data-value="${this.escape(o.value)}">${this.escape(o.text)}</button>
    `).join("")
  }

  escape(text) {
    const div = document.createElement("div")
    div.textContent = text == null ? "" : String(text)
    return div.innerHTML
  }
}
