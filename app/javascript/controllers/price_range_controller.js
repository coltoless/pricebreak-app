import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["min", "max", "preset"]

  connect() {
    this.updateCustomRangeVisibility()
  }

  presetTargetConnected() {
    this.updateCustomRangeVisibility()
  }

  updateCustomRangeVisibility() {
    const preset = this.presetTarget.value
    const customRange = this.element.querySelector('.custom-range')
    
    if (preset === '') {
      customRange.style.display = 'block'
    } else {
      customRange.style.display = 'none'
      this.updateFromPreset(preset)
    }
  }

  updateFromPreset(preset) {
    if (!preset) return

    const [min, max] = preset.split('-').map(Number)
    this.minTarget.value = min
    this.maxTarget.value = max
  }

  presetChanged() {
    this.updateCustomRangeVisibility()
  }
} 