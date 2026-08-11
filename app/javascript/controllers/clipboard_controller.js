import { Controller } from "@hotwired/stimulus"

// Copies a link to the clipboard (used by the Convite de Membro list).
export default class extends Controller {
  static targets = ["source", "label"]

  copy() {
    navigator.clipboard.writeText(this.sourceTarget.value || this.sourceTarget.textContent)

    if (!this.hasLabelTarget) return

    const original = this.labelTarget.textContent
    this.labelTarget.textContent = "Copiado!"
    setTimeout(() => { this.labelTarget.textContent = original }, 1500)
  }
}
