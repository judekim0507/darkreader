# Dark Reader API - Complete Command Reference

## All Available Commands

```javascript
DarkReader.enable()          // Enable dark mode
DarkReader.disable()         // Disable dark mode
DarkReader.auto()            // Follow system preference
DarkReader.isEnabled()       // Check if enabled
DarkReader.exportGeneratedCSS() // Get generated CSS
DarkReader.setFetchMethod()  // Set custom fetch function
```

---

## 1. DarkReader.enable()

**Enable dark mode with custom theme options**

### Basic Usage
```javascript
DarkReader.enable();  // Use default settings
```

### Full Options
```javascript
DarkReader.enable({
    // === CORE SETTINGS ===
    
    brightness: 100,        // 50-200 (Default: 100)
    contrast: 100,          // 50-200 (Default: 100)
    sepia: 0,               // 0-100  (Default: 0)
    grayscale: 0,           // 0-100  (Default: 0)
    
    // === MODE ===
    
    mode: 1,                // 0 = Filter Mode, 1 = Dark Mode (Default: 1)
    
    // === COLOR TINTING (Boosts Feature) ===
    
    tintColor: '#FF6B6B',   // Any CSS color (Default: '')
    tintStrength: 30,       // 0-100 (Default: 0)
    
    // === DARK MODE COLORS ===
    
    darkSchemeBackgroundColor: '#181a1b',  // Default: '#181a1b'
    darkSchemeTextColor: '#e8e6e3',        // Default: '#e8e6e3'
    
    // === LIGHT MODE COLORS (when mode = 0) ===
    
    lightSchemeBackgroundColor: '#dcdad7', // Default: '#dcdad7'
    lightSchemeTextColor: '#181a1b',       // Default: '#181a1b'
    
    // === SCROLLBAR ===
    
    scrollbarColor: 'auto',  // 'auto' | '' | '#FF0000' (Default: '')
    
    // === TEXT SELECTION ===
    
    selectionColor: 'auto',  // 'auto' | '' | '#0096FF' (Default: 'auto')
    
    // === FONT ===
    
    useFont: false,          // Use custom font (Default: false)
    fontFamily: 'Arial',     // Font name (Default: system font)
    textStroke: 0,           // Text stroke 0-1px (Default: 0)
    
    // === ADVANCED ===
    
    styleSystemControls: true  // Style input/button (Default: true)
});
```

### With Site-Specific Fixes
```javascript
DarkReader.enable(
    {
        brightness: 100,
        contrast: 90
    },
    {
        // === FIXES ===
        
        invert: ['.logo', '#icon'],           // CSS selectors to invert
        css: 'body { color: red !important }', // Custom CSS
        ignoreInlineStyle: ['.color-picker'],  // Don't analyze inline styles
        ignoreImageAnalysis: ['.hero-image'],  // Don't process images
        disableStyleSheetsProxy: false         // Disable proxy (advanced)
    }
);
```

---

## 2. DarkReader.disable()

**Disable dark mode**

### Usage
```javascript
DarkReader.disable();
```

No parameters. This removes all dark mode modifications.

---

## 3. DarkReader.auto()

**Enable/disable automatic dark mode based on system preference**

### Enable Auto Mode
```javascript
// Follow system preference
DarkReader.auto({
    brightness: 100,
    contrast: 90,
    tintColor: '#FF8C42',
    tintStrength: 25
});

// Same options as enable()
DarkReader.auto({
    mode: 1,
    brightness: 110,
    contrast: 95
}, {
    invert: ['.logo']
});
```

### Disable Auto Mode
```javascript
DarkReader.auto(false);
```

### How It Works
- Monitors `prefers-color-scheme` media query
- Enables dark mode when system is dark
- Disables dark mode when system is light
- Automatically updates when system changes

---

## 4. DarkReader.isEnabled()

**Check if dark mode is currently enabled**

### Usage
```javascript
const enabled = DarkReader.isEnabled();

if (enabled) {
    console.log('Dark mode is ON');
} else {
    console.log('Dark mode is OFF');
}
```

### Returns
- `true` if dark mode is enabled
- `false` if dark mode is disabled

---

## 5. DarkReader.exportGeneratedCSS()

**Get the generated CSS as a string**

### Usage
```javascript
// Async function - returns Promise
const css = await DarkReader.exportGeneratedCSS();
console.log(css);

// Or with .then()
DarkReader.exportGeneratedCSS().then(css => {
    console.log(css);
});
```

### Returns
A string containing all the generated CSS that Dark Reader created to make the page dark.

### Use Cases
- Debug what CSS is being generated
- Save the CSS for later use
- Export to file
- Analyze color transformations

---

## 6. DarkReader.setFetchMethod()

**Set custom fetch function for CORS requests**

### Usage
```javascript
// Custom fetch function
function customFetch(url) {
    return fetch(url, {
        mode: 'cors',
        credentials: 'include'
    });
}

DarkReader.setFetchMethod(customFetch);
```

### Use Cases
- Custom CORS handling
- Add authentication headers
- Proxy requests
- Debug network requests

---

## Complete Swift Integration Examples

### Basic Toggle
```swift
func enableDarkMode() {
    webView.evaluateJavaScript("DarkReader.enable();")
}

func disableDarkMode() {
    webView.evaluateJavaScript("DarkReader.disable();")
}

func checkIfEnabled() {
    webView.evaluateJavaScript("DarkReader.isEnabled()") { result, error in
        if let enabled = result as? Bool {
            print("Dark mode is \(enabled ? "ON" : "OFF")")
        }
    }
}
```

### With Theme Options
```swift
func enableWithCustomTheme() {
    let script = """
    DarkReader.enable({
        brightness: 100,
        contrast: 90,
        mode: 1,
        tintColor: '#FF6B6B',
        tintStrength: 30
    });
    """
    webView.evaluateJavaScript(script)
}
```

### Auto Mode
```swift
func enableAutoMode() {
    let script = """
    DarkReader.auto({
        brightness: 100,
        contrast: 90,
        tintColor: '#4ECDC4',
        tintStrength: 20
    });
    """
    webView.evaluateJavaScript(script)
}

func disableAutoMode() {
    webView.evaluateJavaScript("DarkReader.auto(false);")
}
```

### Export CSS
```swift
func exportCSS() {
    let script = "DarkReader.exportGeneratedCSS()"
    webView.evaluateJavaScript(script) { result, error in
        if let css = result as? String {
            print("Generated CSS:")
            print(css)
            // Save to file, copy to clipboard, etc.
        }
    }
}
```

### Dynamic Theme Updates
```swift
func updateBrightness(_ value: Int) {
    let script = """
    DarkReader.enable({
        brightness: \(value),
        contrast: 90,
        mode: 1
    });
    """
    webView.evaluateJavaScript(script)
}

func updateTint(color: String, strength: Int) {
    let script = """
    DarkReader.enable({
        brightness: 100,
        contrast: 90,
        tintColor: '\(color)',
        tintStrength: \(strength)
    });
    """
    webView.evaluateJavaScript(script)
}
```

---

## Theme Property Reference

### brightness
- **Type:** `number`
- **Range:** 50-200
- **Default:** 100
- **Description:** Overall brightness adjustment
- **Examples:**
  - `50` = Very dark
  - `100` = Normal
  - `150` = Brighter
  - `200` = Very bright

### contrast
- **Type:** `number`
- **Range:** 50-200
- **Default:** 100
- **Description:** Color contrast adjustment
- **Examples:**
  - `50` = Low contrast (washed out)
  - `100` = Normal contrast
  - `150` = High contrast
  - `200` = Very high contrast

### sepia
- **Type:** `number`
- **Range:** 0-100
- **Default:** 0
- **Description:** Add sepia/brown tone
- **Examples:**
  - `0` = No sepia
  - `30` = Slight warm tone
  - `60` = Paper-like appearance
  - `100` = Full sepia

### grayscale
- **Type:** `number`
- **Range:** 0-100
- **Default:** 0
- **Description:** Convert to grayscale
- **Examples:**
  - `0` = Full color
  - `50` = Half grayscale
  - `100` = Full grayscale (black & white)

### mode
- **Type:** `0 | 1`
- **Values:**
  - `0` = **Filter Mode** (dimmed, preserves colors better)
  - `1` = **Dark Mode** (full dark theme, inverts colors)
- **Default:** 1

### tintColor
- **Type:** `string`
- **Default:** `''` (no tint)
- **Description:** Color to blend into the theme
- **Format:** Any CSS color
- **Examples:**
  - `'#FF6B6B'` = Red tint
  - `'#4ECDC4'` = Cyan tint
  - `'rgb(255, 140, 66)'` = Orange tint
  - `'hsl(280, 50%, 60%)'` = Purple tint

### tintStrength
- **Type:** `number`
- **Range:** 0-100
- **Default:** 0
- **Description:** How much to apply the tint
- **Examples:**
  - `0` = No tint
  - `15` = Subtle tint
  - `30` = Moderate tint
  - `50` = Strong tint
  - `80` = Very strong (usually too much)

### darkSchemeBackgroundColor
- **Type:** `string`
- **Default:** `'#181a1b'`
- **Description:** Background color for dark mode
- **Examples:**
  - `'#000000'` = Pure black
  - `'#181a1b'` = Default dark gray
  - `'#1a1a2e'` = Navy dark

### darkSchemeTextColor
- **Type:** `string`
- **Default:** `'#e8e6e3'`
- **Description:** Text color for dark mode
- **Examples:**
  - `'#ffffff'` = Pure white
  - `'#e8e6e3'` = Default off-white
  - `'#f0f0f0'` = Bright gray

### lightSchemeBackgroundColor
- **Type:** `string`
- **Default:** `'#dcdad7'`
- **Description:** Background color for filter mode (mode: 0)

### lightSchemeTextColor
- **Type:** `string`
- **Default:** `'#181a1b'`
- **Description:** Text color for filter mode (mode: 0)

### scrollbarColor
- **Type:** `string`
- **Default:** `''`
- **Options:**
  - `''` = Don't style scrollbar
  - `'auto'` = Auto-generate from theme
  - `'#FF0000'` = Custom color

### selectionColor
- **Type:** `string`
- **Default:** `'auto'`
- **Options:**
  - `'auto'` = Auto-generate selection color
  - `''` = Don't style selection
  - `'#0096FF'` = Custom color

### useFont
- **Type:** `boolean`
- **Default:** `false`
- **Description:** Use custom font

### fontFamily
- **Type:** `string`
- **Default:** System font
- **Examples:**
  - `'Arial'`
  - `'Helvetica Neue'`
  - `'Open Sans'`

### textStroke
- **Type:** `number`
- **Range:** 0-1
- **Default:** 0
- **Description:** Add text stroke (makes text bolder)
- **Examples:**
  - `0` = No stroke
  - `0.3` = Slight boldness
  - `0.5` = Moderate boldness
  - `1` = Very bold

### styleSystemControls
- **Type:** `boolean`
- **Default:** `true`
- **Description:** Apply dark mode to input/button/select elements

---

## Fixes Reference

### invert
- **Type:** `string[]`
- **Default:** `[]`
- **Description:** CSS selectors to invert (usually for logos/icons)
- **Example:**
```javascript
{
    invert: [
        '.logo',
        '#header-icon',
        'img[src*="logo"]',
        '.sprite-icon'
    ]
}
```

### css
- **Type:** `string`
- **Default:** `''`
- **Description:** Custom CSS to inject
- **Template:** Use `${color}` for theme-aware colors
- **Example:**
```javascript
{
    css: `
        .header {
            background-color: \${#000000} !important;
        }
        .button {
            color: \${#ffffff} !important;
        }
    `
}
```

### ignoreInlineStyle
- **Type:** `string[]`
- **Default:** `[]`
- **Description:** Don't process inline styles for these selectors
- **Use Case:** Color pickers, style editors
- **Example:**
```javascript
{
    ignoreInlineStyle: [
        '.color-picker',
        '.style-editor',
        '[contenteditable]'
    ]
}
```

### ignoreImageAnalysis
- **Type:** `string[]`
- **Default:** `[]`
- **Description:** Don't process background images for these selectors
- **Use Case:** Hero images, photos that shouldn't be darkened
- **Example:**
```javascript
{
    ignoreImageAnalysis: [
        '.hero-image',
        '.photo-gallery img',
        '.profile-picture'
    ]
}
```

### disableStyleSheetsProxy
- **Type:** `boolean`
- **Default:** `false`
- **Description:** Disable proxying of `document.styleSheets` API
- **Warning:** Can break some websites
- **Use Case:** If website uses styleSheets API and breaks

---

## Quick Reference Card

```javascript
// === ENABLE ===
DarkReader.enable()                    // Basic
DarkReader.enable({brightness: 110})   // With options
DarkReader.enable({...}, {...})        // With fixes

// === DISABLE ===
DarkReader.disable()                   // Turn off

// === AUTO ===
DarkReader.auto({...})                 // Follow system
DarkReader.auto(false)                 // Stop following

// === CHECK ===
DarkReader.isEnabled()                 // Returns boolean

// === EXPORT ===
await DarkReader.exportGeneratedCSS()  // Get CSS string

// === CUSTOM FETCH ===
DarkReader.setFetchMethod(fn)          // Custom fetch
```

---

## Common Presets

### Default Dark
```javascript
DarkReader.enable({
    brightness: 100,
    contrast: 100,
    mode: 1
});
```

### High Contrast
```javascript
DarkReader.enable({
    brightness: 110,
    contrast: 110,
    mode: 1
});
```

### Warm Reading Mode
```javascript
DarkReader.enable({
    brightness: 95,
    contrast: 85,
    sepia: 30,
    tintColor: '#D4A574',
    tintStrength: 35
});
```

### Cool Professional
```javascript
DarkReader.enable({
    brightness: 100,
    contrast: 95,
    tintColor: '#4ECDC4',
    tintStrength: 15
});
```

### Grayscale Focus
```javascript
DarkReader.enable({
    brightness: 100,
    contrast: 95,
    grayscale: 100,
    mode: 1
});
```

### Sunset Theme
```javascript
DarkReader.enable({
    brightness: 95,
    contrast: 90,
    sepia: 10,
    tintColor: '#FF8C42',
    tintStrength: 25
});
```

---

## Error Handling

```javascript
try {
    DarkReader.enable({
        brightness: 100,
        contrast: 90
    });
    console.log('Dark mode enabled');
} catch (error) {
    console.error('Failed to enable dark mode:', error);
}

// Check if DarkReader is loaded
if (typeof DarkReader !== 'undefined') {
    DarkReader.enable();
} else {
    console.error('DarkReader not loaded');
}
```

---

## Swift Helper Extension

```swift
extension WKWebView {
    
    func enableDarkReader(theme: DarkReaderTheme? = nil) {
        let themeJSON = theme?.toJSON() ?? "{}"
        evaluateJavaScript("DarkReader.enable(\(themeJSON));")
    }
    
    func disableDarkReader() {
        evaluateJavaScript("DarkReader.disable();")
    }
    
    func isDarkReaderEnabled(completion: @escaping (Bool) -> Void) {
        evaluateJavaScript("DarkReader.isEnabled();") { result, _ in
            completion((result as? Bool) ?? false)
        }
    }
    
    func exportDarkReaderCSS(completion: @escaping (String?) -> Void) {
        evaluateJavaScript("DarkReader.exportGeneratedCSS();") { result, _ in
            completion(result as? String)
        }
    }
}

// Usage
webView.enableDarkReader()
webView.disableDarkReader()
webView.isDarkReaderEnabled { enabled in
    print("Enabled: \(enabled)")
}
webView.exportDarkReaderCSS { css in
    print("CSS: \(css ?? "none")")
}
```

---

## That's Everything!

You now have **every single** Dark Reader API command with:
- ✅ Complete parameter documentation
- ✅ All default values
- ✅ Ranges and types
- ✅ Swift integration examples
- ✅ Common presets
- ✅ Error handling

**Total API Surface:** 6 functions, 20+ theme properties, 5 fix options
