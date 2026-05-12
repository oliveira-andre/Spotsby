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

    // Player paths are not tracked in the stack (autoplay redirects bypass
    // trackLastPage), so on a player page the current URL is not the top of
    // the stack — back is just stack[length-1]. On other pages, the current
    // URL is on top and back is stack[length-2].
    const back = isPlayerPath(currentPath())
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
    // On player pages the stack's top is the page we're navigating back to,
    // not the current page — don't pop, or we'd lose our destination.
    if (isPlayerPath(currentPath())) return

    const stack = readNavStack()
    if (stack.length === 0) return
    stack.pop()
    writeNavStack(stack)
  }
}

function currentPath() {
  return window.location.pathname + window.location.search + window.location.hash
}

function isPlayerPath(path) {
  return /^\/players(\/|$|\?)/.test(path)
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
