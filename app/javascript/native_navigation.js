// Hotwire Native only: page links become native screens.
//
// Turbo submits `data-turbo-stream` links as hidden GET forms. On the web the
// server answers with a page-content stream that swaps the page in place and
// keeps audio alive. In the app the server answers with the full page instead
// (ApplicationController#default_render), which Turbo turns into a visit
// proposal, and the app pushes a native screen for it.
//
// That only works for a page-level submission. When the link sits inside a
// turbo-frame, Turbo targets that frame, the frame looks for itself in the
// full page, and shows "Content missing". So on tap, inside the app, point
// such links at the whole page. Links that name a frame themselves are left
// alone (the home filter chips).
const isNativeApp = document.documentElement.classList.contains("hotwire-native")

if (isNativeApp) {
  window.addEventListener("click", (event) => {
    const link = event.target.closest?.("a[href][data-turbo-stream]")
    if (!link || link.hasAttribute("data-turbo-frame")) return
    if (!link.closest("turbo-frame")) return
    if (link.hasAttribute("data-turbo-method")) return

    link.setAttribute("data-turbo-frame", "_top")
  }, true)
}
