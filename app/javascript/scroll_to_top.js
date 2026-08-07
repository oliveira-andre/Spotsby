// Scroll instantly to the top of the page whenever navigation swaps the main
// content. Navigation happens two ways here:
//
//   1. Turbo Stream links (data-turbo-stream) — ApplicationController#default_render
//      wraps the page in turbo_stream.update("page-content", ...). This is how
//      almost every content link (songs, albums, authors, search results)
//      navigates, including redirects (album#play -> player). We watch incoming
//      streams for that exact action/target pair.
//   2. Turbo Frame navigations — e.g. the home filter tabs. We hang the scroll
//      off the specific frame the clicked link targets, so it only fires once
//      that frame actually reloads.
//
// Deliberately left alone:
//   * Broadcast streams (now-playing etc.) — they never target page-content.
//   * Live search typing — it updates #search_results, not page-content.
//   * Lazy pagination — those frames load without a click, so no turbo:click.
//   * Inline-edit / modal frames — swapping content in place shouldn't jump the
//     page (see INLINE_FRAMES and the modal container check below).
//   * Drive visits — Turbo resets scroll on its own.

const INLINE_FRAMES = new Set(["song_actions_body", "playlist_name"])
const MODAL_SELECTOR = "#bottom-modal, #song-actions-modal"

function targetFrame(link) {
  const explicit = link.dataset.turboFrame
  if (explicit === "_top") return null
  if (explicit) return document.getElementById(explicit)
  return link.closest("turbo-frame")
}

document.addEventListener("turbo:before-stream-render", (event) => {
  const stream = event.target
  if (stream.getAttribute("action") === "update" && stream.getAttribute("target") === "page-content") {
    window.scrollTo({ top: 0, behavior: "instant" })
  }
})

document.addEventListener("turbo:click", (event) => {
  const link = event.target.closest("a")
  if (!link) return

  const frame = targetFrame(link)
  if (!frame || INLINE_FRAMES.has(frame.id) || frame.closest(MODAL_SELECTOR)) return

  frame.addEventListener(
    "turbo:frame-load",
    () => window.scrollTo({ top: 0, behavior: "instant" }),
    { once: true }
  )
})
