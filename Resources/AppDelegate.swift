//
//  AppDelegate.swift
//  Spotify
//
//  Created by Mesut Aygun on 2/14/21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let window = UIWindow(frame: UIScreen.main.bounds)

        if AuthManager.shared.isSignedIn {
            AuthManager.shared.refreshIfNeeded(completion: nil)
            window.rootViewController = TabBarViewController()
        }
        else {
            let navVC = UINavigationController(rootViewController: WelcomeViewController())
            navVC.navigationBar.prefersLargeTitles = true
            navVC.viewControllers.first?.navigationItem.largeTitleDisplayMode = .always
            window.rootViewController = navVC
        }

        window.makeKeyAndVisible()
        self.window = window

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // Handle Spotify redirect URL for older iOS versions
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        print("📱 AppDelegate URL alındı: \(url.absoluteString)")
        
        // iosacademy.io URL'si içeriyor mu?
        if url.absoluteString.contains("iosacademy.io") {
            // Kodu otomatik olarak kopyala
            if let code = URLComponents(string: url.absoluteString)?.queryItems?.first(where: { $0.name == "code" })?.value {
                // Kodu pasteboard'a kopyala
                UIPasteboard.general.string = code
                print("📋 URL'den kod otomatik olarak kopyalandı: \(code)")
                
                // Kullanıcıya bildirim vermek için bir alert göster
                DispatchQueue.main.async {
                    // Açık olan alert'ı kapat
                    if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                        if let presentedVC = rootVC.presentedViewController {
                            presentedVC.dismiss(animated: false, completion: nil)
                        }
                        
                        let alert = UIAlertController(
                            title: "Kod Kopyalandı",
                            message: "Spotify'den alınan doğrulama kodu panoya kopyalandı: \(code.prefix(8))...\n\nBu kodu kullanarak oturum açmak ister misiniz?",
                            preferredStyle: .alert
                        )
                        
                        alert.addAction(UIAlertAction(title: "Evet", style: .default) { _ in
                            // Token alma işlemini başlat
                            self.processAuthCode(code: code)
                        })
                        
                        alert.addAction(UIAlertAction(title: "Daha Sonra", style: .cancel))
                        
                        rootVC.present(alert, animated: true)
                    }
                }
            }
        }
        
        // Spotify callback olup olmadığını kontrol et
        if url.absoluteString.contains("code=") ||
           url.absoluteString.contains("iosacademy.io") ||
           url.absoluteString.contains("spotify-sdk") {
            
            // URL'den kodu çıkartmaya çalış
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
                print("✅ AppDelegate: URL'den kod başarıyla alındı: \(code)")
                
                // Token alma işlemini başlat
                processAuthCode(code: code)
            }
            
            // AuthViewController'a da bildirelim
            NotificationCenter.default.post(
                name: Notification.Name("SpotifyAuthCallback"),
                object: url
            )
            return true
        }
        
        print("⚠️ AppDelegate: Beklenmeyen URL formatı: \(url.absoluteString)")
        return false
    }
    
    // Auth kodu işleme ve token alma
    private func processAuthCode(code: String) {
        // Direkt burada token alma işlemini yapalım
        AuthManager.shared.exchangeCodeForToken(code: code) { success in
            print("🔑 AppDelegate Token değişimi sonucu: \(success ? "BAŞARILI" : "BAŞARISIZ")")
            
            if success {
                DispatchQueue.main.async {
                    // Ana ekrana git
                    let mainAppTabBarVC = TabBarViewController()
                    
                    // Root controller'ı değiştir
                    guard let window = UIApplication.shared.windows.first else { return }
                    window.rootViewController = mainAppTabBarVC
                    window.makeKeyAndVisible()
                    
                    // Animasyonlu geçiş
                    let transition = CATransition()
                    transition.duration = 0.3
                    transition.type = CATransitionType.fade
                    window.layer.add(transition, forKey: "transition")
                    
                    print("🎉 AppDelegate: Token alındı, ana ekrana yönlendirildi")
                }
            }
        }
    }
    
    // Universal link desteği için
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        print("🔄 Universal Link alındı (AppDelegate): \(userActivity)")
        
        // Web sayfası ziyaret ediliyorsa
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return false
        }
        
        print("🌍 Web URL (AppDelegate): \(url)")
        
        // Eğer iosacademy.io'dan bir URL ise işle
        if url.absoluteString.contains("iosacademy.io") {
            // URL içindeki code parametresini çıkart ve işle
            if let code = URLComponents(string: url.absoluteString)?.queryItems?.first(where: { $0.name == "code" })?.value {
                print("✅ AppDelegate: Universal Link'ten kod alındı: \(code)")
                
                // Token alma işlemini başlat
                AuthManager.shared.exchangeCodeForToken(code: code) { [weak self] success in
                    if success {
                        DispatchQueue.main.async {
                            // Ana ekrana git
                            let mainAppTabBarVC = TabBarViewController()
                            
                            // Root controller'ı değiştir
                            if let window = self?.window {
                                window.rootViewController = mainAppTabBarVC
                                window.makeKeyAndVisible()
                                print("🎉 AppDelegate: Universal Link ile oturum açma başarılı")
                            }
                        }
                    } else {
                        print("❌ AppDelegate: Universal Link token alınamadı")
                    }
                }
            }
            return true
        }
        
        return false
    }

}

