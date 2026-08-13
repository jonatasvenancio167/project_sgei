import { Controller } from "@hotwired/stimulus"

// Toggles a password field between hidden and visible text (show/hide via eye icon).
export default class extends Controller {
  static targets = ["input", "eyeIcon", "eyeOffIcon"]

  toggle() {
    const isHidden = this.inputTarget.type === "password"
    this.inputTarget.type = isHidden ? "text" : "password"
    this.eyeIconTarget.classList.toggle("hidden", isHidden)
    this.eyeOffIconTarget.classList.toggle("hidden", !isHidden)
  }
}
