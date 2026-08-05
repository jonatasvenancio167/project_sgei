import { Controller } from "@hotwired/stimulus"

// Wizard de 3 passos do cadastro (/users/sign_up). Não há navegação real de
// página — todos os campos vivem no mesmo <form>; cada passo é um
// <fieldset> que fica desabilitado até ser alcançado (para não interferir
// na validação/submit dos demais) e escondido quando não é o atual.
export default class extends Controller {
  static targets = [
    "step", "stepDot", "stepDotNumber", "stepDotCheck", "stepLabel", "stepLine",
    "passwordInput", "passwordBar", "passwordLabel",
    "cardNumberInput", "cardNameInput", "cardExpInput",
    "cardNumberPreview", "cardNamePreview", "cardExpPreview",
    "billingDocInput"
  ]

  static values = { current: { type: Number, default: 1 }, max: { type: Number, default: 1 } }

  static STRENGTH_LABEL = ["", "Muito fraca", "Média", "Boa", "Forte"]
  static STRENGTH_COLOR = ["", "bg-red-500", "bg-amber-500", "bg-blue-500", "bg-emerald-500"]

  connect() {
    this.#render()
    this.#renderPasswordStrength()
  }

  next() {
    if (!this.#reportStepValidity(this.stepTargets[this.currentValue - 1])) return

    this.currentValue += 1
    if (this.currentValue > this.maxValue) this.maxValue = this.currentValue
  }

  back() {
    this.currentValue -= 1
  }

  updatePasswordStrength() {
    this.#renderPasswordStrength()
  }

  updateCardPreview() {
    if (this.hasCardNumberPreviewTarget) {
      const digits = this.cardNumberInputTarget.value
      this.cardNumberPreviewTarget.textContent = digits || "•••• •••• •••• ••••"
    }
    if (this.hasCardNamePreviewTarget) {
      this.cardNamePreviewTarget.textContent = this.cardNameInputTarget.value || "NOME DO TITULAR"
    }
    if (this.hasCardExpPreviewTarget) {
      this.cardExpPreviewTarget.textContent = this.cardExpInputTarget.value || "MM/AA"
    }
  }

  // Passos anteriores ficam escondidos mas continuam habilitados (para que
  // seus valores sejam enviados). Um campo obrigatório inválido ali não
  // mostra nenhum aviso nativo por estar fora de tela — o navegador apenas
  // cancela o submit em silêncio. Por isso validamos aqui explicitamente e,
  // se algum passo estiver inválido, voltamos até ele antes de reportar.
  validateBeforeSubmit(event) {
    const invalidIndex = this.stepTargets.findIndex((fieldset) => !this.#stepIsValid(fieldset))
    if (invalidIndex === -1) return

    event.preventDefault()
    this.currentValue = invalidIndex + 1
    if (this.currentValue > this.maxValue) this.maxValue = this.currentValue

    requestAnimationFrame(() => this.#reportStepValidity(this.stepTargets[invalidIndex]))
  }

  toggleBillingDocMask(event) {
    if (!this.hasBillingDocInputTarget) return

    const type = event.target.value
    this.billingDocInputTarget.dataset.maskTypeValue = type
    this.billingDocInputTarget.placeholder = type === "cnpj" ? "00.000.000/0000-00" : "000.000.000-00"
    this.billingDocInputTarget.value = ""
  }

  // ── Private ────────────────────────────────────────────────────────────

  currentValueChanged() {
    this.#render()
    this.element.scrollIntoView({ behavior: "smooth", block: "start" })
  }

  maxValueChanged() {
    this.#render()
  }

  #render() {
    this.stepTargets.forEach((fieldset, i) => {
      const step = i + 1
      fieldset.hidden = step !== this.currentValue
      fieldset.disabled = step > this.maxValue
    })

    this.stepDotTargets.forEach((dot, i) => {
      const step = i + 1
      const done = step < this.currentValue
      const active = step === this.currentValue

      dot.classList.toggle("border-primary", done || active)
      dot.classList.toggle("bg-primary", done)
      dot.classList.toggle("text-primary-foreground", done)
      dot.classList.toggle("bg-primary/10", active)
      dot.classList.toggle("text-primary", active)
      dot.classList.toggle("border-border/60", !done && !active)
      dot.classList.toggle("text-muted-foreground/60", !done && !active)

      this.stepDotNumberTargets[i].hidden = done
      this.stepDotCheckTargets[i].hidden = !done

      const label = this.stepLabelTargets[i]
      label.classList.toggle("text-foreground", done || active)
      label.classList.toggle("font-medium", done || active)
      label.classList.toggle("text-muted-foreground/60", !done && !active)
    })

    this.stepLineTargets.forEach((line, i) => {
      line.classList.toggle("bg-primary", i + 1 < this.currentValue)
      line.classList.toggle("bg-border", i + 1 >= this.currentValue)
    })
  }

  #renderPasswordStrength() {
    if (!this.hasPasswordInputTarget) return

    const score = this.#passwordScore(this.passwordInputTarget.value)

    this.passwordBarTargets.forEach((bar, i) => {
      const filled = score >= i + 1
      bar.classList.remove(...this.constructor.STRENGTH_COLOR.filter(Boolean))
      bar.classList.toggle("bg-border", !filled)
      if (filled) bar.classList.add(this.constructor.STRENGTH_COLOR[score])
    })

    if (this.hasPasswordLabelTarget) {
      this.passwordLabelTarget.textContent = score > 0
        ? `Força da senha: ${this.constructor.STRENGTH_LABEL[score]}`
        : ""
    }
  }

  // <fieldset>.checkValidity()/.reportValidity() are no-ops — a fieldset has
  // no constraints of its own and does NOT aggregate its descendants'
  // validity. We have to walk fieldset.elements (the real form controls)
  // ourselves to know whether a step is actually complete.
  #stepIsValid(fieldset) {
    return Array.from(fieldset.elements).every((el) => !el.willValidate || el.checkValidity())
  }

  #reportStepValidity(fieldset) {
    const invalid = Array.from(fieldset.elements).find((el) => el.willValidate && !el.checkValidity())
    if (!invalid) return true

    invalid.reportValidity()
    return false
  }

  #passwordScore(password) {
    let score = 0
    if (password.length >= 8) score++
    if (/[a-z]/.test(password) && /[A-Z]/.test(password)) score++
    if (/\d/.test(password)) score++
    if (/[^A-Za-z0-9]/.test(password)) score++
    return score
  }
}
