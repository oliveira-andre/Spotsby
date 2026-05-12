import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "select", "trigger", "triggerText", "dropdown",
    "searchInput", "optionsList", "clearButton"
  ]

  static values = {
    placeholder: { type: String, default: "Select option" }
  }

  connect() {
    this.isOpen = false
    this.options = this.buildOptionsFromSelect()
    this.selectedValue = this.getInitialSelectedValue()
    this.allowClear = this.computeAllowClear()
    this.suppressNativeChange = false

    this.render()
    this.setupOutsideClickListener()
    this.setupNativeChangeListener()
  }

  disconnect() {
    if (this.outsideClickHandler) {
      document.removeEventListener("click", this.outsideClickHandler)
    }
    if (this.nativeChangeHandler && this.hasSelectTarget) {
      this.selectTarget.removeEventListener("change", this.nativeChangeHandler)
    }
  }

  computeAllowClear() {
    return Array.from(this.selectTarget.options).some(o => o.value === "")
  }

  setupNativeChangeListener() {
    this.nativeChangeHandler = () => {
      if (this.suppressNativeChange) return
      this.options = this.buildOptionsFromSelect()
      this.selectedValue = this.getInitialSelectedValue()
      this.allowClear = this.computeAllowClear()
      this.updateTriggerText()
      this.updateClearButton()
      this.renderDropdownItems()
    }
    this.selectTarget.addEventListener("change", this.nativeChangeHandler)
  }

  buildOptionsFromSelect() {
    return Array.from(this.selectTarget.options)
      .filter(o => o.value && !o.hidden && !o.disabled)
      .map(o => ({ value: o.value, text: o.text, selected: o.selected }))
  }

  getInitialSelectedValue() {
    return this.selectTarget.value === "" ? null : this.selectTarget.value
  }

  setupOutsideClickListener() {
    this.outsideClickHandler = (event) => {
      if (!this.element.contains(event.target)) this.close()
    }
    document.addEventListener("click", this.outsideClickHandler)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    this.isOpen ? this.close() : this.open()
  }

  open() {
    this.options = this.buildOptionsFromSelect()
    this.renderDropdownItems()
    this.isOpen = true
    this.dropdownTarget.classList.add("show")
    this.triggerTarget.classList.add("open")
    if (this.hasSearchInputTarget) this.searchInputTarget.focus()
  }

  close() {
    this.isOpen = false
    this.dropdownTarget.classList.remove("show")
    this.triggerTarget.classList.remove("open")
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.value = ""
      this.filterOptions("")
    }
  }

  selectOption(event) {
    event.stopPropagation()
    this.selectedValue = event.currentTarget.dataset.value
    this.syncToNativeSelect()
    this.updateTriggerText()
    this.updateClearButton()
    this.renderDropdownItems()
    this.dispatchChangeEvent()
    this.close()
  }

  clear(event) {
    event.preventDefault()
    event.stopPropagation()
    this.selectedValue = null
    this.syncToNativeSelect()
    this.updateTriggerText()
    this.updateClearButton()
    this.renderDropdownItems()
    this.dispatchChangeEvent()
  }

  search(event) {
    this.filterOptions(event.target.value.toLowerCase())
  }

  filterOptions(query) {
    const items = this.optionsListTarget.querySelectorAll(".select__option")
    items.forEach(item => {
      item.style.display = item.dataset.text.toLowerCase().includes(query) ? "" : "none"
    })
  }

  syncToNativeSelect() {
    this.selectTarget.value = this.selectedValue ?? ""
  }

  dispatchChangeEvent() {
    this.suppressNativeChange = true
    try {
      this.selectTarget.dispatchEvent(new Event("change", { bubbles: true }))
    } finally {
      this.suppressNativeChange = false
    }
  }

  updateTriggerText() {
    if (this.selectedValue === null) {
      this.triggerTextTarget.textContent = this.placeholderValue
      this.triggerTextTarget.classList.add("placeholder")
    } else {
      const option = this.options.find(o => o.value === this.selectedValue)
      const fromNative = Array.from(this.selectTarget.options).find(o => o.value === this.selectedValue)
      const label = option?.text || fromNative?.text || this.placeholderValue
      this.triggerTextTarget.textContent = label
      this.triggerTextTarget.classList.remove("placeholder")
    }
  }

  updateClearButton() {
    if (!this.hasClearButtonTarget) return
    this.clearButtonTarget.hidden = !this.allowClear || this.selectedValue === null
  }

  render() {
    this.renderDropdownItems()
    this.updateTriggerText()
    this.updateClearButton()
  }

  renderDropdownItems() {
    if (!this.hasOptionsListTarget) return
    if (this.options.length === 0) {
      this.optionsListTarget.innerHTML = `<div class="select__empty">No options</div>`
      return
    }
    this.optionsListTarget.innerHTML = this.options.map(option => {
      const isSelected = option.value === this.selectedValue
      const check = isSelected
        ? `<svg class="select__check" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
             <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
           </svg>`
        : ""
      return `
        <div class="select__option${isSelected ? " is-selected" : ""}"
             data-action="click->select#selectOption"
             data-value="${this.escapeHtml(option.value)}"
             data-text="${this.escapeHtml(option.text)}">
          <span class="select__label">${this.escapeHtml(option.text)}</span>
          ${check}
        </div>
      `
    }).join("")
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
