//
//  AppRemoteManager.swift
//  Spotify
//
//  Created by Mesut Aygün on 23.04.2025.
//



import Foundation
import SpotifyiOS

class AppRemoteManager: NSObject {
    static let shared = AppRemoteManager()

    private let clientID = "c658cfb036f34f6e835e59410b8e0ffb"
    private let redirectURI = URL(string: "spotify-sdk-c658cfb036f34f6e835e59410b8e0ffb://auth")!

    private lazy var configuration: SPTConfiguration = {
        let config = SPTConfiguration(clientID: clientID, redirectURL: redirectURI)
        config.playURI = ""
        config.tokenSwapURL = nil
        config.tokenRefreshURL = nil
        return config
    }()

    private var appRemote: SPTAppRemote?

    func getAppRemote() -> SPTAppRemote? {
        return appRemote
    }

    func connectIfNeeded() {
        guard let accessToken = AuthManager.shared.accessToken else {
            print("❌ AppRemote: Erişim token'ı yok")
            return
        }

        if appRemote == nil {
            print("⚙️ AppRemote oluşturuluyor")
            appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
            appRemote?.delegate = self
        }

        if let appRemote = appRemote, !appRemote.isConnected {
            print("🔌 AppRemote bağlanıyor...")
            appRemote.connectionParameters.accessToken = accessToken
            appRemote.connect()
        } else {
            print("✅ AppRemote zaten bağlı")
        }
    }

    func connectTest() {
        guard let accessToken = AuthManager.shared.accessToken else {
            print("❌ connectTest: access token mevcut değil")
            return
        }
        print("🔍 connectTest: Token alınmış - \(accessToken.prefix(10))...")

        connectIfNeeded()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if let remote = self.appRemote {
                if remote.isConnected {
                    print("✅ connectTest: Spotify AppRemote bağlantısı başarılı")
                } else {
                    print("❌ connectTest: Spotify AppRemote bağlantısı başarısız")
                }
            } else {
                print("❌ connectTest: AppRemote objesi oluşturulamadı")
            }
        }
    }

    func playTrack(uri: String) {
        connectIfNeeded()
        print("▶️ Şarkı çalınıyor: \(uri)")
        appRemote?.playerAPI?.play(uri, callback: { result, error in
            if let error = error {
                print("❌ Play Error: \(error.localizedDescription)")
            } else {
                print("✅ Playing Track: \(uri)")
            }
        })
    }

    func applicationWillResignActive() {
        if appRemote?.isConnected == true {
            print("⛔️ AppRemote bağlantısı kesiliyor (willResignActive)")
            appRemote?.disconnect()
        }
    }

    func applicationDidBecomeActive() {
        print("🔄 App aktif oldu, bağlantı kontrol ediliyor...")
        connectIfNeeded()
    }
}

extension AppRemoteManager: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("✅ App Remote Connected")
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("❌ App Remote Connection Failed: \(error?.localizedDescription ?? "unknown")")
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("⚠️ App Remote Disconnected: \(error?.localizedDescription ?? "unknown")")
    }
}
