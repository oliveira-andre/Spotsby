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
    if (stack.length === 0) return

    // Player views are not tracked in the stack (autoplay redirects bypass
    // trackLastPage, and turbo-stream responses don't update the URL), so on
    // a player view the top of the stack is the page to return to — back is
    // stack[length-1]. On other pages the current URL is on top and back is
    // stack[length-2].
    const back = onPlayerView()
      ? stack[stack.length - 1]
      : stack[stack.length - 2]
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
    // On a player view the stack's top is the page we're navigating back to,
    // not the current page — don't pop, or we'd lose our destination.
    if (onPlayerView()) return

    const stack = readNavStack()
    if (stack.length === 0) return
    stack.pop()
    writeNavStack(stack)
  }
}

function onPlayerView() {
  return !!document.getElementById("player")
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
