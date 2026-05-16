import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  connect() {
    // Listen for custom events to open this modal
    this.element.addEventListener("modal:open", () => this.open())
    this.element.addEventListener("modal:close", () => this.close())
  }

  open() {
    this.containerTarget.classList.remove("hidden")
    // Use a small timeout to trigger the transition
    setTimeout(() => {
      this.containerTarget.classList.remove("opacity-0")
      this.containerTarget.classList.add("opacity-100")
    }, 10)
    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.containerTarget.classList.remove("opacity-100")
    this.containerTarget.classList.add("opacity-0")
    
    // Wait for transition before hiding
    setTimeout(() => {
      this.containerTarget.classList.add("hidden")
      document.body.classList.remove("overflow-hidden")
    }, 300)
  }
}
