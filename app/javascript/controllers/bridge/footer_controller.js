import { BridgeComponent } from "@hotwired/hotwire-native-bridge";

// Tells the native app which tabs this user gets, in footer order,
// so it can show the matching tabs in its own tab bar.
export default class extends BridgeComponent {
  static component = "footer";
  static values = { tabs: Array };

  connect() {
    super.connect();
    this.send("connect", { tabs: this.tabsValue });
  }
}
