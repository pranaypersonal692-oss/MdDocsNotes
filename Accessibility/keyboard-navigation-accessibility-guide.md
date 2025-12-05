# Comprehensive Guide to Keyboard Navigation and Accessibility

## Table of Contents
1. [Introduction to Web Accessibility](#introduction-to-web-accessibility)
2. [Keyboard Navigation Fundamentals](#keyboard-navigation-fundamentals)
3. [ARIA (Accessible Rich Internet Applications)](#aria-accessible-rich-internet-applications)
4. [Common UI Component Patterns](#common-ui-component-patterns)
5. [Focus Management](#focus-management)
6. [Screen Reader Considerations](#screen-reader-considerations)
7. [Testing and Validation](#testing-and-validation)
8. [Best Practices and Common Pitfalls](#best-practices-and-common-pitfalls)

---

## Introduction to Web Accessibility

### What is Web Accessibility?

Web accessibility ensures that websites, tools, and technologies are designed and developed so that people with disabilities can use them. This includes people with:

- **Visual impairments** (blindness, low vision, color blindness)
- **Auditory impairments** (deafness, hard of hearing)
- **Motor impairments** (inability to use a mouse, slow response time, limited fine motor control)
- **Cognitive impairments** (learning disabilities, distractibility, inability to focus on large amounts of information)

### Why Keyboard Navigation Matters

Keyboard navigation is crucial because:
- Many users cannot use a mouse due to motor disabilities
- Screen reader users primarily navigate using keyboards
- Power users often prefer keyboard shortcuts for efficiency
- It's a legal requirement in many jurisdictions (ADA, Section 508, WCAG)

### WCAG Guidelines Overview

The Web Content Accessibility Guidelines (WCAG) are organized around four principles (POUR):

1. **Perceivable** - Information must be presentable to users in ways they can perceive
2. **Operable** - User interface components must be operable
3. **Understandable** - Information and operation must be understandable
4. **Robust** - Content must be robust enough to work with assistive technologies

---

## Keyboard Navigation Fundamentals

### Standard Keyboard Keys for Navigation

| Key | Function |
|-----|----------|
| `Tab` | Move focus forward through interactive elements |
| `Shift + Tab` | Move focus backward through interactive elements |
| `Enter` | Activate buttons, links, and submit forms |
| `Space` | Activate buttons, toggle checkboxes, scroll page |
| `Arrow Keys` | Navigate within composite widgets (menus, tabs, radio groups) |
| `Esc` | Close dialogs, dismiss popups, exit modes |
| `Home` | Move to first item in a list or beginning of content |
| `End` | Move to last item in a list or end of content |
| `Page Up/Down` | Scroll content by page |

### The `tabindex` Attribute

The `tabindex` attribute controls the tab order and focusability of elements:

```html
<!-- tabindex="0": Element is focusable and in natural tab order -->
<div tabindex="0">Focusable div in natural order</div>

<!-- tabindex="-1": Element is focusable programmatically but not in tab order -->
<div tabindex="-1">Focusable only via JavaScript</div>

<!-- tabindex="1+" (AVOID): Positive values create custom tab order -->
<!-- This is an anti-pattern and should be avoided -->
<button tabindex="1">Don't do this</button>
```

**Best Practice**: Only use `tabindex="0"` or `tabindex="-1"`. Positive values disrupt the natural reading order and are confusing.

### Focus Indicators

Always provide visible focus indicators:

```css
/* Default browser focus (usually sufficient) */
button:focus {
  outline: 2px solid blue;
  outline-offset: 2px;
}

/* Custom focus indicator */
.custom-button:focus {
  outline: none; /* Only remove if replacing */
  box-shadow: 0 0 0 3px rgba(66, 153, 225, 0.5);
  border-color: #4299e1;
}

/* High contrast focus for better visibility */
.accessible-button:focus-visible {
  outline: 3px solid #000;
  outline-offset: 3px;
}
```

**Important**: Never use `outline: none` without providing an alternative focus indicator!

---

## ARIA (Accessible Rich Internet Applications)

### ARIA Roles

ARIA roles define what an element is or does. Use semantic HTML when possible, ARIA when necessary.

```html
<!-- Semantic HTML (preferred) -->
<button>Click me</button>
<nav><!-- navigation content --></nav>

<!-- ARIA roles (when semantic HTML isn't available) -->
<div role="button" tabindex="0">Click me</div>
<div role="navigation"><!-- navigation content --></div>
```

#### Common ARIA Roles

| Role | Description | Example |
|------|-------------|---------|
| `button` | Interactive element that triggers an action | `<div role="button">` |
| `navigation` | Collection of navigational elements | `<div role="navigation">` |
| `main` | Main content of the page | `<div role="main">` |
| `dialog` | Modal dialog | `<div role="dialog">` |
| `menu` | List of choices or actions | `<div role="menu">` |
| `menuitem` | Item within a menu | `<div role="menuitem">` |
| `tab` | Tab in a tab list | `<div role="tab">` |
| `tabpanel` | Content panel for a tab | `<div role="tabpanel">` |
| `alert` | Important, time-sensitive message | `<div role="alert">` |

### ARIA States and Properties

ARIA attributes provide additional information about elements:

```html
<!-- aria-label: Provides a text label -->
<button aria-label="Close dialog">
  <span aria-hidden="true">×</span>
</button>

<!-- aria-labelledby: References another element for label -->
<div id="dialog-title">Confirm Action</div>
<div role="dialog" aria-labelledby="dialog-title">
  <!-- dialog content -->
</div>

<!-- aria-describedby: References element providing description -->
<input 
  type="email" 
  aria-describedby="email-help"
  required
>
<span id="email-help">We'll never share your email</span>

<!-- aria-expanded: Indicates if element is expanded -->
<button aria-expanded="false" aria-controls="menu">
  Menu
</button>

<!-- aria-hidden: Hides element from assistive technologies -->
<span aria-hidden="true">⭐</span>

<!-- aria-live: Announces dynamic content -->
<div aria-live="polite" aria-atomic="true">
  <!-- Dynamic content that should be announced -->
</div>

<!-- aria-disabled vs disabled -->
<button disabled>Truly disabled</button>
<button aria-disabled="true">Appears disabled but focusable</button>
```

### When to Use ARIA

**The First Rule of ARIA**: Don't use ARIA if you can use native HTML.

```html
<!-- ❌ BAD: Using ARIA when native HTML exists -->
<div role="button" tabindex="0" onclick="submit()">Submit</div>

<!-- ✅ GOOD: Using semantic HTML -->
<button onclick="submit()">Submit</button>
```

**Use ARIA when**:
- Native HTML doesn't provide the needed semantics
- You're creating custom widgets (accordions, tabs, etc.)
- You need to enhance existing HTML semantics
- Providing dynamic updates to users

---

## Common UI Component Patterns

### 1. Modal Dialogs

Modal dialogs must trap focus and provide proper keyboard navigation.

```html
<div 
  role="dialog" 
  aria-labelledby="dialog-title"
  aria-describedby="dialog-desc"
  aria-modal="true"
>
  <h2 id="dialog-title">Delete Confirmation</h2>
  <p id="dialog-desc">Are you sure you want to delete this item?</p>
  
  <button id="cancel-btn">Cancel</button>
  <button id="confirm-btn">Delete</button>
  <button id="close-btn" aria-label="Close dialog">×</button>
</div>
```

```javascript
class AccessibleModal {
  constructor(modalElement) {
    this.modal = modalElement;
    this.focusableElements = null;
    this.firstFocusable = null;
    this.lastFocusable = null;
    this.previouslyFocused = null;
  }

  open() {
    // Store currently focused element
    this.previouslyFocused = document.activeElement;
    
    // Show modal
    this.modal.style.display = 'block';
    this.modal.setAttribute('aria-hidden', 'false');
    
    // Get all focusable elements
    this.focusableElements = this.modal.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    );
    this.firstFocusable = this.focusableElements[0];
    this.lastFocusable = this.focusableElements[this.focusableElements.length - 1];
    
    // Focus first element
    this.firstFocusable.focus();
    
    // Add event listeners
    this.modal.addEventListener('keydown', this.handleKeyDown.bind(this));
    document.addEventListener('focusin', this.handleFocusTrap.bind(this));
  }

  close() {
    // Hide modal
    this.modal.style.display = 'none';
    this.modal.setAttribute('aria-hidden', 'true');
    
    // Remove event listeners
    this.modal.removeEventListener('keydown', this.handleKeyDown.bind(this));
    document.removeEventListener('focusin', this.handleFocusTrap.bind(this));
    
    // Return focus to previously focused element
    if (this.previouslyFocused) {
      this.previouslyFocused.focus();
    }
  }

  handleKeyDown(e) {
    // Close on Escape
    if (e.key === 'Escape') {
      this.close();
      return;
    }

    // Focus trap with Tab
    if (e.key === 'Tab') {
      if (e.shiftKey) {
        // Shift + Tab
        if (document.activeElement === this.firstFocusable) {
          e.preventDefault();
          this.lastFocusable.focus();
        }
      } else {
        // Tab
        if (document.activeElement === this.lastFocusable) {
          e.preventDefault();
          this.firstFocusable.focus();
        }
      }
    }
  }

  handleFocusTrap(e) {
    // If focus moves outside modal, bring it back
    if (!this.modal.contains(e.target)) {
      e.stopPropagation();
      this.firstFocusable.focus();
    }
  }
}

// Usage
const modal = new AccessibleModal(document.getElementById('my-modal'));
document.getElementById('open-modal-btn').addEventListener('click', () => {
  modal.open();
});
document.getElementById('close-btn').addEventListener('click', () => {
  modal.close();
});
```

### 2. Dropdown Menus

Dropdown menus require arrow key navigation and proper ARIA attributes.

```html
<div class="dropdown">
  <button 
    id="menu-button" 
    aria-haspopup="true" 
    aria-expanded="false"
    aria-controls="menu-list"
  >
    Options
  </button>
  
  <ul id="menu-list" role="menu" aria-labelledby="menu-button">
    <li role="menuitem" tabindex="-1">Profile</li>
    <li role="menuitem" tabindex="-1">Settings</li>
    <li role="menuitem" tabindex="-1">Logout</li>
  </ul>
</div>
```

```javascript
class AccessibleDropdown {
  constructor(buttonElement, menuElement) {
    this.button = buttonElement;
    this.menu = menuElement;
    this.menuItems = Array.from(this.menu.querySelectorAll('[role="menuitem"]'));
    this.currentIndex = 0;
    this.isOpen = false;

    this.button.addEventListener('click', () => this.toggle());
    this.button.addEventListener('keydown', (e) => this.handleButtonKeyDown(e));
    this.menu.addEventListener('keydown', (e) => this.handleMenuKeyDown(e));
    
    // Close on outside click
    document.addEventListener('click', (e) => {
      if (!this.button.contains(e.target) && !this.menu.contains(e.target)) {
        this.close();
      }
    });
  }

  toggle() {
    this.isOpen ? this.close() : this.open();
  }

  open() {
    this.isOpen = true;
    this.menu.style.display = 'block';
    this.button.setAttribute('aria-expanded', 'true');
    this.currentIndex = 0;
    this.focusMenuItem(0);
  }

  close() {
    this.isOpen = false;
    this.menu.style.display = 'none';
    this.button.setAttribute('aria-expanded', 'false');
    this.button.focus();
  }

  handleButtonKeyDown(e) {
    switch(e.key) {
      case 'Enter':
      case ' ':
      case 'ArrowDown':
        e.preventDefault();
        this.open();
        break;
      case 'ArrowUp':
        e.preventDefault();
        this.open();
        this.focusMenuItem(this.menuItems.length - 1);
        break;
    }
  }

  handleMenuKeyDown(e) {
    switch(e.key) {
      case 'Escape':
        e.preventDefault();
        this.close();
        break;
      
      case 'ArrowDown':
        e.preventDefault();
        this.currentIndex = (this.currentIndex + 1) % this.menuItems.length;
        this.focusMenuItem(this.currentIndex);
        break;
      
      case 'ArrowUp':
        e.preventDefault();
        this.currentIndex = this.currentIndex === 0 
          ? this.menuItems.length - 1 
          : this.currentIndex - 1;
        this.focusMenuItem(this.currentIndex);
        break;
      
      case 'Home':
        e.preventDefault();
        this.focusMenuItem(0);
        break;
      
      case 'End':
        e.preventDefault();
        this.focusMenuItem(this.menuItems.length - 1);
        break;
      
      case 'Enter':
      case ' ':
        e.preventDefault();
        this.menuItems[this.currentIndex].click();
        this.close();
        break;
    }
  }

  focusMenuItem(index) {
    this.currentIndex = index;
    this.menuItems[index].focus();
  }
}

// Usage
const dropdown = new AccessibleDropdown(
  document.getElementById('menu-button'),
  document.getElementById('menu-list')
);
```

### 3. Tabs

Tab panels should use arrow keys for navigation between tabs.

```html
<div class="tabs">
  <div role="tablist" aria-label="Sample Tabs">
    <button 
      role="tab" 
      aria-selected="true" 
      aria-controls="panel-1"
      id="tab-1"
      tabindex="0"
    >
      Tab 1
    </button>
    <button 
      role="tab" 
      aria-selected="false" 
      aria-controls="panel-2"
      id="tab-2"
      tabindex="-1"
    >
      Tab 2
    </button>
    <button 
      role="tab" 
      aria-selected="false" 
      aria-controls="panel-3"
      id="tab-3"
      tabindex="-1"
    >
      Tab 3
    </button>
  </div>

  <div id="panel-1" role="tabpanel" aria-labelledby="tab-1" tabindex="0">
    <p>Content for Tab 1</p>
  </div>
  <div id="panel-2" role="tabpanel" aria-labelledby="tab-2" tabindex="0" hidden>
    <p>Content for Tab 2</p>
  </div>
  <div id="panel-3" role="tabpanel" aria-labelledby="tab-3" tabindex="0" hidden>
    <p>Content for Tab 3</p>
  </div>
</div>
```

```javascript
class AccessibleTabs {
  constructor(tabListElement) {
    this.tabList = tabListElement;
    this.tabs = Array.from(this.tabList.querySelectorAll('[role="tab"]'));
    this.panels = this.tabs.map(tab => 
      document.getElementById(tab.getAttribute('aria-controls'))
    );
    this.currentIndex = 0;

    // Add event listeners to each tab
    this.tabs.forEach((tab, index) => {
      tab.addEventListener('click', () => this.selectTab(index));
      tab.addEventListener('keydown', (e) => this.handleKeyDown(e, index));
    });
  }

  selectTab(index) {
    // Deselect all tabs
    this.tabs.forEach((tab, i) => {
      const isSelected = i === index;
      tab.setAttribute('aria-selected', isSelected);
      tab.setAttribute('tabindex', isSelected ? '0' : '-1');
      this.panels[i].hidden = !isSelected;
    });

    this.currentIndex = index;
    this.tabs[index].focus();
  }

  handleKeyDown(e, currentIndex) {
    let newIndex = currentIndex;

    switch(e.key) {
      case 'ArrowLeft':
        e.preventDefault();
        newIndex = currentIndex === 0 ? this.tabs.length - 1 : currentIndex - 1;
        this.selectTab(newIndex);
        break;
      
      case 'ArrowRight':
        e.preventDefault();
        newIndex = (currentIndex + 1) % this.tabs.length;
        this.selectTab(newIndex);
        break;
      
      case 'Home':
        e.preventDefault();
        this.selectTab(0);
        break;
      
      case 'End':
        e.preventDefault();
        this.selectTab(this.tabs.length - 1);
        break;
    }
  }
}

// Usage
const tabs = new AccessibleTabs(document.querySelector('[role="tablist"]'));
```

### 4. Accordion

Accordions expand/collapse content sections.

```html
<div class="accordion">
  <h3>
    <button 
      id="accordion1-btn"
      aria-expanded="false"
      aria-controls="accordion1-panel"
    >
      Section 1
      <span aria-hidden="true">▼</span>
    </button>
  </h3>
  <div id="accordion1-panel" role="region" aria-labelledby="accordion1-btn" hidden>
    <p>Content for section 1</p>
  </div>

  <h3>
    <button 
      id="accordion2-btn"
      aria-expanded="false"
      aria-controls="accordion2-panel"
    >
      Section 2
      <span aria-hidden="true">▼</span>
    </button>
  </h3>
  <div id="accordion2-panel" role="region" aria-labelledby="accordion2-btn" hidden>
    <p>Content for section 2</p>
  </div>
</div>
```

```javascript
class AccessibleAccordion {
  constructor(accordionElement) {
    this.accordion = accordionElement;
    this.buttons = Array.from(this.accordion.querySelectorAll('button[aria-expanded]'));
    
    this.buttons.forEach((button, index) => {
      button.addEventListener('click', () => this.toggle(index));
      button.addEventListener('keydown', (e) => this.handleKeyDown(e, index));
    });
  }

  toggle(index) {
    const button = this.buttons[index];
    const panel = document.getElementById(button.getAttribute('aria-controls'));
    const isExpanded = button.getAttribute('aria-expanded') === 'true';

    button.setAttribute('aria-expanded', !isExpanded);
    panel.hidden = isExpanded;
  }

  handleKeyDown(e, currentIndex) {
    let newIndex = currentIndex;

    switch(e.key) {
      case 'ArrowDown':
        e.preventDefault();
        newIndex = (currentIndex + 1) % this.buttons.length;
        this.buttons[newIndex].focus();
        break;
      
      case 'ArrowUp':
        e.preventDefault();
        newIndex = currentIndex === 0 ? this.buttons.length - 1 : currentIndex - 1;
        this.buttons[newIndex].focus();
        break;
      
      case 'Home':
        e.preventDefault();
        this.buttons[0].focus();
        break;
      
      case 'End':
        e.preventDefault();
        this.buttons[this.buttons.length - 1].focus();
        break;
    }
  }
}

// Usage
const accordion = new AccessibleAccordion(document.querySelector('.accordion'));
```

### 5. Custom Checkbox and Radio Buttons

When creating custom styled checkboxes/radios, maintain accessibility.

```html
<!-- Native checkbox with custom styling (BEST) -->
<label class="custom-checkbox">
  <input type="checkbox" class="visually-hidden">
  <span class="checkbox-custom"></span>
  I agree to terms
</label>

<!-- Custom checkbox with ARIA (when native isn't possible) -->
<div 
  role="checkbox" 
  aria-checked="false" 
  tabindex="0"
  class="custom-checkbox-aria"
>
  Custom Checkbox
</div>

<!-- Radio group -->
<fieldset>
  <legend>Choose an option</legend>
  <div role="radiogroup" aria-labelledby="radio-label">
    <div 
      role="radio" 
      aria-checked="true"
      tabindex="0"
      data-value="option1"
    >
      Option 1
    </div>
    <div 
      role="radio" 
      aria-checked="false"
      tabindex="-1"
      data-value="option2"
    >
      Option 2
    </div>
    <div 
      role="radio" 
      aria-checked="false"
      tabindex="-1"
      data-value="option3"
    >
      Option 3
    </div>
  </div>
</fieldset>
```

```css
/* Visually hidden but accessible to screen readers */
.visually-hidden {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}

/* Custom checkbox styling */
.custom-checkbox {
  display: flex;
  align-items: center;
  cursor: pointer;
}

.checkbox-custom {
  width: 20px;
  height: 20px;
  border: 2px solid #333;
  border-radius: 4px;
  margin-right: 8px;
  display: inline-block;
  position: relative;
}

.custom-checkbox input:checked + .checkbox-custom::after {
  content: '✓';
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  color: #fff;
  background: #007bff;
}

.custom-checkbox input:focus + .checkbox-custom {
  outline: 2px solid #007bff;
  outline-offset: 2px;
}
```

```javascript
// Custom checkbox with ARIA
class CustomCheckbox {
  constructor(element) {
    this.element = element;
    this.checked = element.getAttribute('aria-checked') === 'true';
    
    this.element.addEventListener('click', () => this.toggle());
    this.element.addEventListener('keydown', (e) => this.handleKeyDown(e));
  }

  toggle() {
    this.checked = !this.checked;
    this.element.setAttribute('aria-checked', this.checked);
  }

  handleKeyDown(e) {
    if (e.key === ' ' || e.key === 'Enter') {
      e.preventDefault();
      this.toggle();
    }
  }
}

// Radio group
class RadioGroup {
  constructor(groupElement) {
    this.group = groupElement;
    this.radios = Array.from(this.group.querySelectorAll('[role="radio"]'));
    this.currentIndex = this.radios.findIndex(
      radio => radio.getAttribute('aria-checked') === 'true'
    );

    this.radios.forEach((radio, index) => {
      radio.addEventListener('click', () => this.select(index));
      radio.addEventListener('keydown', (e) => this.handleKeyDown(e, index));
    });
  }

  select(index) {
    this.radios.forEach((radio, i) => {
      const isSelected = i === index;
      radio.setAttribute('aria-checked', isSelected);
      radio.setAttribute('tabindex', isSelected ? '0' : '-1');
    });
    this.currentIndex = index;
    this.radios[index].focus();
  }

  handleKeyDown(e, currentIndex) {
    let newIndex = currentIndex;

    switch(e.key) {
      case 'ArrowDown':
      case 'ArrowRight':
        e.preventDefault();
        newIndex = (currentIndex + 1) % this.radios.length;
        this.select(newIndex);
        break;
      
      case 'ArrowUp':
      case 'ArrowLeft':
        e.preventDefault();
        newIndex = currentIndex === 0 ? this.radios.length - 1 : currentIndex - 1;
        this.select(newIndex);
        break;
      
      case ' ':
        e.preventDefault();
        this.select(currentIndex);
        break;
    }
  }
}
```

### 6. Tooltips

Tooltips provide additional information on hover/focus.

```html
<button 
  aria-describedby="tooltip-1"
  class="tooltip-trigger"
>
  Help
  <span id="tooltip-1" role="tooltip" class="tooltip-content" hidden>
    This provides helpful information
  </span>
</button>
```

```javascript
class AccessibleTooltip {
  constructor(triggerElement) {
    this.trigger = triggerElement;
    this.tooltipId = this.trigger.getAttribute('aria-describedby');
    this.tooltip = document.getElementById(this.tooltipId);
    this.isVisible = false;

    // Show on hover
    this.trigger.addEventListener('mouseenter', () => this.show());
    this.trigger.addEventListener('mouseleave', () => this.hide());
    
    // Show on focus
    this.trigger.addEventListener('focus', () => this.show());
    this.trigger.addEventListener('blur', () => this.hide());
    
    // Show/hide with Escape
    this.trigger.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && this.isVisible) {
        this.hide();
      }
    });
  }

  show() {
    this.tooltip.hidden = false;
    this.isVisible = true;
  }

  hide() {
    this.tooltip.hidden = true;
    this.isVisible = false;
  }
}
```

### 7. Autocomplete/Combobox

Autocomplete provides suggestions as users type.

```html
<div class="combobox">
  <label for="search-input">Search</label>
  <input
    type="text"
    id="search-input"
    role="combobox"
    aria-autocomplete="list"
    aria-expanded="false"
    aria-controls="suggestions-list"
    aria-activedescendant=""
  >
  <ul 
    id="suggestions-list" 
    role="listbox"
    hidden
  >
    <!-- Suggestions populated dynamically -->
  </ul>
</div>
```

```javascript
class AccessibleCombobox {
  constructor(inputElement, listElement, suggestions) {
    this.input = inputElement;
    this.list = listElement;
    this.allSuggestions = suggestions;
    this.filteredSuggestions = [];
    this.currentIndex = -1;

    this.input.addEventListener('input', () => this.handleInput());
    this.input.addEventListener('keydown', (e) => this.handleKeyDown(e));
    this.list.addEventListener('click', (e) => this.handleClick(e));
    
    // Close on outside click
    document.addEventListener('click', (e) => {
      if (!this.input.contains(e.target) && !this.list.contains(e.target)) {
        this.close();
      }
    });
  }

  handleInput() {
    const query = this.input.value.toLowerCase();
    
    if (query.length === 0) {
      this.close();
      return;
    }

    this.filteredSuggestions = this.allSuggestions.filter(
      item => item.toLowerCase().includes(query)
    );

    if (this.filteredSuggestions.length > 0) {
      this.open();
      this.renderSuggestions();
    } else {
      this.close();
    }
  }

  renderSuggestions() {
    this.list.innerHTML = '';
    
    this.filteredSuggestions.forEach((suggestion, index) => {
      const li = document.createElement('li');
      li.setAttribute('role', 'option');
      li.setAttribute('id', `suggestion-${index}`);
      li.textContent = suggestion;
      li.dataset.index = index;
      this.list.appendChild(li);
    });

    this.currentIndex = -1;
  }

  open() {
    this.list.hidden = false;
    this.input.setAttribute('aria-expanded', 'true');
  }

  close() {
    this.list.hidden = true;
    this.input.setAttribute('aria-expanded', 'false');
    this.input.setAttribute('aria-activedescendant', '');
    this.currentIndex = -1;
  }

  handleKeyDown(e) {
    const isOpen = this.input.getAttribute('aria-expanded') === 'true';
    
    if (!isOpen && (e.key === 'ArrowDown' || e.key === 'ArrowUp')) {
      this.handleInput();
      return;
    }

    if (!isOpen) return;

    switch(e.key) {
      case 'ArrowDown':
        e.preventDefault();
        this.currentIndex = Math.min(
          this.currentIndex + 1, 
          this.filteredSuggestions.length - 1
        );
        this.highlightOption();
        break;
      
      case 'ArrowUp':
        e.preventDefault();
        this.currentIndex = Math.max(this.currentIndex - 1, 0);
        this.highlightOption();
        break;
      
      case 'Enter':
        e.preventDefault();
        if (this.currentIndex >= 0) {
          this.selectOption(this.currentIndex);
        }
        break;
      
      case 'Escape':
        e.preventDefault();
        this.close();
        break;
    }
  }

  highlightOption() {
    const options = this.list.querySelectorAll('[role="option"]');
    options.forEach((option, index) => {
      option.setAttribute('aria-selected', index === this.currentIndex);
    });
    
    if (this.currentIndex >= 0) {
      this.input.setAttribute(
        'aria-activedescendant', 
        `suggestion-${this.currentIndex}`
      );
    }
  }

  selectOption(index) {
    this.input.value = this.filteredSuggestions[index];
    this.close();
  }

  handleClick(e) {
    if (e.target.hasAttribute('role') && e.target.getAttribute('role') === 'option') {
      const index = parseInt(e.target.dataset.index);
      this.selectOption(index);
    }
  }
}

// Usage
const combobox = new AccessibleCombobox(
  document.getElementById('search-input'),
  document.getElementById('suggestions-list'),
  ['Apple', 'Banana', 'Cherry', 'Date', 'Elderberry', 'Fig', 'Grape']
);
```

### 8. Data Tables

Tables need proper headers and navigation support.

```html
<table>
  <caption>Employee Information</caption>
  <thead>
    <tr>
      <th scope="col">Name</th>
      <th scope="col">Department</th>
      <th scope="col">Email</th>
      <th scope="col">Actions</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th scope="row">John Doe</th>
      <td>Engineering</td>
      <td>john@example.com</td>
      <td>
        <button aria-label="Edit John Doe">Edit</button>
        <button aria-label="Delete John Doe">Delete</button>
      </td>
    </tr>
    <tr>
      <th scope="row">Jane Smith</th>
      <td>Marketing</td>
      <td>jane@example.com</td>
      <td>
        <button aria-label="Edit Jane Smith">Edit</button>
        <button aria-label="Delete Jane Smith">Delete</button>
      </td>
    </tr>
  </tbody>
</table>
```

**Key Points**:
- Use `<caption>` to label the table
- Use `scope="col"` for column headers
- Use `scope="row"` for row headers
- Provide descriptive `aria-label` for action buttons
- Consider `aria-sort` for sortable columns

### 9. Carousel/Slider

Carousels must be keyboard navigable and pausable.

```html
<div class="carousel" role="region" aria-label="Featured Products">
  <div class="carousel-controls">
    <button aria-label="Previous slide">Previous</button>
    <button aria-label="Pause automatic rotation">Pause</button>
    <button aria-label="Next slide">Next</button>
  </div>
  
  <div class="carousel-slides">
    <div class="slide" aria-hidden="false">
      <img src="product1.jpg" alt="Product 1 description">
    </div>
    <div class="slide" aria-hidden="true">
      <img src="product2.jpg" alt="Product 2 description">
    </div>
    <div class="slide" aria-hidden="true">
      <img src="product3.jpg" alt="Product 3 description">
    </div>
  </div>
  
  <div role="tablist" aria-label="Slide indicators">
    <button role="tab" aria-selected="true" aria-controls="slide-1">1</button>
    <button role="tab" aria-selected="false" aria-controls="slide-2">2</button>
    <button role="tab" aria-selected="false" aria-controls="slide-3">3</button>
  </div>
</div>
```

```javascript
class AccessibleCarousel {
  constructor(carouselElement) {
    this.carousel = carouselElement;
    this.slides = Array.from(this.carousel.querySelectorAll('.slide'));
    this.indicators = Array.from(this.carousel.querySelectorAll('[role="tab"]'));
    this.prevBtn = this.carousel.querySelector('[aria-label*="Previous"]');
    this.nextBtn = this.carousel.querySelector('[aria-label*="Next"]');
    this.pauseBtn = this.carousel.querySelector('[aria-label*="Pause"]');
    
    this.currentIndex = 0;
    this.isPlaying = true;
    this.interval = null;

    this.prevBtn.addEventListener('click', () => this.previous());
    this.nextBtn.addEventListener('click', () => this.next());
    this.pauseBtn.addEventListener('click', () => this.togglePlay());
    
    this.indicators.forEach((indicator, index) => {
      indicator.addEventListener('click', () => this.goToSlide(index));
    });

    // Pause on hover
    this.carousel.addEventListener('mouseenter', () => this.pause());
    this.carousel.addEventListener('mouseleave', () => this.play());

    this.startAutoPlay();
  }

  showSlide(index) {
    this.slides.forEach((slide, i) => {
      slide.setAttribute('aria-hidden', i !== index);
      slide.style.display = i === index ? 'block' : 'none';
    });

    this.indicators.forEach((indicator, i) => {
      indicator.setAttribute('aria-selected', i === index);
    });

    this.currentIndex = index;
    
    // Announce to screen readers
    const liveRegion = document.getElementById('carousel-live-region');
    if (liveRegion) {
      liveRegion.textContent = `Slide ${index + 1} of ${this.slides.length}`;
    }
  }

  next() {
    const nextIndex = (this.currentIndex + 1) % this.slides.length;
    this.goToSlide(nextIndex);
  }

  previous() {
    const prevIndex = this.currentIndex === 0 
      ? this.slides.length - 1 
      : this.currentIndex - 1;
    this.goToSlide(prevIndex);
  }

  goToSlide(index) {
    this.showSlide(index);
  }

  togglePlay() {
    this.isPlaying ? this.pause() : this.play();
  }

  play() {
    if (!this.isPlaying) {
      this.isPlaying = true;
      this.pauseBtn.textContent = 'Pause';
      this.pauseBtn.setAttribute('aria-label', 'Pause automatic rotation');
      this.startAutoPlay();
    }
  }

  pause() {
    if (this.isPlaying) {
      this.isPlaying = false;
      this.pauseBtn.textContent = 'Play';
      this.pauseBtn.setAttribute('aria-label', 'Resume automatic rotation');
      this.stopAutoPlay();
    }
  }

  startAutoPlay() {
    this.interval = setInterval(() => this.next(), 5000);
  }

  stopAutoPlay() {
    if (this.interval) {
      clearInterval(this.interval);
      this.interval = null;
    }
  }
}

// Add live region for announcements
const liveRegion = document.createElement('div');
liveRegion.id = 'carousel-live-region';
liveRegion.setAttribute('aria-live', 'polite');
liveRegion.setAttribute('aria-atomic', 'true');
liveRegion.className = 'visually-hidden';
document.body.appendChild(liveRegion);
```

---

## Focus Management

### Managing Focus After Actions

When content is added, removed, or changed, manage focus appropriately.

```javascript
// Example: Deleting an item from a list
function deleteItem(itemId) {
  const item = document.getElementById(itemId);
  const nextItem = item.nextElementSibling;
  const prevItem = item.previousElementSibling;
  
  // Remove the item
  item.remove();
  
  // Move focus to next or previous item
  if (nextItem) {
    nextItem.querySelector('button').focus();
  } else if (prevItem) {
    prevItem.querySelector('button').focus();
  } else {
    // No items left, focus on add button or container
    document.getElementById('add-item-btn').focus();
  }
}

// Example: Adding an item
function addItem(itemData) {
  const list = document.getElementById('item-list');
  const newItem = createItemElement(itemData);
  
  list.appendChild(newItem);
  
  // Focus on the newly added item
  newItem.querySelector('button').focus();
  
  // Optionally announce to screen readers
  announceToScreenReader(`Item "${itemData.name}" added`);
}

function announceToScreenReader(message) {
  const liveRegion = document.getElementById('announcements');
  liveRegion.textContent = message;
  
  // Clear after announcement
  setTimeout(() => {
    liveRegion.textContent = '';
  }, 1000);
}
```

### Skip Links

Skip links allow users to bypass repetitive navigation.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Page Title</title>
  <style>
    .skip-link {
      position: absolute;
      top: -40px;
      left: 0;
      background: #000;
      color: #fff;
      padding: 8px;
      text-decoration: none;
      z-index: 100;
    }
    
    .skip-link:focus {
      top: 0;
    }
  </style>
</head>
<body>
  <a href="#main-content" class="skip-link">Skip to main content</a>
  <a href="#navigation" class="skip-link">Skip to navigation</a>
  
  <nav id="navigation">
    <!-- Navigation content -->
  </nav>
  
  <main id="main-content" tabindex="-1">
    <!-- Main content -->
  </main>
</body>
</html>
```

### Focus Visible vs Focus

Use `:focus-visible` to show focus only for keyboard users.

```css
/* Show focus for all interactions */
button:focus {
  outline: 2px solid blue;
}

/* Show focus only for keyboard navigation */
button:focus-visible {
  outline: 2px solid blue;
}

/* Remove focus for mouse clicks (when :focus-visible is supported) */
button:focus:not(:focus-visible) {
  outline: none;
}
```

---

## Screen Reader Considerations

### Live Regions

Live regions announce dynamic content changes.

```html
<!-- Polite: Waits for user to finish current task -->
<div aria-live="polite" aria-atomic="true">
  <!-- Updates announced when convenient -->
</div>

<!-- Assertive: Interrupts immediately -->
<div aria-live="assertive" aria-atomic="true">
  <!-- Critical updates announced immediately -->
</div>

<!-- Off: No announcements -->
<div aria-live="off">
  <!-- Updates not announced -->
</div>
```

**Best Practices**:
- Use `aria-atomic="true"` to read entire region
- Use `aria-atomic="false"` to read only changed parts
- Keep messages concise and clear
- Use `polite` for most cases
- Use `assertive` only for critical errors or warnings

```javascript
// Example: Form validation announcements
class FormValidator {
  constructor(formElement) {
    this.form = formElement;
    this.liveRegion = this.createLiveRegion();
  }

  createLiveRegion() {
    const region = document.createElement('div');
    region.setAttribute('aria-live', 'assertive');
    region.setAttribute('aria-atomic', 'true');
    region.className = 'visually-hidden';
    document.body.appendChild(region);
    return region;
  }

  validate() {
    const errors = [];
    
    // Perform validation
    const emailInput = this.form.querySelector('[type="email"]');
    if (!emailInput.value.includes('@')) {
      errors.push('Email address is invalid');
      emailInput.setAttribute('aria-invalid', 'true');
    } else {
      emailInput.setAttribute('aria-invalid', 'false');
    }

    if (errors.length > 0) {
      this.announceErrors(errors);
      return false;
    }

    return true;
  }

  announceErrors(errors) {
    const message = `Form has ${errors.length} error${errors.length > 1 ? 's' : ''}: ${errors.join(', ')}`;
    this.liveRegion.textContent = message;
  }
}
```

### Screen Reader Only Text

Content visible only to screen readers.

```html
<button>
  <span aria-hidden="true">×</span>
  <span class="visually-hidden">Close dialog</span>
</button>

<a href="/profile">
  Profile
  <span class="visually-hidden">(current page)</span>
</a>
```

### Reading Order

Ensure logical reading order in HTML structure.

```html
<!-- ❌ BAD: Visual order doesn't match DOM order -->
<div style="display: flex; flex-direction: column-reverse;">
  <div>This appears second visually</div>
  <div>This appears first visually</div>
</div>

<!-- ✅ GOOD: DOM order matches visual order -->
<div style="display: flex; flex-direction: column;">
  <div>This appears first</div>
  <div>This appears second</div>
</div>
```

---

## Testing and Validation

### Automated Testing Tools

1. **Browser Extensions**:
   - axe DevTools
   - WAVE
   - Lighthouse (Chrome DevTools)
   - ARC Toolkit

2. **Command Line Tools**:
   - pa11y
   - axe-core
   - lighthouse-ci

3. **Testing Libraries**:
   - jest-axe
   - cypress-axe
   - @testing-library/react with accessibility queries

### Manual Testing

#### Keyboard Testing Checklist

- [ ] Can you reach all interactive elements with Tab?
- [ ] Is the tab order logical?
- [ ] Are focus indicators visible?
- [ ] Can you activate all buttons with Enter or Space?
- [ ] Do modals trap focus correctly?
- [ ] Can you close modals with Escape?
- [ ] Do dropdowns work with arrow keys?
- [ ] Can you navigate forms without a mouse?

#### Screen Reader Testing

Test with popular screen readers:
- **NVDA** (Windows, free)
- **JAWS** (Windows, paid)
- **VoiceOver** (Mac/iOS, built-in)
- **TalkBack** (Android, built-in)

**Basic Commands**:

| Screen Reader | Navigate | Activate | Headings | Links |
|---------------|----------|----------|----------|-------|
| NVDA | Arrow keys | Enter | H | K |
| JAWS | Arrow keys | Enter | H | K |
| VoiceOver | VO+Arrow | VO+Space | VO+Cmd+H | VO+Cmd+L |

### Accessibility Testing Script

```javascript
// Basic accessibility checks
function checkAccessibility(element) {
  const issues = [];

  // Check for alt text on images
  const images = element.querySelectorAll('img');
  images.forEach((img, index) => {
    if (!img.hasAttribute('alt')) {
      issues.push(`Image ${index + 1} missing alt attribute`);
    }
  });

  // Check for form labels
  const inputs = element.querySelectorAll('input, select, textarea');
  inputs.forEach((input, index) => {
    const id = input.id;
    const hasLabel = id && document.querySelector(`label[for="${id}"]`);
    const hasAriaLabel = input.hasAttribute('aria-label') || 
                        input.hasAttribute('aria-labelledby');
    
    if (!hasLabel && !hasAriaLabel) {
      issues.push(`Input ${index + 1} missing label`);
    }
  });

  // Check for heading hierarchy
  const headings = Array.from(element.querySelectorAll('h1, h2, h3, h4, h5, h6'));
  let previousLevel = 0;
  headings.forEach((heading, index) => {
    const level = parseInt(heading.tagName[1]);
    if (level > previousLevel + 1) {
      issues.push(`Heading level skip: jumped from h${previousLevel} to h${level}`);
    }
    previousLevel = level;
  });

  // Check for empty links
  const links = element.querySelectorAll('a');
  links.forEach((link, index) => {
    const hasText = link.textContent.trim().length > 0;
    const hasAriaLabel = link.hasAttribute('aria-label') || 
                        link.hasAttribute('aria-labelledby');
    
    if (!hasText && !hasAriaLabel) {
      issues.push(`Link ${index + 1} is empty`);
    }
  });

  // Check for buttons without accessible names
  const buttons = element.querySelectorAll('button');
  buttons.forEach((button, index) => {
    const hasText = button.textContent.trim().length > 0;
    const hasAriaLabel = button.hasAttribute('aria-label') || 
                        button.hasAttribute('aria-labelledby');
    
    if (!hasText && !hasAriaLabel) {
      issues.push(`Button ${index + 1} has no accessible name`);
    }
  });

  return issues;
}

// Usage
const issues = checkAccessibility(document.body);
if (issues.length > 0) {
  console.error('Accessibility issues found:', issues);
} else {
  console.log('No accessibility issues detected');
}
```

---

## Best Practices and Common Pitfalls

### Best Practices

1. **Use Semantic HTML First**
   ```html
   <!-- ✅ GOOD -->
   <button>Click me</button>
   <nav>...</nav>
   <header>...</header>
   
   <!-- ❌ BAD -->
   <div onclick="...">Click me</div>
   <div class="nav">...</div>
   <div class="header">...</div>
   ```

2. **Provide Text Alternatives**
   ```html
   <!-- Images -->
   <img src="chart.png" alt="Sales increased by 25% in Q4">
   
   <!-- Icon buttons -->
   <button aria-label="Search">
     <i class="icon-search" aria-hidden="true"></i>
   </button>
   
   <!-- Decorative images -->
   <img src="decorative.png" alt="" role="presentation">
   ```

3. **Ensure Sufficient Color Contrast**
   - Normal text: 4.5:1 minimum
   - Large text (18pt+ or 14pt+ bold): 3:1 minimum
   - Use tools like WebAIM Contrast Checker

4. **Don't Rely on Color Alone**
   ```html
   <!-- ❌ BAD: Color only -->
   <span style="color: red;">Error</span>
   
   <!-- ✅ GOOD: Icon + color + text -->
   <span style="color: red;">
     <span aria-hidden="true">⚠</span>
     Error: Invalid email address
   </span>
   ```

5. **Make Click Targets Large Enough**
   - Minimum 44x44 pixels for touch targets
   - Provide adequate spacing between interactive elements

6. **Support Keyboard Navigation**
   - All functionality available via keyboard
   - Logical tab order
   - Visible focus indicators

### Common Pitfalls

#### 1. Removing Focus Outlines

```css
/* ❌ NEVER do this without replacement */
*:focus {
  outline: none;
}

/* ✅ GOOD: Provide alternative */
button:focus-visible {
  outline: 2px solid #007bff;
  outline-offset: 2px;
}
```

#### 2. Using Placeholder as Label

```html
<!-- ❌ BAD -->
<input type="text" placeholder="Enter your name">

<!-- ✅ GOOD -->
<label for="name">Name</label>
<input type="text" id="name" placeholder="e.g., John Doe">
```

#### 3. Non-Descriptive Link Text

```html
<!-- ❌ BAD -->
<a href="/report.pdf">Click here</a> to download the report.

<!-- ✅ GOOD -->
<a href="/report.pdf">Download Q4 2024 Financial Report (PDF, 2MB)</a>
```

#### 4. Auto-Playing Media

```html
<!-- ❌ BAD -->
<video autoplay>
  <source src="video.mp4">
</video>

<!-- ✅ GOOD -->
<video controls>
  <source src="video.mp4">
  <track kind="captions" src="captions.vtt" srclang="en">
</video>
```

#### 5. Opening New Windows Without Warning

```html
<!-- ❌ BAD -->
<a href="external.com" target="_blank">External link</a>

<!-- ✅ GOOD -->
<a href="external.com" target="_blank" rel="noopener noreferrer">
  External link
  <span class="visually-hidden">(opens in new window)</span>
</a>
```

#### 6. Fake Buttons

```html
<!-- ❌ BAD -->
<div onclick="submit()">Submit</div>

<!-- ✅ GOOD -->
<button onclick="submit()">Submit</button>
```

#### 7. Incorrect ARIA Usage

```html
<!-- ❌ BAD: Contradicting native semantics -->
<button role="link">Click me</button>

<!-- ✅ GOOD: Using appropriate element -->
<a href="/page">Click me</a>

<!-- ❌ BAD: Redundant ARIA -->
<button role="button">Click me</button>

<!-- ✅ GOOD: No unnecessary ARIA -->
<button>Click me</button>
```

#### 8. Missing Form Labels

```html
<!-- ❌ BAD -->
<input type="text" name="email">

<!-- ✅ GOOD -->
<label for="email">Email address</label>
<input type="text" id="email" name="email">
```

---

## Advanced Patterns

### 1. Roving TabIndex

For composite widgets like toolbars, only one item should be in tab order.

```javascript
class RovingTabIndex {
  constructor(containerElement) {
    this.container = containerElement;
    this.items = Array.from(this.container.querySelectorAll('[role="button"]'));
    this.currentIndex = 0;

    this.items.forEach((item, index) => {
      item.setAttribute('tabindex', index === 0 ? '0' : '-1');
      item.addEventListener('keydown', (e) => this.handleKeyDown(e, index));
      item.addEventListener('click', () => this.setFocus(index));
    });
  }

  handleKeyDown(e, currentIndex) {
    let newIndex = currentIndex;

    switch(e.key) {
      case 'ArrowRight':
      case 'ArrowDown':
        e.preventDefault();
        newIndex = (currentIndex + 1) % this.items.length;
        break;
      
      case 'ArrowLeft':
      case 'ArrowUp':
        e.preventDefault();
        newIndex = currentIndex === 0 ? this.items.length - 1 : currentIndex - 1;
        break;
      
      case 'Home':
        e.preventDefault();
        newIndex = 0;
        break;
      
      case 'End':
        e.preventDefault();
        newIndex = this.items.length - 1;
        break;
      
      default:
        return;
    }

    this.setFocus(newIndex);
  }

  setFocus(index) {
    this.items.forEach((item, i) => {
      item.setAttribute('tabindex', i === index ? '0' : '-1');
    });
    
    this.currentIndex = index;
    this.items[index].focus();
  }
}
```

### 2. Listbox with TypeAhead

Allow users to jump to items by typing.

```javascript
class TypeAheadListbox {
  constructor(listboxElement) {
    this.listbox = listboxElement;
    this.options = Array.from(this.listbox.querySelectorAll('[role="option"]'));
    this.currentIndex = 0;
    this.searchString = '';
    this.searchTimeout = null;

    this.listbox.addEventListener('keydown', (e) => this.handleKeyDown(e));
  }

  handleKeyDown(e) {
    // Handle typeahead
    if (e.key.length === 1 && /[a-zA-Z0-9]/.test(e.key)) {
      e.preventDefault();
      this.handleTypeAhead(e.key);
      return;
    }

    // Other navigation...
  }

  handleTypeAhead(char) {
    clearTimeout(this.searchTimeout);
    
    this.searchString += char.toLowerCase();
    
    // Find matching option
    const matchIndex = this.options.findIndex(option =>
      option.textContent.toLowerCase().startsWith(this.searchString)
    );

    if (matchIndex !== -1) {
      this.selectOption(matchIndex);
    }

    // Clear search string after 500ms
    this.searchTimeout = setTimeout(() => {
      this.searchString = '';
    }, 500);
  }

  selectOption(index) {
    this.options.forEach((option, i) => {
      option.setAttribute('aria-selected', i === index);
    });
    this.currentIndex = index;
    this.options[index].focus();
  }
}
```

### 3. Infinite Scroll with Announcements

```javascript
class AccessibleInfiniteScroll {
  constructor(containerElement, loadMoreFn) {
    this.container = containerElement;
    this.loadMore = loadMoreFn;
    this.isLoading = false;
    this.liveRegion = this.createLiveRegion();

    this.observer = new IntersectionObserver(
      (entries) => this.handleIntersection(entries),
      { threshold: 0.1 }
    );

    this.sentinel = document.createElement('div');
    this.sentinel.className = 'scroll-sentinel';
    this.container.appendChild(this.sentinel);
    this.observer.observe(this.sentinel);
  }

  createLiveRegion() {
    const region = document.createElement('div');
    region.setAttribute('aria-live', 'polite');
    region.setAttribute('aria-atomic', 'true');
    region.className = 'visually-hidden';
    document.body.appendChild(region);
    return region;
  }

  async handleIntersection(entries) {
    if (entries[0].isIntersecting && !this.isLoading) {
      this.isLoading = true;
      this.announce('Loading more items');
      
      const newItems = await this.loadMore();
      
      this.announce(`${newItems.length} new items loaded`);
      this.isLoading = false;
    }
  }

  announce(message) {
    this.liveRegion.textContent = message;
  }
}
```

---

## Conclusion

Accessibility and keyboard navigation are essential for creating inclusive web applications. Key takeaways:

1. **Use semantic HTML** whenever possible
2. **Provide keyboard navigation** for all interactive elements
3. **Manage focus** appropriately when content changes
4. **Use ARIA** to enhance semantics when HTML isn't sufficient
5. **Test with real users** and assistive technologies
6. **Make accessibility** a part of your development process, not an afterthought

Remember: Accessibility benefits everyone, not just users with disabilities. A well-structured, keyboard-navigable, accessible website is often more usable for all users.

---

## Additional Resources

### Documentation
- [WAI-ARIA Authoring Practices Guide (APG)](https://www.w3.org/WAI/ARIA/apg/)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [MDN Accessibility](https://developer.mozilla.org/en-US/docs/Web/Accessibility)

### Tools
- [axe DevTools](https://www.deque.com/axe/devtools/)
- [WAVE Browser Extension](https://wave.webaim.org/extension/)
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)

### Screen Readers
- [NVDA (Free)](https://www.nvaccess.org/)
- [VoiceOver (Built into macOS)](https://www.apple.com/accessibility/voiceover/)
- [JAWS](https://www.freedomscientific.com/products/software/jaws/)

### Testing
- [pa11y](https://pa11y.org/)
- [axe-core](https://github.com/dequelabs/axe-core)
- [Lighthouse](https://developers.google.com/web/tools/lighthouse)
