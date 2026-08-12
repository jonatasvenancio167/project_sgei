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

    this.mobileState = "closed"

    this.updateState()
    this.updateMobileState()
    this.addKeyboardShortcut()
  }

  toggle() {
    if (this.isMobile()) {
      this.mobileState = this.mobileState === "open" ? "closed" : "open"
      this.updateMobileState()
      return
    }

    this.state = this.state === "expanded" ? "collapsed" : "expanded"
    this.setCookie("sidebar_state", this.state, 7)
    this.updateState()
  }

  closeMobile() {
    this.mobileState = "closed"
    this.updateMobileState()
  }

  isMobile() {
    return window.matchMedia("(max-width: 767px)").matches
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

  updateMobileState() {
    this.element.setAttribute("data-mobile-state", this.mobileState)

    if (this.hasSidebarTarget) {
      this.sidebarTarget.setAttribute("data-mobile-state", this.mobileState)
    }

    this.dispatch("mobile-state-change", { detail: { mobileState: this.mobileState } })
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
