import { Controller } from "@hotwired/stimulus"

const CHOICE_TYPES = ["select", "radio", "checkbox"]

// Scoped to a single field card in the form builder. Handles showing the
// options editor for choice types and adding/removing option rows.
export default class extends Controller {
  static targets = ["typeSelect", "choicesSection", "optionsList", "optionTemplate"]

  connect() {
    this.refresh()
  }

  typeChanged() {
    if (this.isChoice && this.rows.length === 0) this.addOption()
    this.refresh()
  }

  addOption(event) {
    event?.preventDefault()
    const row = this.optionTemplateTarget.content.cloneNode(true)
    this.optionsListTarget.appendChild(row)
    this.refresh()
    const inputs = this.optionsListTarget.querySelectorAll("input[type=text]")
    inputs[inputs.length - 1]?.focus()
  }

  removeOption(event) {
    const row = event.currentTarget.closest("[data-option-row]")
    if (this.rows.length <= 1) {
      const input = row.querySelector("input[type=text]")
      if (input) input.value = ""
      return
    }
    row.remove()
    this.refresh()
  }

  // Enter inside an option input adds the next option instead of submitting
  optionKeydown(event) {
    event.preventDefault()
    this.addOption()
  }

  refresh() {
    this.choicesSectionTarget.classList.toggle("hidden", !this.isChoice)
    const markerType = this.type === "select" ? "select" : (this.type === "checkbox" ? "checkbox" : "radio")

    this.rows.forEach((row, i) => {
      row.querySelectorAll("[data-marker-type]").forEach(el => {
        el.classList.toggle("hidden", el.dataset.markerType !== markerType)
      })
      const index = row.querySelector('[data-marker-type="select"]')
      if (index) index.textContent = `${i + 1}.`
      const input = row.querySelector("input[type=text]")
      if (input) input.placeholder = `Opção ${i + 1}`
    })
  }

  get type() {
    return this.typeSelectTarget.value
  }

  get isChoice() {
    return CHOICE_TYPES.includes(this.type)
  }

  get rows() {
    return Array.from(this.optionsListTarget.querySelectorAll("[data-option-row]"))
  }
}
