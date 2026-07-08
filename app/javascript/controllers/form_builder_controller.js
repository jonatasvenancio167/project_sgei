import { Controller } from "@hotwired/stimulus"

// Page-level controller for the form builder: handles the "add field" panel.
// Per-field behavior (choices editor, type switching) lives in form_field_controller.
export default class extends Controller {
  static targets = ["addPanel"]

  connect() {
    this.hideAddPanel()
  }

  toggleAddPanel() {
    if (this.addPanelTarget.classList.contains("hidden")) {
      this.showAddPanel()
    } else {
      this.hideAddPanel()
    }
  }

  showAddPanel() {
    this.addPanelTarget.classList.remove("hidden")
  }

  hideAddPanel() {
    this.addPanelTarget.classList.add("hidden")
  }

  // Dismiss the add panel when clicking outside
  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.hideAddPanel()
    }
  }
}
