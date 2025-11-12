import UIKit
import WebKit

// MARK: - Minimal Example for Nook Browser Dark Mode Integration

/// Minimal Dark Reader integration for Nook Browser
/// Just copy this file into your project and you're ready to go!
class NookBrowserViewController: UIViewController {
    
    // MARK: - Properties
    
    private var webView: WKWebView!
    private var isDarkModeEnabled = false
    private var currentTheme = DarkReaderTheme()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupUI()
        loadHomePage()
    }
    
    // MARK: - Setup
    
    private func setupWebView() {
        // 1. Load Dark Reader script from bundle
        guard let scriptPath = Bundle.main.path(forResource: "darkreader", ofType: "js"),
              let scriptSource = try? String(contentsOfFile: scriptPath) else {
            print("⚠️ Failed to load darkreader.js - make sure it's in your bundle!")
            return
        }
        
        // 2. Create user script to inject Dark Reader
        let userScript = WKUserScript(
            source: scriptSource,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false  // Apply to iframes too
        )
        
        // 3. Configure content controller
        let contentController = WKUserContentController()
        contentController.addUserScript(userScript)
        
        // 4. Create and configure WebView
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.navigationDelegate = self
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(webView)
        
        print("✅ Dark Reader loaded and ready!")
    }
    
    private func setupUI() {
        // Dark mode toggle button
        let moonIcon = UIImage(systemName: isDarkModeEnabled ? "moon.fill" : "moon")
        let toggleButton = UIBarButtonItem(
            image: moonIcon,
            style: .plain,
            target: self,
            action: #selector(toggleDarkMode)
        )
        
        // Settings button
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "slider.horizontal.3"),
            style: .plain,
            target: self,
            action: #selector(showSettings)
        )
        
        navigationItem.rightBarButtonItems = [toggleButton, settingsButton]
    }
    
    private func loadHomePage() {
        if let url = URL(string: "https://www.example.com") {
            webView.load(URLRequest(url: url))
        }
    }
    
    // MARK: - Dark Mode Control
    
    @objc private func toggleDarkMode() {
        isDarkModeEnabled.toggle()
        
        if isDarkModeEnabled {
            enableDarkMode()
        } else {
            disableDarkMode()
        }
        
        // Update button icon
        let moonIcon = UIImage(systemName: isDarkModeEnabled ? "moon.fill" : "moon")
        navigationItem.rightBarButtonItems?.first?.image = moonIcon
    }
    
    private func enableDarkMode() {
        let themeJSON = currentTheme.toJSON()
        let script = """
        if (typeof DarkReader !== 'undefined') {
            DarkReader.enable(\(themeJSON));
            console.log('✅ Dark mode enabled');
        } else {
            console.error('❌ DarkReader not found');
        }
        """
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("❌ Error enabling dark mode: \(error)")
            } else {
                print("✅ Dark mode enabled successfully")
            }
        }
    }
    
    private func disableDarkMode() {
        let script = """
        if (typeof DarkReader !== 'undefined') {
            DarkReader.disable();
            console.log('✅ Dark mode disabled');
        }
        """
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("❌ Error disabling dark mode: \(error)")
            } else {
                print("✅ Dark mode disabled successfully")
            }
        }
    }
    
    private func applyTheme() {
        if isDarkModeEnabled {
            enableDarkMode()
        }
    }
    
    @objc private func showSettings() {
        let alert = UIAlertController(
            title: "Dark Mode Settings",
            message: "Quick preset selection",
            preferredStyle: .actionSheet
        )
        
        // Preset themes
        let presets: [(name: String, theme: DarkReaderTheme)] = [
            ("Default Dark", DarkReaderTheme()),
            ("Warm Dark", DarkReaderTheme(tintColor: "#FF8C42", tintStrength: 20, sepia: 10)),
            ("Cool Dark", DarkReaderTheme(tintColor: "#4ECDC4", tintStrength: 15)),
            ("High Contrast", DarkReaderTheme(brightness: 110, contrast: 110)),
            ("Grayscale", DarkReaderTheme(grayscale: 100)),
            ("Paper-like", DarkReaderTheme(sepia: 60, tintColor: "#D4A574", tintStrength: 25))
        ]
        
        for (name, theme) in presets {
            alert.addAction(UIAlertAction(title: name, style: .default) { [weak self] _ in
                self?.currentTheme = theme
                self?.applyTheme()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.last
        }
        
        present(alert, animated: true)
    }
}

// MARK: - WKNavigationDelegate

extension NookBrowserViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("📄 Page loaded, reapplying dark mode...")
        // Reapply theme after navigation
        applyTheme()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ Navigation failed: \(error)")
    }
}

// MARK: - Dark Reader Theme

/// Theme configuration for Dark Reader
struct DarkReaderTheme {
    var brightness: Int = 100        // 50-200
    var contrast: Int = 90            // 50-200
    var sepia: Int = 0                // 0-100
    var grayscale: Int = 0            // 0-100
    var mode: Int = 1                 // 0 = filter, 1 = dark
    
    // Custom tinting
    var tintColor: String? = nil      // Hex color, e.g., "#FF6B6B"
    var tintStrength: Int = 0         // 0-100
    
    // Color poles for dark mode
    var darkSchemeBackgroundColor: String = "#181a1b"
    var darkSchemeTextColor: String = "#e8e6e3"
    var lightSchemeBackgroundColor: String = "#dcdad7"
    var lightSchemeTextColor: String = "#181a1b"
    
    /// Convert theme to JSON string for JavaScript
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
        
        // Add tint properties if set
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

// MARK: - Advanced Example with Full Features

/// Full-featured Dark Reader manager with persistence and per-site settings
class AdvancedDarkReaderManager {
    
    // MARK: - Properties
    
    private weak var webView: WKWebView?
    private var globalTheme = DarkReaderTheme()
    private var siteThemes: [String: DarkReaderTheme] = [:]
    private var isDarkModeEnabled = false
    
    // MARK: - Initialization
    
    init(webView: WKWebView) {
        self.webView = webView
        loadSettings()
    }
    
    // MARK: - Public API
    
    func enable(with theme: DarkReaderTheme? = nil) {
        isDarkModeEnabled = true
        if let theme = theme {
            globalTheme = theme
        }
        applyTheme(globalTheme)
        saveSettings()
    }
    
    func disable() {
        isDarkModeEnabled = false
        let script = "DarkReader.disable();"
        webView?.evaluateJavaScript(script)
        saveSettings()
    }
    
    func updateTheme(_ updater: (inout DarkReaderTheme) -> Void) {
        updater(&globalTheme)
        if isDarkModeEnabled {
            applyTheme(globalTheme)
        }
        saveSettings()
    }
    
    func setSiteTheme(_ theme: DarkReaderTheme, for url: URL) {
        guard let host = url.host else { return }
        siteThemes[host] = theme
        if isDarkModeEnabled {
            applyTheme(theme)
        }
        saveSettings()
    }
    
    func getSiteTheme(for url: URL) -> DarkReaderTheme? {
        guard let host = url.host else { return nil }
        return siteThemes[host]
    }
    
    func applyCurrentSiteTheme(for url: URL) {
        guard isDarkModeEnabled else { return }
        let theme = getSiteTheme(for: url) ?? globalTheme
        applyTheme(theme)
    }
    
    // MARK: - Private Methods
    
    private func applyTheme(_ theme: DarkReaderTheme) {
        let themeJSON = theme.toJSON()
        let script = """
        if (typeof DarkReader !== 'undefined') {
            DarkReader.enable(\(themeJSON));
        }
        """
        webView?.evaluateJavaScript(script)
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(isDarkModeEnabled, forKey: "DarkModeEnabled")
        
        if let themeData = try? JSONEncoder().encode(globalTheme) {
            UserDefaults.standard.set(themeData, forKey: "DarkReaderGlobalTheme")
        }
        
        if let sitesData = try? JSONEncoder().encode(siteThemes) {
            UserDefaults.standard.set(sitesData, forKey: "DarkReaderSiteThemes")
        }
    }
    
    private func loadSettings() {
        isDarkModeEnabled = UserDefaults.standard.bool(forKey: "DarkModeEnabled")
        
        if let themeData = UserDefaults.standard.data(forKey: "DarkReaderGlobalTheme"),
           let theme = try? JSONDecoder().decode(DarkReaderTheme.self, from: themeData) {
            globalTheme = theme
        }
        
        if let sitesData = UserDefaults.standard.data(forKey: "DarkReaderSiteThemes"),
           let sites = try? JSONDecoder().decode([String: DarkReaderTheme].self, from: sitesData) {
            siteThemes = sites
        }
    }
}

// MARK: - Codable Support

extension DarkReaderTheme: Codable {
    enum CodingKeys: String, CodingKey {
        case brightness, contrast, sepia, grayscale, mode
        case tintColor, tintStrength
        case darkSchemeBackgroundColor, darkSchemeTextColor
        case lightSchemeBackgroundColor, lightSchemeTextColor
    }
}

// MARK: - Usage Example

/*
 
 // Basic Usage:
 let browserVC = NookBrowserViewController()
 navigationController?.pushViewController(browserVC, animated: true)
 
 // That's it! Dark mode is now available with the moon button.
 
 // Advanced Usage:
 let webView = WKWebView()
 let darkReader = AdvancedDarkReaderManager(webView: webView)
 
 // Enable with custom theme
 var customTheme = DarkReaderTheme()
 customTheme.tintColor = "#FF6B6B"
 customTheme.tintStrength = 30
 darkReader.enable(with: customTheme)
 
 // Set per-site theme
 if let url = URL(string: "https://github.com") {
     var githubTheme = DarkReaderTheme()
     githubTheme.contrast = 95
     darkReader.setSiteTheme(githubTheme, for: url)
 }
 
 // Update theme dynamically
 darkReader.updateTheme { theme in
     theme.brightness = 110
     theme.contrast = 95
 }
 
 */
