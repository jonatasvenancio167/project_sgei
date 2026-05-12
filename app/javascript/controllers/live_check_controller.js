import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="live-check"
export default class extends Controller {
  connect() {
    console.log("Hotwire: Stimulus is connected!")
    this.element.textContent = "Hotwire is working! 🚀"
    this.element.classList.add("text-green-600", "font-bold", "mt-4", "block")
  }
}
