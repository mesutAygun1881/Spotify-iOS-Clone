//
//  AuthManager.swift
//  Spotify
//
//  Created by Mesut Aygun on 2/14/21.
//

import Foundation
import UIKit

final class AuthManager {
    static let shared = AuthManager()
    
    private var refreshingToken = false
    
    struct Constants {
        static let clientID = "c658cfb036f34f6e835e59410b8e0ffb"
        static let clientSecret = "35e7c3c6d34c4e9fb2b5b9b53d820544"
        static let tokenAPIURL = "https://accounts.spotify.com/api/token"
        static let redirectURI = "https://www.iosacademy.io"
        static let scopes = """
        user-read-private \
        playlist-modify-public \
        playlist-read-private \
        playlist-modify-private \
        user-follow-read \
        user-library-modify \
        user-library-read \
        user-read-email \
        user-read-currently-playing \
        user-read-playback-state \
        streaming \
        app-remote-control
        """.replacingOccurrences(of: "\n", with: " ").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }
    
    private init() {}
    
    public var signInURL: URL? {
        let base = "https://accounts.spotify.com/authorize"
        let encodedRedirectURI = Constants.redirectURI.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? Constants.redirectURI
        
        let string = "\(base)?response_type=code&client_id=\(Constants.clientID)&scope=\(Constants.scopes)&redirect_uri=\(encodedRedirectURI)&show_dialog=TRUE"
        print("🔍 Spotify Auth URL: \(string)")
        return URL(string: string)
    }
    
    public var spotifyAppSignInURL: URL? {
        let base = "spotify:authorize"
        let redirectScheme = "spotify-sdk-c658cfb036f34f6e835e59410b8e0ffb"
        let encodedRedirectURI = redirectScheme + "://auth"
        
        let string = "\(base)?response_type=code&client_id=\(Constants.clientID)&scope=\(Constants.scopes)&redirect_uri=\(encodedRedirectURI)&show_dialog=TRUE"
        print("🔍 Spotify App URL: \(string)")
        return URL(string: string)
    }
    
    var isSignedIn: Bool {
        return accessToken != nil
    }
    
    public var accessToken: String? {
        return UserDefaults.standard.string(forKey: "access_token")
    }
    
    private var refreshToken: String? {
        return UserDefaults.standard.string(forKey: "refresh_token")
    }
    
    private var tokenExpirationDate: Date? {
        return UserDefaults.standard.object(forKey: "expirationDate") as? Date
    }
    
    private var shouldRefreshToken: Bool {
        guard let expirationDate = tokenExpirationDate else {
            return false
        }
        let currentDate = Date()
        let fiveMinutes: TimeInterval = 300
        return currentDate.addingTimeInterval(fiveMinutes) >= expirationDate
    }
    
    // MARK: - Token Exchange
    
    /// Exchange authorization code from Spotify for access token
    public func exchangeCodeForToken(code: String, completion: @escaping ((Bool) -> Void)) {
        // Get Token
        guard let url = URL(string: Constants.tokenAPIURL) else {
            print("❌ Token URL oluşturulamadı")
            completion(false)
            return
        }
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded ", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.query?.data(using: .utf8)
        
        let basicToken = "\(Constants.clientID):\(Constants.clientSecret)"
        let data = basicToken.data(using: .utf8)
        guard let base64String = data?.base64EncodedString() else {
            print("❌ Base64 dönüşüm hatası")
            completion(false)
            return
        }
        
        request.setValue("Basic \(base64String)", forHTTPHeaderField: "Authorization")
        
        print("🔄 Token isteği gönderiliyor...")
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                completion(false)
                return
            }
            
            // Convert data to json
            do {
                let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                print("✅ Token başarıyla alındı: \(result.access_token.prefix(5))...")
                self?.cacheToken(result: result)
                completion(true)
            }
            catch {
                print("❌ Token JSON decode hatası: \(error.localizedDescription)")
                completion(false)
            }
        }
        task.resume()
    }
    
    private var onRefreshBlocks = [((String) -> Void)]()
    
    /// Supplies valid token to be used with API Calls
    public func withValidToken(completion: @escaping (String) -> Void) {
        guard let token = accessToken, !refreshingToken else {
            refreshIfNeeded { [weak self] success in
                if success, let token = self?.accessToken {
                    print("✅ DEBUG: withValidToken - Token yenilendi: \(token.prefix(10))...")
                    completion(token)
                } else {
                    print("❌ DEBUG: withValidToken - Token yenilenemedi!")
                    completion("")
                }
            }
            return
        }
        
        print("🔍 DEBUG: withValidToken - Mevcut token kullanılıyor: \(token.prefix(10))...")
        completion(token)
    }
    
    public func validateAndRefreshTokenIfNeeded(completion: @escaping (Bool) -> Void) {
        // Hiç token yoksa başarısız
        guard accessToken != nil else {
            print("❌ DEBUG: validateAndRefreshTokenIfNeeded - Token bulunamadı, oturum açılmamış")
            completion(false)
            return
        }
        
        // Şu an yenileme yapılıyorsa bekle ve sonucuna göre devam et
        if refreshingToken {
            print("⚠️ DEBUG: validateAndRefreshTokenIfNeeded - Token zaten yenileniyor, sonucu bekleniyor")
            refreshIfNeeded { success in
                print("\(success ? "✅" : "❌") DEBUG: validateAndRefreshTokenIfNeeded - Token yenileme sonucu: \(success)")
                completion(success)
            }
            return
        }
        
        // Token süresini kontrol et
        if shouldRefreshToken {
            print("🔍 DEBUG: validateAndRefreshTokenIfNeeded - Token süresi dolmuş, yenileniyor")
            refreshIfNeeded { success in
                print("\(success ? "✅" : "❌") DEBUG: validateAndRefreshTokenIfNeeded - Token yenileme sonucu: \(success)")
                completion(success)
            }
        } else {
            print("✅ DEBUG: validateAndRefreshTokenIfNeeded - Token geçerli, yenileme gerekmiyor")
            completion(true)
        }
    }
    
    public func refreshIfNeeded(completion: ((Bool) -> Void)?) {
        guard !refreshingToken else {
            print("⚠️ DEBUG: refreshIfNeeded - Token zaten yenileniyor")
            return
        }
        
        guard shouldRefreshToken else {
            print("✅ DEBUG: refreshIfNeeded - Token geçerli, yenileme gerekmiyor")
            completion?(true)
            return
        }
        
        guard let refreshToken = self.refreshToken else {
            print("❌ DEBUG: refreshIfNeeded - Refresh token bulunamadı")
            completion?(false)
            return
        }
        
        print("🔍 DEBUG: refreshIfNeeded - Token yenileme başlatılıyor, refresh token: \(refreshToken.prefix(10))...")
        
        // Refresh the token
        refreshingToken = true
        
        let url = URL(string: Constants.tokenAPIURL)!
        let basicToken = Constants.clientID+":"+Constants.clientSecret
        let data = basicToken.data(using: .utf8)
        guard let base64String = data?.base64EncodedString() else {
            print("❌ DEBUG: refreshIfNeeded - Base64 kodlama hatası")
            refreshingToken = false
            completion?(false)
            return
        }
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken),
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic \(base64String)", forHTTPHeaderField: "Authorization")
        request.httpBody = components.query?.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            // Token yenileme işlemi bitti, flag'i sıfırla
            self?.refreshingToken = false
            
            // HTTP yanıt kodunu kontrol et
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 DEBUG: refreshIfNeeded HTTP yanıt kodu: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    print("❌ DEBUG: refreshIfNeeded - HTTP yanıt başarısız: \(httpResponse.statusCode)")
                    
                    // Response datası varsa, hatanın ne olduğunu görelim
                    if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("📊 DEBUG: refreshIfNeeded - HTTP yanıt içeriği: \(json)")
                    }
                    
                    completion?(false)
                    return
                }
            }
            
            guard let data = data, error == nil else {
                print("❌ DEBUG: refreshIfNeeded - Veri alınamadı: \(error?.localizedDescription ?? "bilinmeyen hata")")
                completion?(false)
                return
            }
            
            do {
                let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                print("✅ DEBUG: refreshIfNeeded - Token başarıyla yenilendi, yeni token: \(result.access_token.prefix(10))...")
                
                self?.onRefreshBlocks.forEach { $0(result.access_token) }
                self?.onRefreshBlocks.removeAll()
                self?.cacheToken(result: result)
                completion?(true)
            }
            catch {
                print("❌ DEBUG: refreshIfNeeded - JSON decode hatası: \(error.localizedDescription)")
                
                // JSON verilerini loglayalım
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("🔍 DEBUG: refreshIfNeeded - Alınan JSON: \(jsonString)")
                }
                
                completion?(false)
            }
        }
        task.resume()
    }
    
    private func cacheToken(result: AuthResponse) {
        UserDefaults.standard.setValue(result.access_token, forKey: "access_token")
        
        if let refresh_token = result.refresh_token {
            UserDefaults.standard.setValue(refresh_token, forKey: "refresh_token")
        }
        
        UserDefaults.standard.setValue(Date().addingTimeInterval(TimeInterval(result.expires_in)), forKey: "expirationDate")
        print("✅ DEBUG: cacheToken - Token kaydedildi, süre: \(result.expires_in) saniye")
    }
    
    public func signOut(completion: (Bool) -> Void) {
        UserDefaults.standard.setValue(nil,
                                       forKey: "access_token")
        UserDefaults.standard.setValue(nil,
                                       forKey: "refresh_token")
        UserDefaults.standard.setValue(nil,
                                       forKey: "expirationDate")
        
        completion(true)
    }
}
