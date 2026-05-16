import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar"]
  static values = {
    defaultOpen: { type: Boolean, default: true }
  }

  connect() {
    this.state = this.getCookie("sidebar_state")
    
    if (this.state === null) {
      this.state = this.defaultOpenValue ? "expanded" : "collapsed"
    }

    this.updateState()
    this.addKeyboardShortcut()
  }

  toggle() {
    this.state = this.state === "expanded" ? "collapsed" : "expanded"
    this.setCookie("sidebar_state", this.state, 7)
    this.updateState()
  }

  updateState() {
    // Update provider state
    this.element.setAttribute("data-state", this.state)
    
    // Update sidebar target state
    if (this.hasSidebarTarget) {
      this.sidebarTarget.setAttribute("data-state", this.state)
    }

    // Dispatch event for other components if needed
    this.dispatch("state-change", { detail: { state: this.state } })
  }

  addKeyboardShortcut() {
    document.addEventListener("keydown", (event) => {
      if ((event.metaKey || event.ctrlKey) && event.key === "b") {
        event.preventDefault()
        this.toggle()
      }
    })
  }

  getCookie(name) {
    const value = `; ${document.cookie}`
    const parts = value.split(`; ${name}=`)
    if (parts.length === 2) return parts.pop().split(";").shift()
    return null
  }

  setCookie(name, value, days) {
    let expires = ""
    if (days) {
      const date = new Date()
      date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000))
      expires = `; expires=${date.toUTCString()}`
    }
    document.cookie = `${name}=${value || ""}${expires}; path=/`
  }
}
