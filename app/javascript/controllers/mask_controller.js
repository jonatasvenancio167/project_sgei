import { Controller } from "@hotwired/stimulus"

// Máscaras genéricas de formato brasileiro/cartão para um único input.
// Uso: <input data-controller="mask" data-mask-type-value="cep">
export default class extends Controller {
  static values = { type: String }

  connect() {
    this.#applyMask(this.element)
  }

  // Chamado via data-action="input->mask#mask"
  mask(event) {
    this.#applyMask(event.target)
  }

  // ── Private ────────────────────────────────────────────────────────────

  #applyMask(input) {
    const start = input.selectionStart
    const before = input.value

    const digits = before.replace(/\D/g, "").slice(0, this.#maxDigits())
    const masked = this.#format(digits)

    input.value = masked

    if (start < before.length) {
      const delta = masked.length - before.length
      const pos = Math.max(0, start + delta)
      input.setSelectionRange(pos, pos)
    }
  }

  #maxDigits() {
    switch (this.typeValue) {
      case "cep":    return 8
      case "cnpj":   return 14
      case "cpf":    return 11
      case "card":   return 16
      case "expiry": return 4
      default:       return 999
    }
  }

  #format(d) {
    switch (this.typeValue) {
      case "cep":
        if (d.length <= 5) return d
        return `${d.slice(0, 5)}-${d.slice(5)}`
      case "cnpj":
        return this.#formatCnpj(d)
      case "cpf":
        return this.#formatCpf(d)
      case "card":
        return d.replace(/(\d{4})(?=\d)/g, "$1 ")
      case "expiry":
        if (d.length <= 2) return d
        return `${d.slice(0, 2)}/${d.slice(2)}`
      default:
        return d
    }
  }

  #formatCnpj(d) {
    if (d.length <= 2) return d
    if (d.length <= 5) return `${d.slice(0, 2)}.${d.slice(2)}`
    if (d.length <= 8) return `${d.slice(0, 2)}.${d.slice(2, 5)}.${d.slice(5)}`
    if (d.length <= 12) return `${d.slice(0, 2)}.${d.slice(2, 5)}.${d.slice(5, 8)}/${d.slice(8)}`
    return `${d.slice(0, 2)}.${d.slice(2, 5)}.${d.slice(5, 8)}/${d.slice(8, 12)}-${d.slice(12)}`
  }

  #formatCpf(d) {
    if (d.length <= 3) return d
    if (d.length <= 6) return `${d.slice(0, 3)}.${d.slice(3)}`
    if (d.length <= 9) return `${d.slice(0, 3)}.${d.slice(3, 6)}.${d.slice(6)}`
    return `${d.slice(0, 3)}.${d.slice(3, 6)}.${d.slice(6, 9)}-${d.slice(9)}`
  }
}
