import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

// Web side of the native `player` component. Only loads inside the app (the
// user agent lists the supported components). Lives on #minimal-player next to
// the now-playing controller, which talks to it through NativeBackend.
//
// One `subscribe` message per page; the app keeps replying to it with its
// current state for as long as the page lives. Every reply becomes a
// `native-player:state` event on this element.
export default class extends BridgeComponent {
  static component = "player"

  connect() {
    super.connect()
    this.subscribe()
  }

  subscribe() {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || ""
    this.send("subscribe", { csrfToken }, (message) => {
      this.element.dispatchEvent(new CustomEvent("native-player:state", { detail: message.data }))
    })
  }

  load(song) { this.send("load", song) }
  play() { this.send("play") }
  pause() { this.send("pause") }
  seek(position) { this.send("seek", { position }) }
  next() { this.send("next") }
  previous() { this.send("previous") }
  setRepeat(enabled) { this.send("repeat", { enabled }) }
  clear() { this.send("clear") }
}
