// Smoothly scroll to the top of the page whenever a link click drives a Turbo
// Frame navigation. We hang the scroll off the specific frame the link targets,
// so it only fires once that frame actually reloads — never on unrelated frames.
//
// Deliberately left alone:
//   * Lazy pagination — those frames load without a click, so no turbo:click.
//   * Inline-edit / modal frames — swapping content in place shouldn't jump the
//     page (see INLINE_FRAMES and the modal container check below).
//   * Drive / turbo_stream visits — Turbo resets scroll on its own.

const INLINE_FRAMES = new Set(["song_actions_body", "playlist_name"])
const MODAL_SELECTOR = "#bottom-modal, #song-actions-modal"

function targetFrame(link) {
  const explicit = link.dataset.turboFrame
  if (explicit === "_top") return null
  if (explicit) return document.getElementById(explicit)
  return link.closest("turbo-frame")
}

document.addEventListener("turbo:click", (event) => {
  const link = event.target.closest("a")
  if (!link) return

  const frame = targetFrame(link)
  if (!frame || INLINE_FRAMES.has(frame.id) || frame.closest(MODAL_SELECTOR)) return

  frame.addEventListener(
    "turbo:frame-load",
    () => window.scrollTo({ top: 0, behavior: "smooth" }),
    { once: true }
  )
})
