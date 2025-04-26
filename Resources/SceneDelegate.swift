//
//  SceneDelegate.swift
//  Spotify
//
//  Created by Mesut Aygun on 2/14/21.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)

        if AuthManager.shared.isSignedIn {
            // Aktif oturum varsa
            print("✅ Kayıtlı oturum bulundu, ana ekran açılıyor...")
            window.rootViewController = TabBarViewController()
        }
        else {
            print("⚠️ Kayıtlı oturum bulunamadı, karşılama ekranı açılıyor...")
            let navVC = UINavigationController(rootViewController: WelcomeViewController())
            navVC.navigationBar.prefersLargeTitles = true
            navVC.viewControllers.first?.navigationItem.largeTitleDisplayMode = .always
            window.rootViewController = navVC
        }

        window.makeKeyAndVisible()
        self.window = window
        
        // Eğer URL ile açıldıysa işle
        if let url = connectionOptions.urlContexts.first?.url {
            print("🔗 Uygulama URL ile açıldı: \(url)")
            self.scene(scene, openURLContexts: connectionOptions.urlContexts)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        print("🔍 Uygulama foreground'a döndü, token kontrolü yapılıyor...")
        
        // Kullanıcı Safari'den geri döndüğünde token kontrolü
        checkForTokenAndNavigateIfNeeded()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    // Handle Spotify redirect URL
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else {
            print("⚠️ URL bulunamadı")
            return
        }
        
        print("📱 SceneDelegate URL alındı: \(url.absoluteString)")
        
        // URL içeriyor mu kontrol et
        if url.absoluteString.contains("code=") || 
           url.absoluteString.contains("iosacademy.io") ||
           url.absoluteString.contains("spotify-sdk") {
            
            // URL işleme yardımcı fonksiyonunu çağırıyoruz
            handleOpenURL(url: url, scene: scene)
        } else {
            print("⚠️ Beklenmeyen URL formatı: \(url.absoluteString)")
        }
    }
    
    // Universal link desteği için
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        print("🔄 Universal Link alındı: \(userActivity)")
        
        // Web sayfası ziyaret ediliyorsa
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return
        }
        
        print("🌍 Web URL: \(url)")
        
        // Eğer iosacademy.io'dan bir URL ise işle
        if url.absoluteString.contains("iosacademy.io") {
            // URL içindeki code parametresini çıkart ve işle
            if let code = URLComponents(string: url.absoluteString)?.queryItems?.first(where: { $0.name == "code" })?.value {
                print("✅ Universal Link'ten kod alındı: \(code)")
                
                // Token alma işlemini başlat
                AuthManager.shared.exchangeCodeForToken(code: code) { [weak self] success in
                    if success {
                        DispatchQueue.main.async {
                            // Ana ekrana git
                            let mainAppTabBarVC = TabBarViewController()
                            
                            // Root controller'ı değiştir
                            self?.window?.rootViewController = mainAppTabBarVC
                            self?.window?.makeKeyAndVisible()
                            
                            print("🎉 Universal Link ile oturum açma başarılı")
                        }
                    } else {
                        print("❌ Universal Link token alınamadı")
                    }
                }
            }
        }
    }
    
    // URL'yi işlemek için yardımcı fonksiyon
    private func handleOpenURL(url: URL, scene: UIScene) {
        print("🔍 URL işleniyor: \(url.absoluteString)")
        
        // iosacademy.io URL'si içeriyor mu?
        if url.absoluteString.contains("iosacademy.io") {
            // Kodu otomatik olarak kopyala
            if let code = URLComponents(string: url.absoluteString)?.queryItems?.first(where: { $0.name == "code" })?.value {
                // Kodu pasteboard'a kopyala
                UIPasteboard.general.string = code
                print("📋 URL'den kod otomatik olarak kopyalandı: \(code)")
                
                // Kullanıcıya bildirim vermek için bir alert göster
                DispatchQueue.main.async {
                    guard let windowScene = scene as? UIWindowScene,
                          let rootViewController = windowScene.windows.first?.rootViewController else {
                        return
                    }
                    
                    // Açık olan alert'ı kapat
                    if let presentedVC = rootViewController.presentedViewController {
                        presentedVC.dismiss(animated: false, completion: nil)
                    }
                    
                    let alert = UIAlertController(
                        title: "Kod Kopyalandı",
                        message: "Spotify'den alınan doğrulama kodu panoya kopyalandı: \(code.prefix(8))...\n\nBu kodu kullanarak oturum açmak ister misiniz?",
                        preferredStyle: .alert
                    )
                    
                    alert.addAction(UIAlertAction(title: "Evet", style: .default) { _ in
                        // Token alma işlemini başlat
                        self.processAuthCode(code: code, scene: scene)
                    })
                    
                    alert.addAction(UIAlertAction(title: "Daha Sonra", style: .cancel))
                    
                    rootViewController.present(alert, animated: true)
                }
            }
        }
        
        // URL'den kod parametresini çıkartmaya çalış
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
            print("✅ URL'den kod başarıyla alındı: \(code)")
            
            // Token alma işlemini başlat
            processAuthCode(code: code, scene: scene)
        } else {
            print("⚠️ URL'den kod çıkarılamadı: \(url.absoluteString)")
        }
        
        // AuthViewController'a da bildirelim
        NotificationCenter.default.post(
            name: Notification.Name("SpotifyAuthCallback"),
            object: url
        )
    }
    
    // Auth kodu işleme ve token alma
    private func processAuthCode(code: String, scene: UIScene) {
        AuthManager.shared.exchangeCodeForToken(code: code) { [weak self] success in
            print("🔑 Token değişimi sonucu: \(success ? "BAŞARILI" : "BAŞARISIZ")")
            
            if success {
                DispatchQueue.main.async {
                    // Ana ekrana git
                    let mainAppTabBarVC = TabBarViewController()
                    
                    // Root controller'ı değiştir
                    self?.window?.rootViewController = mainAppTabBarVC
                    self?.window?.makeKeyAndVisible()
                    
                    // Animasyonlu geçiş
                    let transition = CATransition()
                    transition.duration = 0.3
                    transition.type = CATransitionType.fade
                    self?.window?.layer.add(transition, forKey: "transition")
                    
                    print("🎉 Token alındı, ana ekrana yönlendirildi")
                }
            }
        }
    }

    // Token kontrol ve ana sayfaya geçiş
    private func checkForTokenAndNavigateIfNeeded() {
        AuthManager.shared.validateAndRefreshTokenIfNeeded { [weak self] success in
            if success {
                DispatchQueue.main.async {
                    // AuthViewController açıksa ve token varsa, TabBarViewController'a geç
                    if let rootVC = self?.window?.rootViewController,
                       rootVC is UINavigationController,
                       let navVC = rootVC as? UINavigationController,
                       let topVC = navVC.topViewController,
                       topVC is AuthViewController {
                        
                        print("✅ Token bulundu ve AuthViewController açık, ana sayfaya geçiliyor...")
                        
                        // Ana ekrana git
                        let mainAppTabBarVC = TabBarViewController()
                        
                        // Animasyonlu geçiş
                        let transition = CATransition()
                        transition.duration = 0.3
                        transition.type = CATransitionType.fade
                        self?.window?.layer.add(transition, forKey: "transition")
                        
                        // Root controller'ı değiştir
                        self?.window?.rootViewController = mainAppTabBarVC
                        self?.window?.makeKeyAndVisible()
                    }
                }
            }
        }
    }

}

