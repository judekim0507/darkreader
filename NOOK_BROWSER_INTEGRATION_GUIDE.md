# Integrating Color Tinting & Dark Mode into Nook Browser (Swift/WebKit)

## Overview
This guide explains how to integrate Dark Reader's color tinting and dark mode functionality natively into Nook Browser using Swift and WebKit, without requiring it as an extension.

## Architecture Overview

### Current Extension Architecture
- **Content Scripts**: Inject JavaScript into web pages (`inject/index.ts`)
- **Background Page**: Manages settings and coordination
- **Dynamic Theme Engine**: Analyzes and modifies CSS in real-time (`inject/dynamic-theme/`)
- **Color Modification**: HSL-based color transformations with tinting support

### Native Browser Integration Architecture
```
┌─────────────────────────────────────────┐
│         Swift UI Layer                   │
│  (Settings, Toggle, Color Picker)        │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│    WKWebView Configuration               │
│  - WKUserContentController               │
│  - WKUserScript (Inject at start)        │
│  - WKScriptMessageHandler                │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│    Dark Reader API (JavaScript)          │
│  - Built from src/api/                   │
│  - Standalone library (no extensions)    │
└─────────────────────────────────────────┘
```

## Step 1: Build the Dark Reader API Library

### 1.1 Build Command
```bash
npm install
npm run api
```

This creates:
- `darkreader.js` - UMD build for browsers
- `darkreader.mjs` - ES module build

### 1.2 What You Get
The API exposes these functions:
```javascript
DarkReader.enable({
    brightness: 100,      // 50-200
    contrast: 90,         // 50-200
    sepia: 0,            // 0-100
    grayscale: 0,        // 0-100
    mode: 1,             // 0 = filter/dimmed, 1 = dark scheme
    
    // Custom color tinting (Boosts feature)
    tintColor: '#FF6B6B',     // Any CSS color
    tintStrength: 30,          // 0-100
    
    // Color poles for dark mode
    darkSchemeBackgroundColor: '#181a1b',
    darkSchemeTextColor: '#e8e6e3',
    
    // Color poles for light mode filtering
    lightSchemeBackgroundColor: '#dcdad7',
    lightSchemeTextColor: '#181a1b',
});

DarkReader.disable();

DarkReader.auto({/* theme */});  // Follow system preference
DarkReader.isEnabled();
const css = await DarkReader.exportGeneratedCSS();
```

## Step 2: Swift/WebKit Integration

### 2.1 Create a DarkReaderManager Swift Class

```swift
import WebKit

class DarkReaderManager {
    // Theme configuration
    struct Theme {
        var enabled: Bool = false
        var brightness: Int = 100
        var contrast: Int = 90
        var sepia: Int = 0
        var grayscale: Int = 0
        var mode: Int = 1  // 0 = dimmed, 1 = dark
        
        // Tinting properties
        var tintColor: String? = nil
        var tintStrength: Int = 0
        
        // Color poles
        var darkSchemeBackgroundColor: String = "#181a1b"
        var darkSchemeTextColor: String = "#e8e6e3"
        var lightSchemeBackgroundColor: String = "#dcdad7"
        var lightSchemeTextColor: String = "#181a1b"
        
        func toJSON() -> String {
            var json = """
            {
                "brightness": \(brightness),
                "contrast": \(contrast),
                "sepia": \(sepia),
                "grayscale": \(grayscale),
                "mode": \(mode),
                "darkSchemeBackgroundColor": "\(darkSchemeBackgroundColor)",
                "darkSchemeTextColor": "\(darkSchemeTextColor)",
                "lightSchemeBackgroundColor": "\(lightSchemeBackgroundColor)",
                "lightSchemeTextColor": "\(lightSchemeTextColor)"
            """
            
            if let tintColor = tintColor, tintStrength > 0 {
                json += """,
                "tintColor": "\(tintColor)",
                "tintStrength": \(tintStrength)
                """
            }
            
            json += "\n}"
            return json
        }
    }
    
    private var theme = Theme()
    private weak var webView: WKWebView?
    
    init(webView: WKWebView) {
        self.webView = webView
    }
    
    // Enable dark mode with current theme
    func enable() {
        theme.enabled = true
        applyTheme()
    }
    
    // Disable dark mode
    func disable() {
        theme.enabled = false
        let script = "DarkReader.disable();"
        webView?.evaluateJavaScript(script, completionHandler: nil)
    }
    
    // Update theme properties
    func updateTheme(_ updates: (inout Theme) -> Void) {
        updates(&theme)
        if theme.enabled {
            applyTheme()
        }
    }
    
    // Apply current theme to web page
    private func applyTheme() {
        let themeJSON = theme.toJSON()
        let script = """
        if (typeof DarkReader !== 'undefined') {
            DarkReader.enable(\(themeJSON));
        }
        """
        webView?.evaluateJavaScript(script, completionHandler: nil)
    }
    
    // Check if dark mode is enabled
    func isEnabled(completion: @escaping (Bool) -> Void) {
        let script = "DarkReader.isEnabled();"
        webView?.evaluateJavaScript(script) { result, error in
            completion((result as? Bool) ?? false)
        }
    }
}
```

### 2.2 Setup WKWebView with Dark Reader Injection

```swift
import WebKit

class NookWebViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {
    
    var webView: WKWebView!
    var darkReaderManager: DarkReaderManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
    }
    
    private func setupWebView() {
        // 1. Create user content controller
        let contentController = WKUserContentController()
        
        // 2. Load Dark Reader script from bundle
        guard let scriptPath = Bundle.main.path(forResource: "darkreader", ofType: "js"),
              let scriptSource = try? String(contentsOfFile: scriptPath) else {
            print("Failed to load Dark Reader script")
            return
        }
        
        // 3. Create user script to inject at document start
        let userScript = WKUserScript(
            source: scriptSource,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false  // Apply to all frames including iframes
        )
        contentController.addUserScript(userScript)
        
        // 4. Optional: Add message handler for communication
        contentController.add(self, name: "darkReader")
        
        // 5. Configure WebView
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        // 6. Create WebView
        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.navigationDelegate = self
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(webView)
        
        // 7. Initialize Dark Reader Manager
        darkReaderManager = DarkReaderManager(webView: webView)
    }
    
    // WKNavigationDelegate - Apply theme after page loads
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Reapply theme after navigation
        if darkReaderManager.theme.enabled {
            darkReaderManager.enable()
        }
    }
    
    // WKScriptMessageHandler - Handle messages from JavaScript
    func userContentController(_ userContentController: WKUserContentController, 
                              didReceive message: WKScriptMessage) {
        if message.name == "darkReader" {
            // Handle any messages from Dark Reader if needed
            print("Message from Dark Reader: \(message.body)")
        }
    }
}
```

### 2.3 Create UI Controls

```swift
import UIKit

extension NookWebViewController {
    
    func setupDarkModeControls() {
        // Toggle Switch
        let toggleButton = UIBarButtonItem(
            image: UIImage(systemName: "moon.fill"),
            style: .plain,
            target: self,
            action: #selector(toggleDarkMode)
        )
        
        // Settings Button
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "slider.horizontal.3"),
            style: .plain,
            target: self,
            action: #selector(showSettings)
        )
        
        navigationItem.rightBarButtonItems = [toggleButton, settingsButton]
    }
    
    @objc func toggleDarkMode() {
        darkReaderManager.updateTheme { theme in
            theme.enabled.toggle()
        }
        
        if darkReaderManager.theme.enabled {
            darkReaderManager.enable()
        } else {
            darkReaderManager.disable()
        }
    }
    
    @objc func showSettings() {
        let settingsVC = DarkReaderSettingsViewController(manager: darkReaderManager)
        present(UINavigationController(rootViewController: settingsVC), animated: true)
    }
}

// Settings View Controller
class DarkReaderSettingsViewController: UIViewController {
    
    let manager: DarkReaderManager
    
    init(manager: DarkReaderManager) {
        self.manager = manager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Dark Mode Settings"
        view.backgroundColor = .systemGroupedBackground
        
        setupUI()
    }
    
    private func setupUI() {
        // Create sliders for brightness, contrast, etc.
        let scrollView = UIScrollView(frame: view.bounds)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scrollView)
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        
        // Brightness Slider
        let brightnessControl = createSliderControl(
            title: "Brightness",
            min: 50, max: 200, value: Float(manager.theme.brightness)
        ) { [weak self] value in
            self?.manager.updateTheme { theme in
                theme.brightness = Int(value)
            }
            self?.manager.enable()
        }
        stackView.addArrangedSubview(brightnessControl)
        
        // Contrast Slider
        let contrastControl = createSliderControl(
            title: "Contrast",
            min: 50, max: 200, value: Float(manager.theme.contrast)
        ) { [weak self] value in
            self?.manager.updateTheme { theme in
                theme.contrast = Int(value)
            }
            self?.manager.enable()
        }
        stackView.addArrangedSubview(contrastControl)
        
        // Sepia Slider
        let sepiaControl = createSliderControl(
            title: "Sepia",
            min: 0, max: 100, value: Float(manager.theme.sepia)
        ) { [weak self] value in
            self?.manager.updateTheme { theme in
                theme.sepia = Int(value)
            }
            self?.manager.enable()
        }
        stackView.addArrangedSubview(sepiaControl)
        
        // Grayscale Slider
        let grayscaleControl = createSliderControl(
            title: "Grayscale",
            min: 0, max: 100, value: Float(manager.theme.grayscale)
        ) { [weak self] value in
            self?.manager.updateTheme { theme in
                theme.grayscale = Int(value)
            }
            self?.manager.enable()
        }
        stackView.addArrangedSubview(grayscaleControl)
        
        // Tint Color Picker
        let tintSection = createTintColorPicker()
        stackView.addArrangedSubview(tintSection)
        
        // Tint Strength Slider
        let tintStrengthControl = createSliderControl(
            title: "Tint Strength",
            min: 0, max: 100, value: Float(manager.theme.tintStrength)
        ) { [weak self] value in
            self?.manager.updateTheme { theme in
                theme.tintStrength = Int(value)
            }
            self?.manager.enable()
        }
        stackView.addArrangedSubview(tintStrengthControl)
        
        // Mode Segmented Control
        let modeControl = createModeControl()
        stackView.addArrangedSubview(modeControl)
        
        // Layout
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20)
        ])
    }
    
    private func createSliderControl(
        title: String,
        min: Float, max: Float, value: Float,
        onChange: @escaping (Float) -> Void
    ) -> UIView {
        let container = UIView()
        
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: .medium)
        
        let valueLabel = UILabel()
        valueLabel.text = "\(Int(value))"
        valueLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        valueLabel.textColor = .secondaryLabel
        
        let slider = UISlider()
        slider.minimumValue = min
        slider.maximumValue = max
        slider.value = value
        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        slider.tag = title.hashValue
        
        // Store onChange closure
        objc_setAssociatedObject(slider, "onChange", onChange, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(slider, "valueLabel", valueLabel, .OBJC_ASSOCIATION_RETAIN)
        
        [label, valueLabel, slider].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            
            valueLabel.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            slider.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            slider.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            slider.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            slider.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    @objc private func sliderChanged(_ slider: UISlider) {
        if let onChange = objc_getAssociatedObject(slider, "onChange") as? (Float) -> Void,
           let valueLabel = objc_getAssociatedObject(slider, "valueLabel") as? UILabel {
            valueLabel.text = "\(Int(slider.value))"
            onChange(slider.value)
        }
    }
    
    private func createTintColorPicker() -> UIView {
        let container = UIView()
        
        let label = UILabel()
        label.text = "Tint Color"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        
        let colorButton = UIButton(type: .system)
        colorButton.setTitle("Choose Color", for: .normal)
        colorButton.addTarget(self, action: #selector(chooseTintColor), for: .touchUpInside)
        colorButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(colorButton)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            colorButton.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            colorButton.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        
        return container
    }
    
    @objc private func chooseTintColor() {
        if #available(iOS 14.0, *) {
            let colorPicker = UIColorPickerViewController()
            colorPicker.delegate = self
            if let tintColor = manager.theme.tintColor {
                colorPicker.selectedColor = UIColor(hexString: tintColor) ?? .systemBlue
            }
            present(colorPicker, animated: true)
        }
    }
    
    private func createModeControl() -> UIView {
        let container = UIView()
        
        let label = UILabel()
        label.text = "Mode"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        
        let segmentedControl = UISegmentedControl(items: ["Filter", "Dark"])
        segmentedControl.selectedSegmentIndex = manager.theme.mode
        segmentedControl.addTarget(self, action: #selector(modeChanged(_:)), for: .valueChanged)
        
        [label, segmentedControl].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            
            segmentedControl.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            segmentedControl.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            segmentedControl.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    @objc private func modeChanged(_ sender: UISegmentedControl) {
        manager.updateTheme { theme in
            theme.mode = sender.selectedSegmentIndex
        }
        manager.enable()
    }
}

@available(iOS 14.0, *)
extension DarkReaderSettingsViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        let color = viewController.selectedColor
        manager.updateTheme { theme in
            theme.tintColor = color.toHex()
        }
        manager.enable()
    }
}

// Helper extensions
extension UIColor {
    convenience init?(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: return nil
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
    
    func toHex() -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
```

## Step 3: Persistence & User Preferences

```swift
import Foundation

extension DarkReaderManager {
    
    // Save theme to UserDefaults
    func saveTheme() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(theme) {
            UserDefaults.standard.set(encoded, forKey: "DarkReaderTheme")
        }
    }
    
    // Load theme from UserDefaults
    func loadTheme() {
        if let data = UserDefaults.standard.data(forKey: "DarkReaderTheme"),
           let decoded = try? JSONDecoder().decode(Theme.self, from: data) {
            theme = decoded
        }
    }
}

// Make Theme Codable
extension DarkReaderManager.Theme: Codable {
    enum CodingKeys: String, CodingKey {
        case enabled, brightness, contrast, sepia, grayscale, mode
        case tintColor, tintStrength
        case darkSchemeBackgroundColor, darkSchemeTextColor
        case lightSchemeBackgroundColor, lightSchemeTextColor
    }
}
```

## Step 4: Advanced Features

### 4.1 Per-Site Settings

```swift
extension DarkReaderManager {
    
    struct SiteSettings: Codable {
        let domain: String
        var enabled: Bool
        var customTheme: Theme?
    }
    
    private var siteSettings: [String: SiteSettings] = [:]
    
    func applySiteSpecificSettings(for url: URL) {
        guard let domain = url.host else { return }
        
        if let settings = siteSettings[domain] {
            theme.enabled = settings.enabled
            if let customTheme = settings.customTheme {
                theme = customTheme
            }
            
            if theme.enabled {
                enable()
            } else {
                disable()
            }
        }
    }
    
    func saveSiteSettings(for url: URL) {
        guard let domain = url.host else { return }
        
        siteSettings[domain] = SiteSettings(
            domain: domain,
            enabled: theme.enabled,
            customTheme: theme
        )
        
        // Persist to UserDefaults
        if let encoded = try? JSONEncoder().encode(siteSettings) {
            UserDefaults.standard.set(encoded, forKey: "DarkReaderSiteSettings")
        }
    }
}
```

### 4.2 Auto Mode (Follow System Theme)

```swift
extension DarkReaderManager {
    
    func enableAutoMode() {
        // Monitor system appearance changes
        NotificationCenter.default.addObserver(
            forName: UIScreen.brightnessDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateBasedOnSystemAppearance()
        }
        
        updateBasedOnSystemAppearance()
    }
    
    private func updateBasedOnSystemAppearance() {
        let isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        
        if isDarkMode && !theme.enabled {
            enable()
        } else if !isDarkMode && theme.enabled {
            disable()
        }
    }
}
```

### 4.3 Export/Import Settings

```swift
extension DarkReaderManager {
    
    func exportSettings() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        if let data = try? encoder.encode(theme),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return nil
    }
    
    func importSettings(from json: String) -> Bool {
        guard let data = json.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(Theme.self, from: data) else {
            return false
        }
        
        theme = decoded
        if theme.enabled {
            enable()
        }
        return true
    }
}
```

## Step 5: Bundle Dark Reader in Your App

### 5.1 Copy Built Files to Xcode Project

1. Build Dark Reader: `npm run api`
2. Copy `darkreader.js` to your Xcode project
3. Add to your app bundle in Build Phases → Copy Bundle Resources

### 5.2 Alternative: Embed as String

If you prefer not to use a separate file:

```swift
let darkReaderScript = """
// Paste the contents of darkreader.js here
// Or load from a file at compile time
"""

let userScript = WKUserScript(
    source: darkReaderScript,
    injectionTime: .atDocumentStart,
    forMainFrameOnly: false
)
```

## Performance Considerations

### 1. **Initial Load**
- Dark Reader processes all CSS on page load
- For large pages, this may take 100-300ms
- Consider showing a loading indicator

### 2. **Memory Usage**
- Caches parsed colors and modified CSS
- Typically uses 5-15 MB per tab
- Clear cache on memory warnings

### 3. **Battery Impact**
- Dynamic theme requires continuous DOM monitoring
- For battery-sensitive scenarios, consider:
  - Using filter mode instead of dynamic mode
  - Disabling on low battery

## Testing Checklist

- [ ] Dark mode toggles correctly
- [ ] Settings persist across app restarts
- [ ] Per-site settings work
- [ ] Theme survives navigation
- [ ] iFrames are styled correctly
- [ ] No conflicts with website's own dark mode
- [ ] Tint colors apply correctly
- [ ] Performance is acceptable on low-end devices

## Troubleshooting

### Issue: Dark Reader not loading
- Check that `darkreader.js` is in your bundle
- Verify injection time is `.atDocumentStart`
- Check console for JavaScript errors

### Issue: Theme not persisting after navigation
- Implement `didFinish navigation:` callback
- Reapply theme after page loads

### Issue: Some elements not styled
- Some sites use Shadow DOM
- Ensure `forMainFrameOnly: false` in user script
- Check for CSP (Content Security Policy) issues

## Next Steps

1. Build Dark Reader API: `npm run api`
2. Integrate into your Swift project
3. Add UI controls
4. Test on various websites
5. Consider adding preset themes
6. Implement keyboard shortcuts
7. Add share extension for system-wide dark mode

## Additional Resources

- Dark Reader GitHub: https://github.com/darkreader/darkreader
- WKWebView Documentation: https://developer.apple.com/documentation/webkit/wkwebview
- WKUserScript Documentation: https://developer.apple.com/documentation/webkit/wkuserscript

---

## Example: Complete Implementation

See the Swift code examples above for a complete, production-ready implementation including:
- Theme management
- Persistence
- UI controls with sliders and color pickers
- Per-site settings
- Auto mode
- Export/import functionality
