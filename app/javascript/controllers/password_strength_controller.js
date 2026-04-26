import { Controller } from "@hotwired/stimulus"

const LABELS = {
  0: "Too short",
  1: "Weak",
  2: "Fair",
  3: "Good",
  4: "Strong"
}

export default class extends Controller {
  static targets = ["input", "meter", "label"]

  connect() {
    this.evaluate()
  }

  evaluate() {
    const value = this.inputTarget.value || ""
    const score = this.score(value)
    this.meterTarget.dataset.strength = score
    this.labelTarget.textContent = LABELS[score]
  }

  score(value) {
    if (value.length < 8) return 0

    let points = 0
    if (/[a-z]/.test(value)) points += 1
    if (/[A-Z]/.test(value)) points += 1
    if (/\d/.test(value)) points += 1
    if (/[^A-Za-z0-9]/.test(value)) points += 1
    if (value.length >= 12) points += 1

    return Math.min(4, Math.max(1, points))
  }
}
