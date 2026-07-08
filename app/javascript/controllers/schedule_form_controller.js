import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "row", "colorInput", "colorButton"]

  connect() {
    this.syncColorSelection()
  }

  addColumn() {
    const index = this.rowTargets.length
    const row = document.createElement("div")
    row.className = "flex items-center gap-2"
    row.dataset.scheduleFormTarget = "row"
    row.innerHTML = `
      <button type="button"
              class="grid h-9 w-9 shrink-0 place-items-center rounded-md border border-border/60 text-muted-foreground hover:bg-muted/50 cursor-pointer"
              aria-label="Mover"
              data-action="click->schedule-form#moveUp"
              data-index="${index}">
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-grip-vertical h-4 w-4"><circle cx="9" cy="12" r="1"/><circle cx="9" cy="5" r="1"/><circle cx="9" cy="19" r="1"/><circle cx="15" cy="12" r="1"/><circle cx="15" cy="5" r="1"/><circle cx="15" cy="19" r="1"/></svg>
      </button>
      <input type="text"
             name="columns[][name]"
             placeholder="Coluna ${index + 1}"
             class="flex h-9 min-w-0 flex-1 rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring" />
      <select name="columns[][type]"
              class="flex h-9 w-32 shrink-0 cursor-pointer rounded-md border border-input bg-transparent px-2 py-1 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring">
        <option value="text">Texto</option>
        <option value="member">Membro</option>
        <option value="date">Data</option>
        <option value="time">Hora</option>
        <option value="number">Número</option>
        <option value="boolean">Sim/Não</option>
      </select>
      <button type="button"
              class="inline-flex shrink-0 items-center justify-center rounded-lg p-2 text-muted-foreground hover:bg-destructive/10 hover:text-destructive transition-colors cursor-pointer"
              aria-label="Remover"
              data-action="click->schedule-form#removeColumn">
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-trash-2 h-4 w-4"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/><line x1="10" x2="10" y1="11" y2="17"/><line x1="14" x2="14" y1="11" y2="17"/></svg>
      </button>
    `
    this.listTarget.appendChild(row)
    this.reindexRows()
  }

  removeColumn(event) {
    const row = event.currentTarget.closest("[data-schedule-form-target='row']")
    if (this.rowTargets.length <= 1) return
    row.remove()
    this.reindexRows()
  }

  moveUp(event) {
    const row = event.currentTarget.closest("[data-schedule-form-target='row']")
    const prev = row.previousElementSibling
    if (prev) {
      this.listTarget.insertBefore(row, prev)
      this.reindexRows()
    }
  }

  selectColor(event) {
    const value = event.currentTarget.dataset.color
    this.colorInputTarget.value = value
    this.syncColorSelection()
  }

  syncColorSelection() {
    const selected = this.colorInputTarget.value
    this.colorButtonTargets.forEach((btn) => {
      const active = btn.dataset.color === selected
      btn.classList.toggle("border-foreground", active)
      btn.classList.toggle("border-transparent", !active)
    })
  }

  reindexRows() {
    this.rowTargets.forEach((row, index) => {
      const input = row.querySelector("input[type='text']")
      if (input) input.placeholder = `Coluna ${index + 1}`
      const moveBtn = row.querySelector("[data-action*='moveUp']")
      if (moveBtn) moveBtn.dataset.index = index
    })
  }
}
