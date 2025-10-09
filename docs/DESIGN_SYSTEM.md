# PriceBreak Design System

This document outlines the comprehensive design system for PriceBreak, ensuring consistent visual identity and user experience across all features.

## 🎨 Color Palette

### Primary Colors (Purple Gradient Theme)
- **Primary Purple**: `#8B5CF6` - Main brand color
- **Primary Purple Dark**: `#7C3AED` - Hover states
- **Primary Purple Darker**: `#6D28D9` - Active states
- **Primary Purple Darkest**: `#5B21B6` - Deep accents

### Secondary Colors
- **Secondary Gray**: `#1F2937` - Dark backgrounds
- **Accent Blue**: `#3B82F6` - Information elements
- **Accent Green**: `#10B981` - Success states
- **Accent Yellow**: `#F59E0B` - Warning states
- **Accent Red**: `#EF4444` - Error states

### Neutral Colors
- **White**: `#FFFFFF` - Primary text on dark backgrounds
- **Gray Scale**: From `#F9FAFB` (lightest) to `#111827` (darkest)

## 🌈 Background Gradients

### Primary Gradient
```css
background: linear-gradient(180deg, 
  #8B5CF6 0%, 
  #7C3AED 25%, 
  #6D28D9 50%, 
  #5B21B6 75%, 
  #1F2937 100%);
```

### Overlay Gradient
```css
background-image: 
  radial-gradient(circle at 20% 80%, rgba(139, 92, 246, 0.3) 0%, transparent 50%),
  radial-gradient(circle at 80% 20%, rgba(124, 58, 237, 0.3) 0%, transparent 50%),
  radial-gradient(circle at 40% 40%, rgba(109, 40, 217, 0.2) 0%, transparent 50%);
```

## 🧩 Component Library

### Layout Components

#### `.pricebreak-page`
Main page container with gradient background and overlay effects.

#### `.pricebreak-container`
Content container with max-width and responsive padding.

#### `.pricebreak-header`
Header section with logo and navigation.

### Card Components

#### `.pricebreak-card`
Glass morphism card with purple theme:
- Background: `rgba(255, 255, 255, 0.1)`
- Border: `rgba(255, 255, 255, 0.2)`
- Backdrop filter: `blur(10px)`
- Hover effects with purple shadow

#### `.pricebreak-card-white`
Clean white card for forms and content:
- Background: `#FFFFFF`
- Border: `#E5E7EB`
- Shadow: `0 4px 6px -1px rgba(0, 0, 0, 0.1)`

### Button Components

#### `.pricebreak-btn`
Base button class with consistent styling.

#### `.pricebreak-btn-primary`
Primary purple button with hover effects.

#### `.pricebreak-btn-secondary`
Glass morphism button with white text.

#### `.pricebreak-btn-white`
White button for dark backgrounds.

#### Size Variants
- `.pricebreak-btn-sm` - Small buttons
- `.pricebreak-btn-lg` - Large buttons

### Form Components

#### `.pricebreak-input`
Glass morphism input field:
- Background: `rgba(255, 255, 255, 0.1)`
- Border: `rgba(255, 255, 255, 0.2)`
- Purple focus state

#### `.pricebreak-input-white`
White input field for forms:
- Background: `#FFFFFF`
- Border: `#D1D5DB`
- Purple focus state

#### `.pricebreak-select`
Styled select dropdown matching input fields.

### Typography

#### `.pricebreak-title`
Large gradient title text:
- Font size: `2.25rem`
- Gradient: `linear-gradient(135deg, #FFFFFF 0%, #E0E7FF 100%)`
- Font weight: `700`

#### `.pricebreak-subtitle`
Subtitle text with opacity:
- Font size: `1.25rem`
- Opacity: `0.9`

#### `.pricebreak-heading`
Section headings:
- Font size: `1.875rem`
- Font weight: `700`
- Color: `#FFFFFF`

#### `.pricebreak-text`
Body text:
- Font size: `1rem`
- Color: `rgba(255, 255, 255, 0.9)`

#### `.pricebreak-text-muted`
Muted text:
- Color: `rgba(255, 255, 255, 0.7)`

### Statistics Cards

#### `.pricebreak-stats-grid`
Grid layout for statistics cards.

#### `.pricebreak-stat-card`
Individual statistic card with glass morphism.

#### `.pricebreak-stat-icon`
Icon container with color variants:
- `.pricebreak-stat-icon-primary` - Purple
- `.pricebreak-stat-icon-success` - Green
- `.pricebreak-stat-icon-warning` - Yellow
- `.pricebreak-stat-icon-info` - Blue

### Badge Components

#### `.pricebreak-badge`
Base badge class with rounded corners.

#### Color Variants
- `.pricebreak-badge-success` - Green success badge
- `.pricebreak-badge-gray` - Gray neutral badge
- `.pricebreak-badge-warning` - Yellow warning badge
- `.pricebreak-badge-error` - Red error badge

### Notification Components

#### `.pricebreak-notification`
Base notification class.

#### Color Variants
- `.pricebreak-notification-success` - Green success
- `.pricebreak-notification-error` - Red error
- `.pricebreak-notification-warning` - Yellow warning
- `.pricebreak-notification-info` - Blue info

## 🎯 Usage Guidelines

### Page Structure
```erb
<div class="pricebreak-page">
  <header class="pricebreak-header">
    <div class="pricebreak-container">
      <!-- Header content -->
    </div>
  </header>
  
  <main class="pricebreak-container">
    <!-- Main content -->
  </main>
  
  <footer class="pricebreak-card pricebreak-mt-16">
    <!-- Footer content -->
  </footer>
</div>
```

### Statistics Section
```erb
<div class="pricebreak-stats-grid">
  <div class="pricebreak-stat-card">
    <div class="pricebreak-stat-icon pricebreak-stat-icon-primary">
      <!-- Icon -->
    </div>
    <div class="pricebreak-stat-value">123</div>
    <div class="pricebreak-stat-label">Label</div>
  </div>
</div>
```

### Form Structure
```erb
<div class="pricebreak-card-white">
  <form class="pricebreak-form">
    <div class="pricebreak-form-section">
      <div class="pricebreak-form-grid">
        <div class="pricebreak-form-field">
          <label class="pricebreak-form-label">Label</label>
          <input class="pricebreak-input-white" type="text">
          <p class="pricebreak-form-help">Help text</p>
        </div>
      </div>
    </div>
    <div class="pricebreak-form-actions">
      <button class="pricebreak-btn pricebreak-btn-primary">Submit</button>
    </div>
  </form>
</div>
```

## 📱 Responsive Design

The design system includes responsive breakpoints:
- **Mobile**: `< 768px`
- **Tablet**: `768px - 1024px`
- **Desktop**: `> 1024px`

### Mobile Adaptations
- Stacked navigation
- Single column layouts
- Reduced padding and margins
- Touch-friendly button sizes

## 🎨 Visual Effects

### Glass Morphism
- Semi-transparent backgrounds
- Backdrop blur effects
- Subtle borders
- Layered depth

### Hover Effects
- Subtle transforms (`translateY(-1px)`)
- Color transitions
- Shadow enhancements
- Purple glow effects

### Animations
- Smooth transitions (`0.2s ease`)
- Floating logo animation
- Loading spinners
- Micro-interactions

## 🔧 Implementation

### CSS Variables
All design tokens are defined as CSS custom properties for easy theming and maintenance.

### Utility Classes
Comprehensive utility classes for spacing, typography, and layout.

### Component Classes
Semantic component classes that combine multiple utilities for common patterns.

## 📋 Checklist for New Features

When creating new pages or features:

- [ ] Use `.pricebreak-page` as the main container
- [ ] Include `.pricebreak-header` with logo and navigation
- [ ] Use `.pricebreak-container` for content width
- [ ] Apply appropriate card components (`.pricebreak-card` or `.pricebreak-card-white`)
- [ ] Use consistent button styles (`.pricebreak-btn-*`)
- [ ] Apply proper typography hierarchy (`.pricebreak-title`, `.pricebreak-heading`, etc.)
- [ ] Include responsive design considerations
- [ ] Test hover effects and transitions
- [ ] Ensure accessibility with proper contrast ratios
- [ ] Validate form styling consistency

## 🚀 Future Enhancements

- Dark/light theme toggle
- Additional color variants
- Animation library
- Icon system
- Component documentation with live examples
- Design tokens export for other tools

