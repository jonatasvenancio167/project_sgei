import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "previewName",
    "previewIconBadge",
    "previewIcon",
    "searchInput",
    "memberRow",
    "leaderIdInput",
    "tabButton",
    "tabContent"
  ]

  connect() {
    this.iconPaths = {
      "music": '<path d="M9 18V5l12-2v13"></path><circle cx="6" cy="18" r="3"></circle><circle cx="18" cy="16" r="3"></circle>',
      "users": '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M22 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path>',
      "heart": '<path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"></path>',
      "hand-heart": '<path d="M11 14h2a2 2 0 1 0 0-4h-3c-.6 0-1.1.2-1.4.6L7 12.8M17 14h2a2 2 0 1 0 0-4h-2a2 2 0 1 0 0 4Z"></path><path d="M9.5 20H5a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2h4.5L12 4l2.5 3H19a2 2 0 0 1 2 2v1.5"></path><path d="M14 22a8.5 8.5 0 0 0 4.7-2.3L22 17"></path>',
      "baby": '<path d="M9 12h.01"></path><path d="M15 12h.01"></path><path d="M10 16c.5.3 1.2.5 2 .5s1.5-.2 2-.5"></path><path d="M19 6.3a9 9 0 0 1 1.8 3.9 2 2 0 0 1 0 3.6 9 9 0 0 1-17.6 0 2 2 0 0 1 0-3.6A9 9 0 0 1 5 6.3"></path><path d="M12 2v4"></path>',
      "book-open": '<path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"></path><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"></path>',
      "church": '<path d="M10 20v-5h4v5"></path><path d="M7 20h10a2 2 0 0 0 2-2V8l-7-5-7 5v10a2 2 0 0 0 2 2Z"></path><path d="M12 7v4"></path><path d="M10 9h4"></path>',
      "sparkles": '<path d="m12 3-1.912 5.813a2 2 0 0 1-1.275 1.275L3 12l5.813 1.912a2 2 0 0 1 1.275 1.275L12 21l1.912-5.813a2 2 0 0 1 1.275-1.275L21 12l-5.813-1.912a2 2 0 0 1-1.275-1.275L12 3Z"></path><path d="m5 3 1 2.5L8.5 6 6 7 5 9.5 4 7 1.5 6 4 5 5 3Z"></path><path d="m19 17 1 2.5 2.5.5-2.5 1-1 2.5-1-2.5-2.5-1 2.5-1 1-2.5Z"></path>'
    }

    if (this.hasTabButtonTarget) {
      // Emulate click on first tab
      this.switchTab({ currentTarget: this.tabButtonTargets[0] })
    }
  }

  // --- Live Preview ---
  updateName(event) {
    const val = event.target.value.trim()
    this.previewNameTarget.textContent = val || "Nome do departamento"
  }

  updateColor(event) {
    const val = event.target.value
    const badge = this.previewIconBadgeTarget
    badge.className = `grid h-12 w-12 place-items-center rounded-xl transition-colors duration-200 ${val}`
  }

  updateIcon(event) {
    const val = event.target.value
    const paths = this.iconPaths[val] || this.iconPaths["users"]
    const svg = this.previewIconTarget
    svg.className = `lucide lucide-${val} h-5 w-5`
    svg.innerHTML = paths
  }

  // --- Local Filtering ---
  filterMembers(event) {
    const query = event.target.value.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    this.memberRowTargets.forEach(row => {
      const name = row.dataset.memberName.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "")
      const email = row.dataset.memberEmail.toLowerCase()
      if (name.includes(query) || email.includes(query)) {
        row.classList.remove("hidden")
      } else {
        row.classList.add("hidden")
      }
    })
  }

  // --- Leader Selector ---
  toggleMemberCheckbox(event) {
    const row = event.target.closest("[data-target='departament-dialogs.memberRow']")
    const btn = row.querySelector(".leader-btn")
    if (event.target.checked) {
      if (btn) btn.classList.remove("hidden")
    } else {
      if (btn) {
        btn.classList.add("hidden")
        btn.className = "leader-btn h-7 gap-1 px-2 text-xs rounded-lg transition-colors border border-border/40 text-muted-foreground hover:bg-muted font-medium inline-flex items-center hidden"
        btn.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-crown h-3 w-3 mr-1"><path d="m2 4 3 12h14l3-12-6 7-4-7-4 7-6-7z"></path></svg> Definir líder`
        
        const userId = row.dataset.memberId
        if (this.leaderIdInputTarget.value === userId) {
          this.leaderIdInputTarget.value = ""
        }
      }
    }
  }

  setLeader(event) {
    const clickedBtn = event.currentTarget
    const row = clickedBtn.closest("[data-target='departament-dialogs.memberRow']")
    const userId = row.dataset.memberId

    const isCurrentLeader = this.leaderIdInputTarget.value === userId

    this.memberRowTargets.forEach(r => {
      const b = r.querySelector(".leader-btn")
      if (b) {
        b.className = "leader-btn h-7 gap-1 px-2 text-xs rounded-lg transition-colors border border-border/40 text-muted-foreground hover:bg-muted font-medium inline-flex items-center hidden"
        const chk = r.querySelector("input[type='checkbox']")
        if (chk && chk.checked) {
          b.classList.remove("hidden")
        }
        b.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-crown h-3 w-3 mr-1"><path d="m2 4 3 12h14l3-12-6 7-4-7-4 7-6-7z"></path></svg> Definir líder`
      }
    })

    if (isCurrentLeader) {
      this.leaderIdInputTarget.value = ""
    } else {
      this.leaderIdInputTarget.value = userId
      clickedBtn.className = "leader-btn h-7 gap-1 px-2 text-xs rounded-lg transition-colors bg-primary text-primary-foreground font-medium inline-flex items-center"
      clickedBtn.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-crown h-3 w-3 mr-1"><path d="m2 4 3 12h14l3-12-6 7-4-7-4 7-6-7z"></path></svg> Líder`
    }
  }

  // --- Tab Switcher ---
  switchTab(event) {
    const btn = event.currentTarget
    const tabName = btn.dataset.tab

    this.tabButtonTargets.forEach(b => {
      if (b === btn) {
        b.className = "flex-1 rounded-md px-3 py-1.5 transition-colors bg-background font-medium shadow-sm text-foreground"
      } else {
        b.className = "flex-1 rounded-md px-3 py-1.5 transition-colors text-muted-foreground hover:text-foreground bg-transparent"
      }
    })

    this.tabContentTargets.forEach(content => {
      if (content.dataset.tabContent === tabName) {
        content.classList.remove("hidden")
      } else {
        content.classList.add("hidden")
      }
    })
  }
}
