import { Controller } from "@hotwired/stimulus"

const NAV_STACK_KEY = "spotsby:nav-stack"

export default class extends Controller {
  initialize() {
    this.onClick = this.handleClick.bind(this)
  }

  connect() {
    this.element.addEventListener("click", this.onClick)
    this.applyHref()
  }

  disconnect() {
    this.element.removeEventListener("click", this.onClick)
  }

  applyHref() {
    const stack = readNavStack()
    if (stack.length < 2) return

    const back = stack[stack.length - 2]
    if (!back) return

    let url
    try {
      url = new URL(back, window.location.origin)
    } catch (_) {
      return
    }
    if (url.origin !== window.location.origin) return

    this.element.href = url.pathname + url.search + url.hash
  }

  handleClick() {
    const stack = readNavStack()
    if (stack.length === 0) return
    stack.pop()
    writeNavStack(stack)
  }
}

function readNavStack() {
  let raw
  try { raw = sessionStorage.getItem(NAV_STACK_KEY) } catch (_) { return [] }
  if (!raw) return []
  try {
    const parsed = JSON.parse(raw)
    return Array.isArray(parsed) ? parsed : []
  } catch (_) { return [] }
}

function writeNavStack(stack) {
  try { sessionStorage.setItem(NAV_STACK_KEY, JSON.stringify(stack)) } catch (_) {}
}
