import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["start", "end", "preset"]

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

    const today = new Date()
    let startDate = new Date(today)
    let endDate = new Date(today)

    switch (preset) {
      case 'today':
        // Start and end date are already today
        break
      case 'tomorrow':
        startDate.setDate(today.getDate() + 1)
        endDate.setDate(today.getDate() + 1)
        break
      case 'weekend':
        // Set to this weekend (Saturday and Sunday)
        const dayOfWeek = today.getDay()
        const daysUntilWeekend = dayOfWeek === 0 ? 6 : 6 - dayOfWeek
        startDate.setDate(today.getDate() + daysUntilWeekend)
        endDate.setDate(startDate.getDate() + 1)
        break
      case '7days':
        endDate.setDate(today.getDate() + 7)
        break
      case '30days':
        endDate.setDate(today.getDate() + 30)
        break
    }

    this.startTarget.value = this.formatDate(startDate)
    this.endTarget.value = this.formatDate(endDate)
  }

  formatDate(date) {
    return date.toISOString().split('T')[0]
  }

  presetChanged() {
    this.updateCustomRangeVisibility()
  }
} 