// SuperAdmin JavaScript entry point
// This file auto-registers all Stimulus controllers with the host app's Stimulus instance

import { Controller } from "@hotwired/stimulus"

// Define controllers inline to avoid module loading issues
class AssociationSelectController extends Controller {
  static targets = ["select", "search", "results"]
  static values = {
    model: String,
    url: String,
    selectedId: String
  }

  connect() {
    if (this.hasSelectTarget && this.selectTarget.dataset.searchable === "true") {
      this.enhanceSelect()
    }
  }

  enhanceSelect() {
    const select = this.selectTarget
    if (select.dataset.searchEnhanced === "true") {
      return
    }

    const totalCount = parseInt(select.dataset.totalCount || "0")
    const selectLimit = parseInt(select.querySelectorAll('option').length - 1) || 0

    if (totalCount <= selectLimit) {
      return
    }

    select.dataset.searchEnhanced = "true"
    this.createSearchInterface()
  }

  createSearchInterface() {
    const select = this.selectTarget
    const wrapper = document.createElement("div")
    wrapper.className = "relative"

    const searchInput = document.createElement("input")
    searchInput.type = "text"
    searchInput.placeholder = "Rechercher..."
    searchInput.className = "block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm px-3 py-2 mb-2"
    searchInput.dataset.superAdminAssociationSelectTarget = "search"

    let searchTimeout
    searchInput.addEventListener("input", (e) => {
      clearTimeout(searchTimeout)
      searchTimeout = setTimeout(() => {
        this.performSearch(e.target.value)
      }, 300)
    })

    select.parentNode.insertBefore(wrapper, select)
    wrapper.appendChild(searchInput)
    wrapper.appendChild(select)
  }

  async performSearch(query) {
    const select = this.selectTarget
    const model = select.dataset.association
    const selectedId = select.value

    if (!model) {
      console.error("Association model not defined")
      return
    }

    try {
      const url = new URL("/super_admin/associations/search", window.location.origin)
      url.searchParams.set("model", model)
      url.searchParams.set("q", query)
      url.searchParams.set("page", "1")
      if (selectedId) {
        url.searchParams.set("selected_id", selectedId)
      }

      const response = await fetch(url)
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`)
      }

      const data = await response.json()
      this.updateSelectOptions(data.results, selectedId)
    } catch (error) {
      console.error("Association search failed:", error)
    }
  }

  updateSelectOptions(results, selectedId) {
    const select = this.selectTarget
    const hasBlank = select.querySelector('option[value=""]')

    select.innerHTML = ""
    if (hasBlank) {
      const blankOption = document.createElement("option")
      blankOption.value = ""
      blankOption.textContent = ""
      select.appendChild(blankOption)
    }

    results.forEach(result => {
      const option = document.createElement("option")
      option.value = result.id
      option.textContent = result.text
      if (result.id.toString() === selectedId) {
        option.selected = true
      }
      select.appendChild(option)
    })
  }
}

class BulkSelectionController extends Controller {
  static targets = ["checkbox", "toggle", "counter"]

  connect() {
    this.updateCounter()
  }

  toggleAll(event) {
    const checked = event.target.checked
    this.checkboxTargets.forEach((checkbox) => {
      checkbox.checked = checked
    })
    if (this.hasToggleTarget) {
      this.toggleTarget.indeterminate = false
    }
    this.updateCounter()
  }

  itemChanged() {
    const allChecked = this.checkboxTargets.length > 0 && this.checkboxTargets.every((checkbox) => checkbox.checked)
    if (this.hasToggleTarget) {
      this.toggleTarget.indeterminate = !allChecked && this.checkboxTargets.some((checkbox) => checkbox.checked)
      this.toggleTarget.checked = allChecked
    }
    this.updateCounter()
  }

  updateCounter() {
    if (!this.hasCounterTarget) return

    const selected = this.checkboxTargets.filter((checkbox) => checkbox.checked).length
    this.counterTarget.textContent = selected
  }
}

class NestedFormController extends Controller {
  static targets = ["entries", "template"]

  add(event) {
    event.preventDefault()
    if (!this.hasTemplateTarget) return

    const timestamp = Date.now().toString()
    const content = this.templateTarget.innerHTML.replace(/__NEW_RECORD__/g, timestamp)
    this.entriesTarget.insertAdjacentHTML("beforeend", content)
  }

  remove(event) {
    event.preventDefault()
    const button = event.target.closest("[data-super-admin--nested-form-remove]") || event.target
    const wrapper = button.closest("[data-super-admin--nested-form-entry]")
    if (!wrapper) return

    const destroyInput = wrapper.querySelector("input[name$='[_destroy]']")
    const idInput = wrapper.querySelector("input[name$='[id]']")

    if (destroyInput) {
      destroyInput.value = "1"
    }

    if (idInput && idInput.value !== "") {
      wrapper.classList.add("hidden")
    } else {
      wrapper.remove()
    }
  }
}

class FlashController extends Controller {
  static values = {
    autoDismiss: { type: Number, default: 5000 }
  }

  connect() {
    if (this.autoDismissValue > 0) {
      this.timeout = setTimeout(() => {
        this.close()
      }, this.autoDismissValue)
    }
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  close() {
    // Use inline style for fade out animation
    this.element.style.transition = 'opacity 0.3s ease-out, transform 0.3s ease-out'
    this.element.style.opacity = '0'
    this.element.style.transform = 'translateY(-10px)'

    setTimeout(() => {
      this.element.remove()
    }, 300)
  }

  remove() {
    this.element.remove()
  }
}

class MobileMenuController extends Controller {
  static targets = ["sidebar", "overlay"]

  toggle() {
    if (this.hasSidebarTarget && this.hasOverlayTarget) {
      this.sidebarTarget.classList.toggle('-translate-x-full')
      this.overlayTarget.classList.toggle('hidden')
    }
  }

  close(event) {
    // Close on overlay click or escape key
    if (event.type === 'click' || (event.type === 'keydown' && event.key === 'Escape')) {
      if (this.hasSidebarTarget && this.hasOverlayTarget) {
        if (!this.overlayTarget.classList.contains('hidden')) {
          this.toggle()
        }
      }
    }
  }
}

// Auto-register with the host app's Stimulus application
function registerControllers() {
  if (window.Stimulus) {
    window.Stimulus.register("super-admin--association-select", AssociationSelectController)
    window.Stimulus.register("super-admin--bulk-selection", BulkSelectionController)
    window.Stimulus.register("super-admin--nested-form", NestedFormController)
    window.Stimulus.register("super-admin--flash", FlashController)
    window.Stimulus.register("super-admin--mobile-menu", MobileMenuController)
  } else {
    console.warn("SuperAdmin: Stimulus not found. Controllers will not be registered.")
  }
}

// Register immediately if Stimulus is already loaded
if (window.Stimulus) {
  registerControllers()
} else {
  // Otherwise wait for Stimulus to load
  document.addEventListener("DOMContentLoaded", () => {
    setTimeout(registerControllers, 100)
  })
}
