# Dark Reader API - Quick Command List

## 🎯 All Commands (6 Total)

```javascript
DarkReader.enable()             // Enable dark mode
DarkReader.disable()            // Disable dark mode  
DarkReader.auto()               // Follow system preference
DarkReader.isEnabled()          // Check if enabled (returns boolean)
DarkReader.exportGeneratedCSS() // Get CSS string (async)
DarkReader.setFetchMethod()     // Custom fetch function
```

---

## 📋 All Theme Properties (20 Total)

```javascript
{
    // Core adjustments (4)
    brightness: 100,              // 50-200
    contrast: 100,                // 50-200
    sepia: 0,                     // 0-100
    grayscale: 0,                 // 0-100
    
    // Mode (1)
    mode: 1,                      // 0 = Filter, 1 = Dark
    
    // Color tinting (2)
    tintColor: '',                // CSS color or ''
    tintStrength: 0,              // 0-100
    
    // Dark mode colors (2)
    darkSchemeBackgroundColor: '#181a1b',
    darkSchemeTextColor: '#e8e6e3',
    
    // Light mode colors (2)
    lightSchemeBackgroundColor: '#dcdad7',
    lightSchemeTextColor: '#181a1b',
    
    // UI elements (2)
    scrollbarColor: '',           // '', 'auto', or color
    selectionColor: 'auto',       // '', 'auto', or color
    
    // Font (3)
    useFont: false,               // Boolean
    fontFamily: 'Arial',          // Font name
    textStroke: 0,                // 0-1
    
    // Advanced (1)
    styleSystemControls: true     // Boolean
}
```

---

## 🔧 All Fix Properties (5 Total)

```javascript
{
    invert: [],                   // CSS selectors to invert
    css: '',                      // Custom CSS
    ignoreInlineStyle: [],        // Selectors to skip inline styles
    ignoreImageAnalysis: [],      // Selectors to skip image processing
    disableStyleSheetsProxy: false // Boolean
}
```

---

## 💡 Common Usage Patterns

### Enable with defaults
```javascript
DarkReader.enable();
```

### Enable with options
```javascript
DarkReader.enable({brightness: 110, contrast: 95});
```

### Enable with tint
```javascript
DarkReader.enable({tintColor: '#FF6B6B', tintStrength: 30});
```

### Enable with fixes
```javascript
DarkReader.enable(
    {brightness: 100},
    {invert: ['.logo']}
);
```

### Auto mode
```javascript
DarkReader.auto({brightness: 100});  // Enable
DarkReader.auto(false);               // Disable
```

### Check status
```javascript
const enabled = DarkReader.isEnabled();
```

### Export CSS
```javascript
const css = await DarkReader.exportGeneratedCSS();
```

---

## 🎨 Preset Examples

```javascript
// Default
DarkReader.enable();

// High Contrast
DarkReader.enable({brightness: 110, contrast: 110});

// Warm
DarkReader.enable({sepia: 30, tintColor: '#FF8C42', tintStrength: 25});

// Cool
DarkReader.enable({tintColor: '#4ECDC4', tintStrength: 20});

// Grayscale
DarkReader.enable({grayscale: 100});
```

---

## 📱 Swift Examples

```swift
// Enable
webView.evaluateJavaScript("DarkReader.enable();")

// Disable
webView.evaluateJavaScript("DarkReader.disable();")

// Check
webView.evaluateJavaScript("DarkReader.isEnabled()") { result, _ in
    let enabled = result as? Bool ?? false
}

// With options
webView.evaluateJavaScript("""
    DarkReader.enable({
        brightness: 110,
        tintColor: '#FF6B6B',
        tintStrength: 30
    });
""")
```

---

## 🔢 Value Ranges Summary

| Property | Min | Max | Default | Type |
|----------|-----|-----|---------|------|
| brightness | 50 | 200 | 100 | number |
| contrast | 50 | 200 | 100 | number |
| sepia | 0 | 100 | 0 | number |
| grayscale | 0 | 100 | 0 | number |
| tintStrength | 0 | 100 | 0 | number |
| textStroke | 0 | 1 | 0 | number |
| mode | 0 | 1 | 1 | 0 or 1 |
| tintColor | - | - | '' | string |
| useFont | - | - | false | boolean |
| styleSystemControls | - | - | true | boolean |

---

## ⚡ Performance Tips

1. **Reuse theme objects** - Don't create new objects every time
2. **Batch updates** - Update multiple properties at once
3. **Cache CSS** - Use `exportGeneratedCSS()` sparingly
4. **Auto mode** - Better than manual toggling
5. **Minimize fixes** - Only use when necessary

---

## 🎓 Learning Path

1. **Start:** `DarkReader.enable()` and `DarkReader.disable()`
2. **Next:** Add brightness/contrast sliders
3. **Then:** Try color tinting
4. **Advanced:** Use fixes for specific sites
5. **Pro:** Implement auto mode and per-site settings

---

## 📖 Full Documentation

See `DARKREADER_API_REFERENCE.md` for complete details on every parameter, example, and use case.
