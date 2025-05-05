import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["settings", "checkbox"]

  connect() {
    this.updateSettingsVisibility()
  }

  checkboxTargetConnected() {
    this.updateSettingsVisibility()
  }

  updateSettingsVisibility() {
    const isEnabled = this.checkboxTarget.checked
    this.settingsTarget.style.display = isEnabled ? 'block' : 'none'
  }

  toggleChanged() {
    this.updateSettingsVisibility()
  }
} 