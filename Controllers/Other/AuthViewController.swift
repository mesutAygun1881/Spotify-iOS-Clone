//
//  AuthViewController.swift
//  Spotify
//
//  Created by Mesut Aygun on 2/14/21.
//

import UIKit
import WebKit
import SafariServices

class AuthViewController: UIViewController, WKNavigationDelegate, SFSafariViewControllerDelegate {

    private let webView: WKWebView = {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = prefs
        // UserAgent for better compatibility with OAuth
        config.applicationNameForUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        let webView = WKWebView(frame: .zero,
                                configuration: config)
        return webView
    }()

    public var completionHandler: ((Bool) -> Void)?
    
    private var safariVC: SFSafariViewController?
    
    // Background image view
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(named: "albums_background")
        return imageView
    }()

    // Overlay to darken the background
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0.7
        return view
    }()

    // Spotify logo
    private let logoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "logo"))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    // Title label
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .white
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.text = "Sign In"
        return label
    }()
    
    // Description label
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.text = "Sign in to access millions of songs, playlists, and podcasts."
        return label
    }()
    
    // Continue with web button
    private let webSignInButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemGreen
        button.setTitle("Continue with Web", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        return button
    }()
    
    // Manual code entry button
    private let manualCodeButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        button.setTitle("Enter Code Manually", for: .normal)
        button.setTitleColor(.lightGray, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sign In"
        view.backgroundColor = .systemBackground
        
        setupUI()
        
        webView.navigationDelegate = self
        view.addSubview(webView)
        webView.isHidden = true // Initially hidden
        
        webSignInButton.addTarget(self, action: #selector(didTapWebSignIn), for: .touchUpInside)
        manualCodeButton.addTarget(self, action: #selector(didTapManualCodeEntry), for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Set frames for the UI elements
        imageView.frame = view.bounds
        overlayView.frame = view.bounds
        webView.frame = view.bounds
        
        // Position logo at the center top area
        logoImageView.frame = CGRect(
            x: (view.width-120)/2,
            y: view.safeAreaInsets.top + 60,
            width: 120,
            height: 120
        )
        
        // Position title label below logo
        titleLabel.frame = CGRect(
            x: 30,
            y: logoImageView.bottom + 30,
            width: view.width-60,
            height: 40
        )
        
        // Position description label below title
        descriptionLabel.frame = CGRect(
            x: 30,
            y: titleLabel.bottom + 10,
            width: view.width-60,
            height: 50
        )
        
        // Position buttons at the bottom
        webSignInButton.frame = CGRect(
            x: 20,
            y: view.height-130-view.safeAreaInsets.bottom,
            width: view.width-40,
            height: 50
        )
        
        manualCodeButton.frame = CGRect(
            x: 20,
            y: webSignInButton.bottom + 20,
            width: view.width-40,
            height: 30
        )
    }
    
    private func setupUI() {
        // Add UI elements to the view
        view.addSubview(imageView)
        view.addSubview(overlayView)
        view.addSubview(logoImageView)
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(webSignInButton)
        view.addSubview(manualCodeButton)
    }
    
    @objc private func didTapWebSignIn() {
        // Show the webview for direct sign in
        webView.isHidden = false
        
        guard let url = AuthManager.shared.signInURL else {
            return
        }
        
        // Inject JavaScript to handle redirection
        let userScript = WKUserScript(
            source: """
            // Script to monitor URL changes
            var lastUrl = window.location.href;
            
            // Check URL every 500ms
            var checkInterval = setInterval(function() {
                if (window.location.href !== lastUrl) {
                    lastUrl = window.location.href;
                    
                    // If redirected to iosacademy.io with code
                    if (lastUrl.indexOf('iosacademy.io') !== -1 && lastUrl.indexOf('code=') !== -1) {
                        // Copy URL automatically
                        navigator.clipboard.writeText(lastUrl).then(function() {
                            console.log('URL copied: ' + lastUrl);
                            
                            // Show success message to user
                            var infoDiv = document.createElement('div');
                            infoDiv.style.position = 'fixed';
                            infoDiv.style.top = '0';
                            infoDiv.style.left = '0';
                            infoDiv.style.width = '100%';
                            infoDiv.style.padding = '20px';
                            infoDiv.style.backgroundColor = '#4CAF50';
                            infoDiv.style.color = 'white';
                            infoDiv.style.textAlign = 'center';
                            infoDiv.style.fontWeight = 'bold';
                            infoDiv.style.zIndex = '9999';
                            infoDiv.innerHTML = 'URL Copied! You can now return to the app.';
                            document.body.appendChild(infoDiv);
                            
                            // Clear interval
                            clearInterval(checkInterval);
                        });
                    }
                }
            }, 500);
            """, 
            injectionTime: .atDocumentEnd, 
            forMainFrameOnly: true
        )
        
        webView.configuration.userContentController.addUserScript(userScript)
        
        // Show instructions to user
        let alert = UIAlertController(
            title: "Sign In Instructions",
            message: "Sign in with your Spotify account. After completion, you'll be redirected and the URL will be automatically copied. Then tap 'Back' to return to the app.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { [weak self] _ in
            self?.webView.load(URLRequest(url: url))
            self?.createBackButton()
        })
        
        present(alert, animated: true)
    }
    
    private func createBackButton() {
        // Add back button on top of WebView
        let backButton = UIButton(type: .system)
        backButton.setTitle("← Back", for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        backButton.backgroundColor = UIColor.systemBlue
        backButton.setTitleColor(.white, for: .normal)
        backButton.layer.cornerRadius = 8
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)
        
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 120),
            backButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc private func backButtonTapped() {
        // Hide WebView and check clipboard for URL
        webView.isHidden = true
        checkClipboardAndProcessCode()
    }
    
    @objc private func didTapManualCodeEntry() {
        // Show alert for manual code entry
        let alert = UIAlertController(
            title: "Enter Authorization Code",
            message: "If you have the authorization URL or code, paste it here",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "URL or Code"
            textField.autocapitalizationType = .none
            textField.keyboardType = .URL
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { [weak self, weak alert] _ in
            if let text = alert?.textFields?.first?.text {
                self?.processUserInput(text)
            }
        })
        
        present(alert, animated: true)
    }
    
    private func processUserInput(_ input: String) {
        // Process the input
        print("✅ Manual input: \(input)")
        processManualCode(code: input)
    }
    
    private func processManualCode(code: String) {
        // Token alma işlemini başlat
        print("🔄 Manuel kod ile token alınıyor...")
        AuthManager.shared.exchangeCodeForToken(code: code) { [weak self] success in
            print("🔑 Token değişimi sonucu: \(success ? "BAŞARILI" : "BAŞARISIZ")")
            DispatchQueue.main.async {
                if success {
                    // Başarılı oturum açma
                    print("✅ Token başarıyla alındı!")
                    
                    // Ana ekrana git
                    let mainAppTabBarVC = TabBarViewController()
                    self?.view.window?.rootViewController = mainAppTabBarVC
                    self?.view.window?.makeKeyAndVisible()
                    
                    // Animasyonlu geçiş
                    let transition = CATransition()
                    transition.duration = 0.3
                    transition.type = CATransitionType.fade
                    self?.view.window?.layer.add(transition, forKey: "transition")
                    
                    print("🎉 Oturum açıldı, ana ekrana yönlendirildi")
                    
                    // Completion handler'ı çağır
                    self?.completionHandler?(true)
                } else {
                    // Başarısız oturum açma
                    print("❌ Token alınamadı!")
                    
                    // Hata göster
                    let alert = UIAlertController(
                        title: "Oturum Açma Hatası",
                        message: "Kod geçersiz veya süresi dolmuş olabilir. Lütfen tekrar deneyin.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "Tamam", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
    }
    
    @objc public func handleAuthURLCallback(_ notification: Notification) {
        guard let url = notification.object as? URL else {
            print("⚠️ AuthVC: URL objesi bulunamadı")
            return
        }
        
        print("🔍 Callback URL alındı: \(url.absoluteString)")
        
        // URL'den kodu çıkart
        var code: String? = nil
        
        // Spotify SDK redirect URL formatı (spotify-sdk-xxxx://auth?code=ZZZ)
        if url.absoluteString.contains("spotify-sdk") {
            code = URLComponents(string: url.absoluteString)?.queryItems?.first(where: { $0.name == "code" })?.value
            print("🔍 Spotify SDK URL'sinden kod: \(code ?? "bulunamadı")")
        }
        // Normal web redirecti (https://www.iosacademy.io?code=ZZZ)
        else if let urlComponents = URLComponents(string: url.absoluteString),
                let codeItem = urlComponents.queryItems?.first(where: { $0.name == "code" }) {
            code = codeItem.value
        }
        
        if let code = code {
            print("✅ Kod başarıyla alındı: \(code)")
            
            // Safari'yi kapat (eğer açıksa)
            safariVC?.dismiss(animated: true) {
                print("🔐 Safari kapatıldı, token alınıyor...")
            }
            
            // Token al ve oturumu aç
            AuthManager.shared.exchangeCodeForToken(code: code) { [weak self] success in
                print("🔑 Token değişimi sonucu: \(success ? "BAŞARILI" : "BAŞARISIZ")")
                if success {
                    // Başarılı oturum açma
                    DispatchQueue.main.async {
                        // Ana ekrana git
                        let mainAppTabBarVC = TabBarViewController()
                        self?.view.window?.rootViewController = mainAppTabBarVC
                        self?.view.window?.makeKeyAndVisible()
                        print("🎉 Oturum açıldı, ana ekrana yönlendirildi")
                        
                        // Eski completion callback'i çağır
                        self?.completionHandler?(true)
                    }
                } else {
                    print("❌ Token alınamadı")
                    DispatchQueue.main.async {
                        // Hata göster
                        let alert = UIAlertController(
                            title: "Oturum Açma Hatası",
                            message: "Spotify oturumu açılırken bir sorun oluştu. Lütfen tekrar deneyin.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
                        self?.present(alert, animated: true)
                    }
                }
            }
            
            // Gözlemciyi kaldır
            NotificationCenter.default.removeObserver(self, name: Notification.Name("SpotifyAuthCallback"), object: nil)
        } else {
            print("⚠️ URL'den kod çıkarılamadı: \(url)")
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        guard let url = webView.url else {
            return
        }
        
        print("🔍 WebView navigasyon: \(url.absoluteString)")
        
        // Yönlendirme URL'ini kontrol et (iosacademy.io sayfasına yönlendirildik mi?)
        if url.absoluteString.contains("iosacademy.io") && url.absoluteString.contains("code=") {
            // Exchange the code for access token
            guard let code = URLComponents(string: url.absoluteString)?.queryItems?.first(where: { $0.name == "code" })?.value else {
                return
            }
            
            print("✅ WebView yönlendirmesinden kod tespit edildi: \(code)")
            
            // URL'yi panoya kopyala
            UIPasteboard.general.string = url.absoluteString
            print("📋 URL panoya kopyalandı: \(url.absoluteString)")
            
            // Kullanıcıya bildir
            let alert = UIAlertController(
                title: "URL Kopyalandı",
                message: "Oturum açma tamamlandı. URL otomatik olarak kopyalandı. İşlem başlatılıyor...",
                preferredStyle: .alert
            )
            
            present(alert, animated: true) { [weak self] in
                // 1 saniye sonra alert'ı kapat
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    alert.dismiss(animated: true) {
                        // WebView'i gizle
                        webView.isHidden = true
                        
                        // Token alma işlemini başlat
                        self?.processManualCode(code: code)
                    }
                }
            }
        }
    }

    // MARK: - SFSafariViewControllerDelegate
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        print("📱 Safari kapatıldı")
        
        // Kullanıcıya URL'yi kopyalayıp kopyalamadığını soralım
        let alert = UIAlertController(
            title: "URL Kopyaladınız mı?",
            message: "Spotify'den dönen URL'yi kopyaladınız mı? Kopyaladıysanız 'URL İşle' butonuna tıklayın.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "URL İşle", style: .default) { [weak self] _ in
            // URL'yi işle
            self?.checkClipboardAndProcessCode()
        })
        
        alert.addAction(UIAlertAction(title: "Manuel Kod Gir", style: .default) { [weak self] _ in
            // Manuel kod giriş ekranını göster
            self?.didTapManualCodeEntry()
        })
        
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func checkClipboardAndProcessCode() {
        // Pano içeriğini kontrol et
        let pasteboard = UIPasteboard.general
        
        guard let pasteboardContent = pasteboard.string, !pasteboardContent.isEmpty else {
            print("⚠️ Pano boş")
            didTapManualCodeEntry()
            return
        }
        
        print("📋 Panodaki içerik: \(pasteboardContent)")
        
        // URL formatında ve code= içeriyor mu?
        if pasteboardContent.contains("code=") {
            // URL'den kodu otomatik ayıkla
            let components = pasteboardContent.components(separatedBy: "code=")
            if components.count > 1 {
                var code = components[1]
                if let andIndex = code.firstIndex(of: "&") {
                    code = String(code[..<andIndex])
                }
                
                // Kodu temizle
                code = code.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !code.isEmpty {
                    // Kodu otomatik olarak işle
                    print("✅ Otomatik kod algılandı: \(code)")
                    processManualCode(code: code)
                    return
                }
            }
        }
        
        // Otomatik kod algılanamadıysa, manuel giriş ekranını göster
        didTapManualCodeEntry()
    }
}
