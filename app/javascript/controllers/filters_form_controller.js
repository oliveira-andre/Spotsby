import { Controller } from "@hotwired/stimulus"

// Submits a filter form to a turbo-frame while preserving any URL params not
// owned by the form (e.g. sort/dir set by chips elsewhere in the frame). The
// form's visible fields are the source of truth for their own params; everything
// else is carried over from window.location.
export default class extends Controller {
  static values = { frame: String }

  connect() {
    this.boundSubmit = this.handleSubmit.bind(this)
    this.element.addEventListener("submit", this.boundSubmit)
  }

  disconnect() {
    this.element.removeEventListener("submit", this.boundSubmit)
  }

  handleSubmit(event) {
    event.preventDefault()

    const target = new URL(this.element.action, window.location.origin)

    // Carry over current URL params (sort, dir, etc).
    new URL(window.location.href).searchParams.forEach((value, key) => {
      target.searchParams.set(key, value)
    })

    // Form fields are authoritative for their own keys.
    const data = new FormData(this.element)
    const owned = new Set()
    for (const [key, value] of data.entries()) {
      if (!owned.has(key)) {
        target.searchParams.delete(key)
        owned.add(key)
      }
      if (value !== "") target.searchParams.append(key, value)
    }

    target.searchParams.delete("page")

    const url = target.toString()
    const frame = document.getElementById(this.frameValue)
    if (frame) {
      frame.src = url
      history.replaceState(history.state, "", url)
    } else {
      window.Turbo?.visit(url, { action: "advance" })
    }
  }
}
