//
//  WelcomeViewController.swift
//  Spotify
//
//  Created by Mesut Aygun on 2/14/21.
//

import UIKit

class WelcomeViewController: UIViewController {

    private let signInButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemGreen
        button.setTitle("Sign In with Spotify", for: .normal)
        button.setTitleColor(.black, for: .normal)
        return button
    }()

//    private let spotifyAppSignInButton: UIButton = {
//        let button = UIButton()
//        button.backgroundColor = .systemGreen
//        button.setTitle("Sign In with Spotify App", for: .normal)
//        button.setTitleColor(.white, for: .normal)
//        return button
//    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(named: "albums_background")
        return imageView
    }()

    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0.7
        return view
    }()

    private let logoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "logo"))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .white
        label.font = .systemFont(ofSize: 32, weight: .semibold)
        label.text = "Listen to Millions\nof Songs on\nthe go."
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Spotify"
        view.addSubview(imageView)
        view.addSubview(overlayView)
        view.backgroundColor = .blue
        view.addSubview(signInButton)
        //view.addSubview(spotifyAppSignInButton)
        signInButton.addTarget(self, action: #selector(didTapSignIn), for: .touchUpInside)
        //spotifyAppSignInButton.addTarget(self, action: #selector(didTapSpotifyAppSignIn), for: .touchUpInside)
        
        view.addSubview(label)
        view.addSubview(logoImageView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.frame = view.bounds
        overlayView.frame = view.bounds
        
        // Ana Sign In butonu
        signInButton.frame = CGRect(
            x: 20,
            y: view.height-100-view.safeAreaInsets.bottom,
            width: view.width-40,
            height: 50
        )
        
        // Spotify App Sign In butonu
//        spotifyAppSignInButton.frame = CGRect(
//            x: 20,
//            y: view.height-40-view.safeAreaInsets.bottom,
//            width: view.width-40,
//            height: 50
//        )
        
        logoImageView.frame = CGRect(x: (view.width-120)/2, y: (view.height-350)/2, width: 120, height: 120)
        label.frame = CGRect(x: 30, y: logoImageView.bottom+30, width: view.width-60, height: 150)
    }

    @objc func didTapSignIn() {
        print("👆 Sign In butonuna tıklandı")
        
        // Daha önce bir oturum açma işlemi varsa temizle
        UserDefaults.standard.removeObject(forKey: "access_token")
        UserDefaults.standard.removeObject(forKey: "refresh_token")
        UserDefaults.standard.removeObject(forKey: "expirationDate")
        
        let vc = AuthViewController()
        vc.completionHandler = { [weak self] success in
            print("🔙 AuthViewController'dan dönüş: \(success ? "Başarılı" : "Başarısız")")
            DispatchQueue.main.async {
                if success {
                    // Doğrudan anaekrana geçiş yap
                    let mainAppTabBarVC = TabBarViewController()
                    
                    // Root değiştir
                    UIApplication.shared.windows.first?.rootViewController = mainAppTabBarVC
                    UIApplication.shared.windows.first?.makeKeyAndVisible()
                    
                    // Geçiş animasyonu ekle
                    let transition = CATransition()
                    transition.duration = 0.4
                    transition.type = CATransitionType.fade
                    UIApplication.shared.windows.first?.layer.add(transition, forKey: kCATransition)
                } else {
                    // Normal handleSignIn metodunu çağır
                    self?.handleSignIn(success: success)
                }
            }
        }
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func didTapSpotifyAppSignIn() {
        print("👆 Spotify App Sign In butonuna tıklandı")
        
        // Daha önce bir oturum açma işlemi varsa temizle
        UserDefaults.standard.removeObject(forKey: "access_token")
        UserDefaults.standard.removeObject(forKey: "refresh_token")
        UserDefaults.standard.removeObject(forKey: "expirationDate")
        
        let vc = AuthViewController()
        vc.completionHandler = { [weak self] success in
            print("🔙 AuthViewController'dan dönüş (Spotify App): \(success ? "Başarılı" : "Başarısız")")
            DispatchQueue.main.async {
                if success {
                    // Doğrudan anaekrana geçiş yap
                    let mainAppTabBarVC = TabBarViewController()
                    
                    // Root değiştir
                    UIApplication.shared.windows.first?.rootViewController = mainAppTabBarVC
                    UIApplication.shared.windows.first?.makeKeyAndVisible()
                    
                    // Geçiş animasyonu ekle
                    let transition = CATransition()
                    transition.duration = 0.4
                    transition.type = CATransitionType.fade
                    UIApplication.shared.windows.first?.layer.add(transition, forKey: kCATransition)
                } else {
                    // Normal handleSignIn metodunu çağır
                    self?.handleSignIn(success: success)
                }
            }
        }
        
        // Doğrudan Spotify uygulamasını açmaya çalış
        if let spotifyAppURL = AuthManager.shared.spotifyAppSignInURL {
            if UIApplication.shared.canOpenURL(spotifyAppURL) {
                print("✅ Spotify uygulaması açılıyor: \(spotifyAppURL)")
                UIApplication.shared.open(spotifyAppURL, options: [:]) { success in
                    print("🔍 Spotify uygulaması açıldı: \(success ? "BAŞARILI" : "BAŞARISIZ")")
                }
                
                // Kullanıcı Spotify'dan döndüğünde token kontrolü yapmak için bir dinleyici ekle
                NotificationCenter.default.addObserver(
                    vc,
                    selector: #selector(AuthViewController.handleAuthURLCallback(_:)),
                    name: Notification.Name("SpotifyAuthCallback"),
                    object: nil
                )
            } else {
                // Spotify uygulaması yüklü değilse App Store'u aç veya normal yöntemle devam et
                print("⚠️ Spotify uygulaması yüklü değil, normal oturum açma yöntemiyle devam edilecek")
                vc.navigationItem.largeTitleDisplayMode = .never
                navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            print("⚠️ Spotify App URL oluşturulamadı, normal oturum açma yöntemiyle devam edilecek")
            vc.navigationItem.largeTitleDisplayMode = .never
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func handleSignIn(success: Bool) {
        // Log user in or yell at them for error
        guard success else {
            let alert = UIAlertController(title: "Oturum Açma Hatası",
                                          message: "Spotify oturumu açılırken bir sorun oluştu. Lütfen tekrar deneyin.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .cancel, handler: nil))
            present(alert, animated: true)
            return
        }

        print("🔑 WelcomeVC: Başarılı oturum, ana ekrana geçiliyor")
        
        // Auth kontrolü yap, sonra ana ekrana geç
        AuthManager.shared.validateAndRefreshTokenIfNeeded { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    // Ana uygulamaya geç
                    let mainAppTabBarVC = TabBarViewController()
                    mainAppTabBarVC.modalPresentationStyle = .fullScreen
                    
                    // Mevcut view controller hiyerarşisini tamamen değiştir
                    UIApplication.shared.windows.first?.rootViewController = mainAppTabBarVC
                    UIApplication.shared.windows.first?.makeKeyAndVisible()
                    
                    // Geçiş animasyonu ekle
                    let transition = CATransition()
                    transition.duration = 0.4
                    transition.type = CATransitionType.fade
                    UIApplication.shared.windows.first?.layer.add(transition, forKey: kCATransition)
                } else {
                    // Token yenilenemedi, tekrar oturum açma ekranına dön
                    let alert = UIAlertController(
                        title: "Oturum Hatası",
                        message: "Oturum açma bilgileri geçersiz, lütfen tekrar giriş yapın.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "Tamam", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
    }
}
