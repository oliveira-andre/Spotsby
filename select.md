# Custom Select Component — Implementation Guide

A single-value, searchable, Stimulus-backed `<select>` replacement. Wraps a hidden native `<select>` so it serializes naturally with Rails form helpers, validates server-side, and stays the source of truth.

This document is portable — drop these files into any Rails + Stimulus app and the component works.

## What you get

- Styled trigger button with placeholder / selected-label text and a chevron.
- Dropdown panel with an in-dropdown search filter (case-insensitive, substring match).
- Optional `×` clear button inside the trigger (auto-shown only when the underlying `<select>` allows a blank value).
- Selected option highlighted in the dropdown with a check icon.
- Fires native `change` events on the underlying `<select>` — works with any `data-action="change->..."` Stimulus action or jQuery `.on('change')` listener.
- Listens for external `change` events too, so programmatic updates (`select.value = 'x'; select.dispatchEvent(new Event('change'))`) re-sync the UI.
- Outside-click closes the dropdown.

## Files to add

| File | Purpose |
|---|---|
| `app/javascript/controllers/select_controller.js` | Stimulus controller (identifier: `select`) |
| `app/assets/stylesheets/spree/backend/components/_select.scss` | Styles (BEM under `.select`) |
| `app/views/spree/admin/shared/_select.html.erb` | Wrapping partial that takes a `yield`ed `<select>` |
| `app/assets/stylesheets/spree/backend/spree_admin.scss` | Add `@import 'components/select';` |

Path conventions are project-specific; adjust the `app/assets/stylesheets/...` paths and `@import` location to match your project's structure.

## Markup contract

The component requires this DOM shape inside `data-controller="select"`:

```html
<div data-controller="select" data-select-placeholder-value="Pick one">
  <div class="select">
    <!-- 1. Hidden native <select> — the source of truth -->
    <select class="select__native" data-select-target="select"
            name="model[field]" id="model_field">
      <option value="">--</option>       <!-- blank option enables × clear -->
      <option value="1">One</option>
      <option value="2" selected>Two</option>
    </select>

    <!-- 2. Visible trigger (div, NOT button — it contains a nested button) -->
    <div class="select__trigger" role="button" tabindex="0"
         data-select-target="trigger"
         data-action="click->select#toggle
                      keydown.enter->select#toggle
                      keydown.space->select#toggle">
      <span class="select__trigger-text" data-select-target="triggerText">Pick one</span>
      <button type="button" class="select__clear" hidden
              data-select-target="clearButton"
              data-action="click->select#clear"
              aria-label="Clear">&times;</button>
      <svg class="select__chevron" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
        <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
      </svg>
    </div>

    <!-- 3. Dropdown panel -->
    <div class="select__dropdown" data-select-target="dropdown">
      <div class="select__search">
        <input type="text" placeholder="Search…"
               data-select-target="searchInput"
               data-action="input->select#search">
      </div>
      <div class="select__options" data-select-target="optionsList"></div>
    </div>
  </div>
</div>
```

Why a `<div role="button">` for the trigger instead of `<button>`? The clear `×` is itself a `<button>` and nested buttons are invalid HTML. The `role="button"` + `tabindex="0"` + `keydown.enter|space` actions make it keyboard-accessible.

## Stimulus controller

```js
// app/javascript/controllers/select_controller.js
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
      document.removeEventListener('click', this.outsideClickHandler)
    }
    if (this.nativeChangeHandler && this.hasSelectTarget) {
      this.selectTarget.removeEventListener('change', this.nativeChangeHandler)
    }
  }

  // Allow clearing only when the underlying <select> has a blank option —
  // i.e. the form accepts an empty value. Required selects don't get an ×.
  computeAllowClear() {
    return Array.from(this.selectTarget.options).some(o => o.value === '')
  }

  setupNativeChangeListener() {
    this.nativeChangeHandler = () => {
      if (this.suppressNativeChange) return
      this.selectedValue = this.getInitialSelectedValue()
      this.updateTriggerText()
      this.updateClearButton()
      this.renderDropdownItems()
    }
    this.selectTarget.addEventListener('change', this.nativeChangeHandler)
  }

  buildOptionsFromSelect() {
    return Array.from(this.selectTarget.options)
      .filter(o => o.value)
      .map(o => ({ value: o.value, text: o.text, selected: o.selected }))
  }

  getInitialSelectedValue() {
    return this.selectTarget.value === '' ? null : this.selectTarget.value
  }

  setupOutsideClickListener() {
    this.outsideClickHandler = (event) => {
      if (!this.element.contains(event.target)) this.close()
    }
    document.addEventListener('click', this.outsideClickHandler)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    this.isOpen ? this.close() : this.open()
  }

  open() {
    this.isOpen = true
    this.dropdownTarget.classList.add('show')
    this.triggerTarget.classList.add('open')
    if (this.hasSearchInputTarget) this.searchInputTarget.focus()
  }

  close() {
    this.isOpen = false
    this.dropdownTarget.classList.remove('show')
    this.triggerTarget.classList.remove('open')
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.value = ''
      this.filterOptions('')
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
    const items = this.optionsListTarget.querySelectorAll('.select__option')
    items.forEach(item => {
      item.style.display = item.dataset.text.toLowerCase().includes(query) ? '' : 'none'
    })
  }

  syncToNativeSelect() {
    this.selectTarget.value = this.selectedValue ?? ''
  }

  dispatchChangeEvent() {
    // Suppress our own listener so we don't re-sync from the value we
    // just wrote. Only external mutations should trigger the re-sync path.
    this.suppressNativeChange = true
    try {
      this.selectTarget.dispatchEvent(new Event('change', { bubbles: true }))
    } finally {
      this.suppressNativeChange = false
    }
  }

  updateTriggerText() {
    if (this.selectedValue === null) {
      this.triggerTextTarget.textContent = this.placeholderValue
      this.triggerTextTarget.classList.add('placeholder')
    } else {
      const option = this.options.find(o => o.value === this.selectedValue)
      this.triggerTextTarget.textContent = option ? option.text : this.placeholderValue
      this.triggerTextTarget.classList.remove('placeholder')
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
    this.optionsListTarget.innerHTML = this.options.map(option => {
      const isSelected = option.value === this.selectedValue
      const check = isSelected
        ? `<svg class="select__check" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
             <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
           </svg>`
        : ''
      return `
        <div class="select__option${isSelected ? ' is-selected' : ''}"
             data-action="click->select#selectOption"
             data-value="${this.escapeHtml(option.value)}"
             data-text="${this.escapeHtml(option.text)}">
          <span class="select__label">${this.escapeHtml(option.text)}</span>
          ${check}
        </div>
      `
    }).join('')
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
```

### Targets

| Target | Element | Required |
|---|---|---|
| `select` | hidden native `<select>` | yes |
| `trigger` | clickable visible trigger | yes |
| `triggerText` | `<span>` inside trigger | yes |
| `dropdown` | dropdown panel | yes |
| `optionsList` | container the controller fills with `.select__option`s | yes |
| `searchInput` | search `<input>` | optional (search is skipped if absent) |
| `clearButton` | `<button>` inside trigger | optional |

### Values

| Value | Type | Default | Notes |
|---|---|---|---|
| `placeholder` | String | `"Select option"` | Shown when nothing is selected |

### Actions

| Action | Wired on | Behavior |
|---|---|---|
| `toggle` | trigger (`click`, `keydown.enter`, `keydown.space`) | open/close dropdown |
| `selectOption` | each rendered option (auto-wired) | pick value, sync, dispatch `change`, close |
| `clear` | clear `<button>` | reset value, sync, dispatch `change` |
| `search` | search input (`input`) | live-filter options |

### Auto-detection: when is the `×` shown?

The controller inspects the native `<select>` on `connect()`: if it has any `<option value="">` (i.e. a blank option), `allowClear` is `true` and the `×` appears once something is selected. Otherwise the `×` stays hidden forever — useful for required fields where clearing would just break submission.

This means **the choice is driven by your Rails form helper**, not by an extra Stimulus flag:

- `f.collection_select(:vendor_id, @vendors, :id, :name, {}, ...)` → **no blank**, **no ×**
- `f.collection_select(:partner_id, @partners, :id, :name, { include_blank: true }, ...)` → **× available**

## Styles

```scss
// app/assets/stylesheets/<your-path>/components/_select.scss
.select {
  position: relative;
  width: 100%;

  &__native {
    position: absolute; opacity: 0; width: 0; height: 0; pointer-events: none;
  }

  &__trigger {
    display: flex; align-items: center; justify-content: space-between;
    gap: 0.5rem;
    width: 100%; min-height: 42px; padding: 0.5rem 0.75rem;
    background: #fff; border: 1px solid #d1d5db; border-radius: 0.5rem;
    cursor: pointer; user-select: none;
    transition: all 0.15s ease;

    &:hover { border-color: #9ca3af; }

    &:focus, &.open {
      border-color: #005BD3;
      box-shadow: 0 0 0 3px rgba(0, 91, 211, 0.1);
      outline: none;
    }
  }

  &__trigger-text {
    flex: 1; min-width: 0;
    font-size: 0.875rem; color: #1f2937; font-weight: 500;
    overflow: hidden; text-overflow: ellipsis; white-space: nowrap;

    &.placeholder { color: #9ca3af; font-weight: 400; }
  }

  &__clear {
    display: flex; align-items: center; justify-content: center;
    width: 1.25rem; height: 1.25rem; padding: 0;
    background: none; border: none; border-radius: 9999px;
    cursor: pointer; color: #9ca3af; opacity: 0.7;
    font-size: 1rem; line-height: 1;
    transition: opacity 0.15s ease, background-color 0.15s ease;
    flex-shrink: 0;

    &:hover { opacity: 1; background-color: #f3f4f6; color: #1f2937; }
    &[hidden] { display: none; }
  }

  &__chevron {
    width: 1rem; height: 1rem; color: #6b7280;
    transition: transform 0.2s ease; flex-shrink: 0;
  }
  &__trigger.open &__chevron { transform: rotate(180deg); }

  &__dropdown {
    position: absolute; top: calc(100% + 4px); left: 0; right: 0;
    z-index: 1000;
    background: #fff; border: 1px solid #e5e7eb; border-radius: 0.5rem;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    display: none; max-height: 280px; overflow: hidden;

    &.show { display: block; }
  }

  &__search {
    padding: 0.5rem; border-bottom: 1px solid #e5e7eb;

    input {
      width: 100%; padding: 0.5rem 0.75rem;
      border: 1px solid #d1d5db; border-radius: 0.375rem;
      font-size: 0.875rem; outline: none;

      &:focus { border-color: #005BD3; box-shadow: 0 0 0 2px rgba(0, 91, 211, 0.1); }
      &::placeholder { color: #9ca3af; }
    }
  }

  &__options { max-height: 220px; overflow-y: auto; padding: 0.25rem 0; }

  &__option {
    display: flex; align-items: center; gap: 0.625rem;
    padding: 0.5rem 0.75rem; cursor: pointer;
    transition: background-color 0.1s ease;

    &:hover { background-color: #f3f4f6; }

    &.is-selected {
      background-color: #e0efff;
      .select__label { color: #005BD3; font-weight: 500; }
    }
  }

  &__label {
    flex: 1; min-width: 0;
    font-size: 0.875rem; color: #374151; line-height: 1.4;
  }

  &__check { width: 1rem; height: 1rem; color: #005BD3; flex-shrink: 0; }
}
```

Adjust the palette (`#005BD3`, `#e0efff`, `#d1d5db`, `#374151`, `#9ca3af`, `#f3f4f6`, `#e5e7eb`) to your design system. The structure stays the same.

Don't forget to `@import 'components/select';` from your admin/frontend SCSS manifest.

## Rails partial (wrapping the form helper)

```erb
<%# app/views/<your-path>/shared/_select.html.erb
    locals: placeholder %>
<div data-controller="select" data-select-placeholder-value="<%= placeholder %>">
  <div class="select">
    <%= yield %>
    <div class="select__trigger" role="button" tabindex="0"
         data-select-target="trigger"
         data-action="click->select#toggle keydown.enter->select#toggle keydown.space->select#toggle">
      <span class="select__trigger-text placeholder"
            data-select-target="triggerText"><%= placeholder %></span>
      <button type="button" class="select__clear" hidden
              data-select-target="clearButton"
              data-action="click->select#clear"
              aria-label="Clear">&times;</button>
      <svg class="select__chevron" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
        <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
      </svg>
    </div>
    <div class="select__dropdown" data-select-target="dropdown">
      <div class="select__search">
        <input type="text" placeholder="Search…"
               data-select-target="searchInput"
               data-action="input->select#search">
      </div>
      <div class="select__options" data-select-target="optionsList"></div>
    </div>
  </div>
</div>
```

## Usage with Rails form helpers

### Required field (no clear)

```erb
<%= render 'shared/select', placeholder: 'Account' do %>
  <%= f.collection_select(:vendor_id, @vendors, :id, :name, {},
        { class: 'select__native', data: { select_target: 'select' } }) %>
<% end %>
```

### Optional field (× clear shows up)

```erb
<%= render 'shared/select', placeholder: 'Listing' do %>
  <%= f.collection_select(:partner_id, @partners, :id, :name, { include_blank: true },
        { class: 'select__native', data: { select_target: 'select' } }) %>
<% end %>
```

### With a change-handler that triggers another controller

```erb
<%= render 'shared/select', placeholder: 'Account' do %>
  <%= f.collection_select(:vendor_id, @vendors, :id, :name, {},
        { class: 'select__native',
          data: { select_target: 'select',
                  action: 'change->parent-controller#onVendorChange' } }) %>
<% end %>
```

The `data-action` attribute lives on the **native `<select>`** (the source of truth). When the user picks an option, our controller fires `change` on it and the Stimulus action runs.

## Integration gotchas

### 1. Stimulus identifier vs. filename

`stimulus-webpack-helpers` (and `@hotwired/stimulus-loading`) convert `_` in the filename to `-` in the identifier:

- `select_controller.js` → identifier **`select`**
- `pipe_object_controller.js` → identifier **`pipe-object`** (not `pipe_object`)

So `data-action="change->pipe_object#foo"` (underscore) silently does nothing. Always check the identifier with `Array.from(window.Stimulus.router.modulesByIdentifier.keys())` in the console if an action isn't firing.

### 2. Turbo Stream responses must use the new component

If you have endpoints that return Turbo Streams to update the form (e.g. dependent dropdowns), the response template must render the new component too, otherwise it'll overwrite the styled component with whatever it renders. Reuse the same `shared/select` partial in the Turbo Stream view:

```erb
<%= turbo_stream.update(@target) do %>
  <%= render 'shared/select', placeholder: 'Listing' do %>
    <%= collection_select(:model, :partner_id, @partner_listings, :id, :name,
          { include_blank: true },
          { class: 'select__native', data: { select_target: 'select' } }) %>
  <% end %>
<% end %>
```

### 3. External `change` events

The controller listens to `change` events on its native `<select>` so external code can update the UI:

```js
const select = document.querySelector('#model_field')
select.value = '5'
select.dispatchEvent(new Event('change', { bubbles: true }))
// Trigger text and selected highlight will both update.
```

It uses a `suppressNativeChange` guard internally to avoid re-syncing from its own dispatched events, so this is safe even though we also dispatch `change` from `selectOption`/`clear`.

### 4. Nested-button HTML

The trigger is a `<div role="button">`, not a `<button>`, because it contains the clear `<button>`. Keyboard support is added via `keydown.enter->select#toggle` and `keydown.space->select#toggle`.

### 5. Modals + outside-click

`setupOutsideClickListener` listens on `document`. If the component sits inside a modal that traps focus or stops propagation, make sure those handlers don't swallow document-level clicks before this one runs. In practice this hasn't been an issue with Bootstrap modals.

## Quick checklist for porting

- [ ] Copy `select_controller.js` into the Stimulus controllers folder.
- [ ] Copy `_select.scss`, adjust palette, `@import` from your manifest.
- [ ] Copy `_select.html.erb` into a shared views folder.
- [ ] Pick one existing `f.collection_select(..., class: 'select2')` and convert it as the smoke test — view it in the browser.
- [ ] If you have Turbo Stream endpoints that re-render form fields, update those templates too.
- [ ] Verify any `data-action="change->..."` on the converted field still fires — and that the controller identifier in the action uses hyphens.
