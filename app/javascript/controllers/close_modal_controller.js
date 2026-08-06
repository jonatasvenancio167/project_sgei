import { Controller } from "@hotwired/stimulus"

// Mounted on a throwaway element inserted via a Turbo Stream response.
// Turbo Streams insert nodes through real DOM APIs, so the connect()
// lifecycle callback fires reliably — unlike a raw <script> tag in the
// stream response, which browsers treat as inert markup and never run.
export default class extends Controller {
  static values = { modalId: String }

  connect() {
    document.getElementById(this.modalIdValue)?.dispatchEvent(new CustomEvent("modal:close"))
    this.element.remove()
  }
}
