import { Controller } from "@hotwired/stimulus"

// Preview local de um arquivo de imagem selecionado (drag & drop ou clique),
// antes do upload. Alterna entre um placeholder e uma caixa de preview.
// Uso:
//   <div data-controller="file-preview">
//     <input type="file" data-file-preview-target="input" data-action="change->file-preview#show">
//     <div data-file-preview-target="placeholder" data-action="click->file-preview#trigger dragover->file-preview#dragOver drop->file-preview#drop">...</div>
//     <div data-file-preview-target="previewBox" hidden>
//       <img data-file-preview-target="image">
//       <span data-file-preview-target="fileName"></span>
//     </div>
//   </div>
export default class extends Controller {
  static targets = ["input", "image", "placeholder", "previewBox", "fileName"]

  show() {
    const file = this.inputTarget.files?.[0]
    if (!file) return

    if (this.hasImageTarget) this.imageTarget.src = URL.createObjectURL(file)
    if (this.hasFileNameTarget) this.fileNameTarget.textContent = file.name

    if (this.hasPlaceholderTarget) this.placeholderTarget.hidden = true
    if (this.hasPreviewBoxTarget) this.previewBoxTarget.hidden = false
  }

  trigger() {
    this.inputTarget.click()
  }

  dragOver(event) {
    event.preventDefault()
  }

  drop(event) {
    event.preventDefault()
    const file = event.dataTransfer.files?.[0]
    if (!file) return

    this.inputTarget.files = event.dataTransfer.files
    this.show()
  }
}
