import { Controller } from "@hotwired/stimulus"

// Máscara de telefone brasileiro: (DD) 9XXXX-XXXX  — 15 caracteres
// Funciona com celular 11 dígitos: (11) 91111-1111
export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.inputTargets.forEach(input => this.#applyMask(input))
  }

  // Chamado via data-action="input->phone-mask#mask"
  mask(event) {
    this.#applyMask(event.target)
  }

  // ── Private ────────────────────────────────────────────────────────────

  #applyMask(input) {
    // Guarda posição do cursor antes de reformatar
    const start = input.selectionStart
    const before = input.value

    const digits = before.replace(/\D/g, "").slice(0, 11)
    const masked = this.#format(digits)

    input.value = masked

    // Reposiciona cursor se o usuário não estava no fim
    if (start < before.length) {
      const delta = masked.length - before.length
      const pos = Math.max(0, start + delta)
      input.setSelectionRange(pos, pos)
    }
  }

  #format(digits) {
    if (digits.length === 0) return ""
    if (digits.length <= 2) return `(${digits}`
    if (digits.length <= 7) return `(${digits.slice(0, 2)}) ${digits.slice(2)}`
    // 8–10 dígitos: fixo  (DD) XXXX-XXXX
    // 11  dígitos: celular (DD) 9XXXX-XXXX
    const sep = digits.length <= 10 ? 6 : 7
    return `(${digits.slice(0, 2)}) ${digits.slice(2, sep)}-${digits.slice(sep)}`
  }
}
