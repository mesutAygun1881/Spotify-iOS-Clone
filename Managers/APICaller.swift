//
//  APICaller.swift
//  Spotify
//
//  Created by Mesut Aygun on 2/14/21.
//

import Foundation

final class APICaller {
    static let shared = APICaller()

    private init() {}

    struct Constants {
        static let baseAPIURL = "https://api.spotify.com/v1"
    }

    enum APIError: Error {
        case faileedToGetData
    }

    // MARK: - Albums

    public func getAlbumDetails(for album: Album, completion: @escaping (Result<AlbumDetailsResponse, Error>) -> Void) {
        createRequest(
            with: URL(string: Constants.baseAPIURL + "/albums/" + album.id),
            type: .GET
        ) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.faileedToGetData))
                    return
                }

                do {
                    let result = try JSONDecoder().decode(AlbumDetailsResponse.self, from: data)
                    completion(.success(result))
                }
                catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    public func startPlayback(trackUri: String, completion: @escaping (Bool) -> Void) {
        let url = URL(string: Constants.baseAPIURL + "/me/player/play")
        createRequest(with: url, type: .PUT) { request in
            var request = request
            let json = [
                "uris": [trackUri]
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: json, options: .fragmentsAllowed)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let httpResp = response as? HTTPURLResponse {
                    print("📡 Start Playback Status: \(httpResp.statusCode)")
                }
                completion(error == nil)
            }
            task.resume()
        }
    }
    public func getCurrentUserAlbums(completion: @escaping (Result<[Album], Error>) -> Void) {
        // Market parametresi ekleyerek ve daha detaylı loglama yaparak sorunu tespit edelim
        let urlString = Constants.baseAPIURL + "/me/albums?limit=50&market=US"
        print("🔍 DEBUG: getCurrentUserAlbums - URL: \(urlString)")

        createRequest(
            with: URL(string: urlString),
            type: .GET
        ) { request in
            // Debug için headers görüntüleme
            print("📍 DEBUG: getCurrentUserAlbums - Headers: \(request.allHTTPHeaderFields ?? [:])")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                // HTTP response kodunu kontrol et
                if let httpResponse = response as? HTTPURLResponse {
                    print("📍 DEBUG: getCurrentUserAlbums - HTTP Status: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 401 {
                        print("⚠️ DEBUG: getCurrentUserAlbums - Unauthorized! Token geçersiz veya süresi dolmuş olabilir.")
                        
                        // Token yenileme dene ve tekrar istek at
                        AuthManager.shared.refreshIfNeeded { success in
                            if success {
                                print("✅ DEBUG: getCurrentUserAlbums - Token yenilendi, istek tekrarlanıyor")
                                // Yeni token ile recursively aynı işlevi çağır
                                self.getCurrentUserAlbums(completion: completion)
                            } else {
                                print("❌ DEBUG: getCurrentUserAlbums - Token yenilenemedi!")
                                completion(.failure(APIError.faileedToGetData))
                            }
                        }
                        return
                    }
                    
                    if httpResponse.statusCode == 404 {
                        print("⚠️ DEBUG: getCurrentUserAlbums - Not Found! API adresi veya parametreler yanlış olabilir.")
                    }
                }
                
                // Hata kontrolü
                if let error = error {
                    print("❌ DEBUG: getCurrentUserAlbums - Network error: \(error.localizedDescription)")
                    completion(.failure(APIError.faileedToGetData))
                    return
                }
                
                guard let data = data, error == nil else {
                    print("❌ DEBUG: getCurrentUserAlbums - Veri yok")
                    completion(.failure(APIError.faileedToGetData))
                    return
                }
                
                // JSON yanıtını kontrol et
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📊 DEBUG: getCurrentUserAlbums - JSON Yanıt: \(jsonString.prefix(200))...")
                }

                do {
                    let result = try JSONDecoder().decode(LibraryAlbumsResponse.self, from: data)
                    print("✅ DEBUG: getCurrentUserAlbums - Başarılı: \(result.items.count) albüm alındı")
                    completion(.success(result.items.compactMap({ $0.album })))
                }
                catch {
                    print("❌ DEBUG: getCurrentUserAlbums - JSON decode hatası: \(error.localizedDescription)")
                    
                    // API yanıt formatını görelim
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("📊 DEBUG: getCurrentUserAlbums - Hata detay: \(json)")
                    }
                    
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    public func getCurrentlyPlayingTrack(completion: @escaping (Result<CurrentlyPlayingResponse, Error>) -> Void) {
        let url = URL(string: Constants.baseAPIURL + "/me/player/currently-playing")
        
        createRequest(with: url, type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.faileedToGetData))
                    return
                }

                // ✅ Eğer Spotify hiçbir şarkı çalmıyorsa 204 No Content döner ve veri boş gelir.
                if data.count == 0 {
                    print("📭 DEBUG: Spotify'da şu anda çalan bir şey yok (204 No Content).")
                    completion(.failure(APIError.faileedToGetData))
                    return
                }

                if let json = String(data: data, encoding: .utf8) {
                    print("📊 DEBUG: CurrentlyPlayingResponse JSON: \(json)")
                }

                do {
                    let result = try JSONDecoder().decode(CurrentlyPlayingResponse.self, from: data)
                    completion(.success(result))
                } catch {
                    print("❌ Decode hatası: \(error)")
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    public func saveAlbum(album: Album, completion: @escaping (Bool) -> Void) {
        createRequest(
            with: URL(string: Constants.baseAPIURL + "/me/albums?ids=\(album.id)"),
            type: .PUT
        ) { baseRequest in
            var request = baseRequest
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let code = (response as? HTTPURLResponse)?.statusCode,
                      error == nil else {
                    completion(false)
                    return
                }
                print(code)
                completion(code == 200)
            }
            task.resume()
        }
    }

    // MARK: - Playlists

    public func getPlaylistDetails(for playlist: Playlist, completion: @escaping (Result<PlaylistDetailsResponse, Error>) -> Void) {
        createRequest(
            with: URL(string: Constants.baseAPIURL + "/playlists/" + playlist.id),
            type: .GET
        ) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.faileedToGetData))
                    return
                }

                do {
                    let result = try JSONDecoder().decode(PlaylistDetailsResponse.self, from: data)
                    completion(.success(result))
                }
                catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    public func togglePlayback(completion: @escaping (Bool) -> Void) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/me/player/pause"), type: .PUT) { request in
            let task = URLSession.shared.dataTask(with: request) { _, response, error in
                completion(error == nil)
            }
            task.resume()
        }
    }

    public func skipToNext(completion: @escaping (Bool) -> Void) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/me/player/next"), type: .POST) { request in
            let task = URLSession.shared.dataTask(with: request) { _, _, error in
                completion(error == nil)
            }
            task.resume()
        }
    }

    public func skipToPrevious(completion: @escaping (Bool) -> Void) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/me/player/previous"), type: .POST) { request in
            let task = URLSession.shared.dataTask(with: request) { _, _, error in
                completion(error == nil)
            }
            task.resume()
        }
    }
    public func resumePlayback(completion: @escaping (Bool) -> Void) {
        let url = URL(string: Constants.baseAPIURL + "/me/player/play")
        
        createRequest(with: url, type: .PUT) { request in
            var request = request
            request.httpBody = nil // önceki çalanı devam ettir
            
            let task = URLSession.shared.dataTask(with: request) { _, response, error in
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(false)
                    return
                }
                print("🔁 Resume playback HTTP status: \(httpResponse.statusCode)")
                completion(httpResponse.statusCode == 204) // 204 No Content = Başarılı
            }
            task.resume()
        }
    }
    public func getCurrentUserPlaylists(completion: @escaping (Result<[Playlist], Error>) -> Void) {
        // Market parametresi ekleyerek ve daha detaylı loglama yaparak sorunu tespit edelim
        let urlString = Constants.baseAPIURL + "/me/playlists?limit=50&market=US"
        print("🔍 DEBUG: getCurrentUserPlaylists - URL: \(urlString)")
        
        createRequest(
            with: URL(string: urlString),
            type: .GET
        ) { request in
            // Debug için headers görüntüleme
            print("📍 DEBUG: getCurrentUserPlaylists - Headers: \(request.allHTTPHeaderFields ?? [:])")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                // HTTP response kodunu kontrol et
                if let httpResponse = response as? HTTPURLResponse {
                    print("📍 DEBUG: getCurrentUserPlaylists - HTTP Status: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 401 {
                        print("⚠️ DEBUG: getCurrentUserPlaylists - Unauthorized! Token geçersiz veya süresi dolmuş olabilir.")
                        
                        // Token yenileme dene ve tekrar istek at
                        AuthManager.shared.refreshIfNeeded { success in
                            if success {
                                print("✅ DEBUG: getCurrentUserPlaylists - Token yenilendi, istek tekrarlanıyor")
                                // Yeni token ile recursively aynı işlevi çağır
                                self.getCurrentUserPlaylists(completion: completion)
                            } else {
                                print("❌ DEBUG: getCurrentUserPlaylists - Token yenilenemedi!")
                                completion(.failure(APIError.faileedToGetData))
                            }
                        }
                        return
                    }
                    
                    if httpResponse.statusCode == 404 {
                        print("⚠️ DEBUG: getCurrentUserPlaylists - Not Found! API adresi veya parametreler yanlış olabilir.")
                    }
                }
                
                // Hata kontrolü
                if let error = error {
                    print("❌ DEBUG: getCurrentUserPlaylists - Network error: \(error.localizedDescription)")
                    completion(.failure(APIError.faileedToGetData))
                    return
                }
                
                guard let data = data, error == nil else {
                    print("❌ DEBUG: getCurrentUserPlaylists - Veri yok")
                    completion(.failure(APIError.faileedToGetData))
                    return
                }
                
                // JSON yanıtını kontrol et
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📊 DEBUG: getCurrentUserPlaylists - JSON Yanıt: \(jsonString.prefix(200))...")
                }

                do {
                    let result = try JSONDecoder().decode(LibraryPlaylistsResponse.self, from: data)
                    print("✅ DEBUG: getCurrentUserPlaylists - Başarılı: \(result.items.count) playlist alındı")
                    completion(.success(result.items))
                }
                catch {
                    print("❌ DEBUG: getCurrentUserPlaylists - JSON decode hatası: \(error.localizedDescription)")
                    print(error)
                    
                    // API yanıt formatını görelim
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("📊 DEBUG: getCurrentUserPlaylists - Hata detay: \(json)")
                    }
                    
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }

    public func createPlaylist(with name: String, completion: @escaping (Bool) -> Void) {
        getCurrentUserProfile { [weak self] result in
            switch result {
            case .success(let profile):
                let urlString = Constants.baseAPIURL + "/users/\(profile.id)/playlists"
                print(urlString)
                self?.createRequest(with: URL(string: urlString), type: .POST) { baseRequest in
                    var request = baseRequest
                    let json = [
                        "name": name
                    ]
                    request.httpBody = try? JSONSerialization.data(withJSONObject: json, options: .fragmentsAllowed)
                    print("Starting creation...")
                    let task = URLSession.shared.dataTask(with: request) { data, _, error in
                        guard let data = data, error == nil else {
                            completion(false)
                            return
                        }

                        do {
                            let result = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                            if let response = result as? [String: Any], response["id"] as? String != nil {
                                completion(true)
                            }
                            else {
                                completion(false)
                            }
                        }
                        catch {
                            print(error.localizedDescription)
                            completion(false)
                        }
                    }
                    task.resume()
                }

            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }

    public func addTrackToPlaylist(
        track: AudioTrack,
        playlist: Playlist,
        completion: @escaping (Bool) -> Void
    ) {
        createRequest(
            with: URL(string: Constants.baseAPIURL + "/playlists/\(playlist.id)/tracks"),
            type: .POST
        ) { baseRequest in
            var request = baseRequest
            let json = [
                "uris": [
                    "spotify:track:\(track.id)"
                ]
            ]
            print(json)
            request.httpBody = try? JSONSerialization.data(withJSONObject: json, options: .fragmentsAllowed)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            print("Adding...")
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else{
                    completion(false)
                    return
                }

                do {
                    let result = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                        print(result)
                    if let response = result as? [String: Any],
                       response["snapshot_id"] as? String != nil {
                        completion(true)
                    }
                    else {
                        completion(false)
                    }
                }
                catch {
                    completion(false)
                }
            }
            task.resume()
        }
    }

    public func removeTrackFromPlaylist(
        track: AudioTrack,
        playlist: Playlist,
        completion: @escaping (Bool) -> Void
    ) {
        createRequest(
            with: URL(string: Constants.baseAPIURL + "/playlists/\(playlist.id)/tracks"),
            type: .DELETE
        ) { baseRequest in
            var request = baseRequest
            let json: [String: Any] = [
                "tracks": [
                    [
                        "uri": "spotify:track:\(track.id)"
                    ]
                ]
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: json, options: .fragmentsAllowed)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else{
                    completion(false)
                    return
                }

                do {
                    let result = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                    if let response = result as? [String: Any],
                       response["snapshot_id"] as? String != nil {
                        completion(true)
                    }
                    else {
                        completion(false)
                    }
                }
                catch {
                    completion(false)
                }
            }
            task.resume()
        }
    }

    // MARK: - Profile

    public func getCurrentUserProfile(completion: @escaping (Result<UserProfile, Error>) -> Void) {
        createRequest(
            with: URL(string: Constants.baseAPIURL + "/me"),
            type: .GET
        ) { baseRequest in
            let task = URLSession.shared.dataTask(with: baseRequest) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.faileedToGetData))
                    return
                }

                do {
                    let result = try JSONDecoder().decode(UserProfile.self, from: data)
                    completion(.success(result))
                }
                catch {
                    print(error.localizedDescription)
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }

    // MARK: - Browse

    public func getNewReleases(completion: @escaping ((Result<NewReleasesResponse, Error>)) -> Void) {
        let urlString = Constants.baseAPIURL + "/browse/new-releases?limit=50&market=US"
        print("🔍 DEBUG: getNewReleases URL: \(urlString)")
        
        createRequest(with: URL(string: urlString), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                
                // Eğer token süresi dolmuşsa (401 Unauthorized)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                    print("⚠️ DEBUG: getNewReleases - Unauthorized! Token geçersiz olabilir. Yenileniyor...")

                    AuthManager.shared.refreshIfNeeded { success in
                        if success {
                            print("✅ DEBUG: getNewReleases - Token yenilendi. Tekrar deneniyor...")
                            self?.getNewReleases(completion: completion)
                        } else {
                            print("❌ DEBUG: getNewReleases - Token yenileme başarısız!")
                            completion(.failure(APIError.faileedToGetData))
                        }
                    }
                    return
                }

                // Diğer HTTP response logları
                if let httpResponse = response as? HTTPURLResponse {
                    print("📍 DEBUG: getNewReleases HTTP Status: \(httpResponse.statusCode)")
                    print("📍 DEBUG: getNewReleases URL: \(request.url?.absoluteString ?? "none")")
                    print("📍 DEBUG: getNewReleases Headers: \(httpResponse.allHeaderFields)")
                }

                guard let data = data, error == nil else {
                    completion(.failure(APIError.faileedToGetData))
                    return
                }

                // Print raw JSON data
                if let jsonString = self?.prettyPrintJSON(data: data) {
                    print("📊 NEW RELEASES RAW JSON: \(jsonString)")
                }

                do {
                    let result = try JSONDecoder().decode(NewReleasesResponse.self, from: data)
                    completion(.success(result))
                } catch {
                    print("❌ NEW RELEASES DECODE ERROR: \(error)")
                    if let errorJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("📊 NEW RELEASES ERROR DETAILS: \(errorJson)")
                    }
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    public func getFeaturedFlaylists(completion: @escaping ((Result<FeaturedPlaylistsResponse, Error>) -> Void)) {
        let urlString = Constants.baseAPIURL + "/browse/featured-playlists?country=US&locale=en_US&limit=10"

        createRequest(with: URL(string: urlString), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.faileedToGetData))
                    return
                }

                // Yanıt HTTP kodunu kontrol et
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("❌ FEATURED PLAYLISTS API HATASI: \(jsonString)")
                    }
                    completion(.failure(APIError.faileedToGetData))
                    return
                }

                do {
                    let result = try JSONDecoder().decode(FeaturedPlaylistsResponse.self, from: data)
                    completion(.success(result))
                } catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    public func getCategoryPlaylists(categoryId: String, completion: @escaping (Result<[Playlist], Error>) -> Void) {
        let urlString = Constants.baseAPIURL + "/browse/categories/\(categoryId)/playlists?limit=10&market=US"
        createRequest(with: URL(string: urlString), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.faileedToGetData))
                    return
                }

                do {
                    let result = try JSONDecoder().decode(CategoryPlaylistsResponse.self, from: data)
                    completion(.success(result.playlists.items))
                } catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    public func getRecommendations(genres: Set<String>, completion: @escaping ((Result<RecommendationsResponse, Error>) -> Void)) {
        // URL encode uygulanmış genre string'i
        let encodedGenres = genres.joined(separator: ",").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // Spotify API minimum seed gereksinimleri:
        // seed_artists, seed_tracks veya seed_genres'den en az biri gerekli
        // Biz basit olması için sabit seed_artists ve seed_genres kullanıyoruz
        
        // Popüler bir Spotify artist ID (Drake)
        let seedArtist = "3TVXtAsR1Inumwj472S9r4"
        
        let urlString = Constants.baseAPIURL + "/recommendations?limit=20&market=US&seed_artists=\(seedArtist)&seed_genres=\(encodedGenres)"
        print("🔍 DEBUG: getRecommendations URL: \(urlString)")
        
        createRequest(
            with: URL(string: urlString),
            type: .GET
        ) { request in
            // URL'yi ekrana yazdır, debug için
            print("📍 DEBUG: Tam URL: \(request.url?.absoluteString ?? "URL yok")")
            print("📍 DEBUG: Headers: \(request.allHTTPHeaderFields ?? [:])")
            
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                // HTTP Response detaylı logging
                if let httpResponse = response as? HTTPURLResponse {
                    print("📍 DEBUG: getRecommendations HTTP Status: \(httpResponse.statusCode)")
                    print("📍 DEBUG: getRecommendations URL: \(request.url?.absoluteString ?? "none")")
                    print("📍 DEBUG: getRecommendations Headers: \(httpResponse.allHeaderFields)")
                }
                
                guard let data = data, error == nil else {
                    print("❌ DEBUG: getRecommendations veri yok veya hata var: \(error?.localizedDescription ?? "unknown")")
                    completion(.failure(APIError.faileedToGetData))
                    return
                }
                
                // Boş data kontrolü
                guard data.count > 0 else {
                    print("❌ DEBUG: getRecommendations boş veri döndü!")
                    completion(.failure(APIError.faileedToGetData))
                    return
                }

                // Print raw JSON data
                if let jsonString = self?.prettyPrintJSON(data: data) {
                    print("📊 RECOMMENDATIONS RAW JSON: \(jsonString)")
                }

                do {
                    let result = try JSONDecoder().decode(RecommendationsResponse.self, from: data)
                    completion(.success(result))
                }
                catch {
                    print("❌ RECOMMENDATIONS DECODE ERROR: \(error)")
                    // Try to parse any additional error info from the response
                    if let errorJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("📊 RECOMMENDATIONS ERROR DETAILS: \(errorJson)")
                    }
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }

    public func gerRecommendedGenres(completion: @escaping ((Result<RecommendedGenresResponse, Error>) -> Void)) {
        createRequest(
            with: URL(string: Constants.baseAPIURL + "/recommendations/available-genre-seeds"),
            type: .GET
        ) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.faileedToGetData))
                    return
                }

                do {
                    let result = try JSONDecoder().decode(RecommendedGenresResponse.self, from: data)
                    completion(.success(result))
                }
                catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }

    // MARK: - Category

    public func getCategories(completion: @escaping (Result<[Category], Error>) -> Void) {
        createRequest(
            with: URL(string: Constants.baseAPIURL + "/browse/categories?limit=50"),
            type: .GET
        ) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else{
                    completion(.failure(APIError.faileedToGetData))
                    return
                }

                do {
                    let result = try JSONDecoder().decode(AllCategoriesResponse.self,
                                                          from: data)
                    completion(.success(result.categories.items))
                }
                catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }

    public func getCategoryPlaylists(category: Category, completion: @escaping (Result<[Playlist], Error>) -> Void) {
        let urlString = Constants.baseAPIURL + "/browse/categories/\(category.id)/playlists?limit=50&market=US"
        print("🔍 DEBUG: getCategoryPlaylists - URL: \(urlString)")
        
        createRequest(
            with: URL(string: urlString),
            type: .GET
        ) { request in
            print("📍 DEBUG: getCategoryPlaylists - Headers: \(request.allHTTPHeaderFields ?? [:])")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                // HTTP Response detaylı logging
                if let httpResponse = response as? HTTPURLResponse {
                    print("📍 DEBUG: getCategoryPlaylists HTTP Status: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 401 {
                        print("⚠️ DEBUG: getCategoryPlaylists - Unauthorized! Token yenileniyor...")
                        AuthManager.shared.refreshIfNeeded { success in
                            if success {
                                print("✅ DEBUG: getCategoryPlaylists - Token yenilendi, istek tekrarlanıyor")
                                self.getCategoryPlaylists(category: category, completion: completion)
                            } else {
                                print("❌ DEBUG: getCategoryPlaylists - Token yenilenemedi!")
                                completion(.failure(APIError.faileedToGetData))
                            }
                        }
                        return
                    }
                    
                    if httpResponse.statusCode == 404 {
                        print("⚠️ DEBUG: getCategoryPlaylists - Kategori bulunamadı veya playlist yok!")
                        completion(.success([]))
                        return
                    }
                }

                if let error = error {
                    print("❌ DEBUG: getCategoryPlaylists - Network error: \(error)")
                    completion(.failure(error))
                    return
                }

                guard let data = data, data.count > 0 else {
                    print("❌ DEBUG: getCategoryPlaylists - Veri yok veya boş")
                    completion(.failure(APIError.faileedToGetData))
                    return
                }

                // JSON yanıtını kontrol et
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📊 DEBUG: getCategoryPlaylists - JSON Response:\n\(jsonString)")
                }

                do {
                    let result = try JSONDecoder().decode(CategoryPlaylistsResponse.self, from: data)
                    print("✅ DEBUG: getCategoryPlaylists - Başarılı decode: \(result.playlists.items.count) playlist")
                    completion(.success(result.playlists.items))
                }
                catch {
                    print("❌ DEBUG: getCategoryPlaylists - Decode error: \(error)")
                    print("❌ DEBUG: getCategoryPlaylists - Detailed error: \(String(describing: error))")
                    
                    // API yanıt formatını görelim
                    if let errorJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("📊 DEBUG: getCategoryPlaylists - Error Response: \(errorJson)")
                    }
                    
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }

    // MARK: - Search

    public func search(with query: String, completion: @escaping (Result<[SearchResult], Error>) -> Void) {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlStr = Constants.baseAPIURL + "/search?limit=10&type=album,artist,playlist,track&q=\(encodedQuery)&market=US"
        print("🔍 DEBUG: Search URL = \(urlStr)")

        createRequest(
            with: URL(string: urlStr),
            type: .GET
        ) { request in
            print("📍 DEBUG: Search Headers = \(request.allHTTPHeaderFields ?? [:])")

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                // HTTP Response detaylı logging
                if let httpResponse = response as? HTTPURLResponse {
                    print("📍 DEBUG: Search HTTP Status: \(httpResponse.statusCode)")
                    if httpResponse.statusCode == 401 {
                        print("⚠️ DEBUG: Search - Unauthorized! Token geçersiz olabilir.")
                        // Token yenileme dene
                        AuthManager.shared.refreshIfNeeded { success in
                            if success {
                                print("✅ DEBUG: Search - Token yenilendi, istek tekrarlanıyor")
                                // Yeni token ile tekrar dene
                                self.search(with: query, completion: completion)
                            } else {
                                print("❌ DEBUG: Search - Token yenilenemedi!")
                                completion(.failure(APIError.faileedToGetData))
                            }
                        }
                        return
                    }
                }

                if let error = error {
                    print("❌ DEBUG: Search API error = \(error)")
                    completion(.failure(error))
                    return
                }

                guard let data = data, data.count > 0 else {
                    print("❌ DEBUG: Search API no data or empty data")
                    completion(.failure(APIError.faileedToGetData))
                    return
                }

                // JSON verisini detaylı yazdır
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📊 DEBUG: Search Raw JSON Response:\n\(jsonString)")
                }

                do {
                    let result = try JSONDecoder().decode(SearchResultsResponse.self, from: data)
                    print("✅ DEBUG: Successfully decoded SearchResultsResponse")
                    print("📊 DEBUG: Tracks count: \(result.tracks.items.count)")
                    print("📊 DEBUG: Albums count: \(result.albums.items.count)")
                    print("📊 DEBUG: Artists count: \(result.artists.items.count)")
                    print("📊 DEBUG: Playlists count: \(result.playlists.items.count)")
                    
                    var searchResults: [SearchResult] = []
                    searchResults.append(contentsOf: result.tracks.items.compactMap { .track(model: $0) })
                    searchResults.append(contentsOf: result.albums.items.compactMap { .album(model: $0) })
                    searchResults.append(contentsOf: result.artists.items.compactMap { .artist(model: $0) })
                    searchResults.append(contentsOf: result.playlists.items.compactMap { .playlist(model: $0) })
                    
                    print("✅ DEBUG: Total search results: \(searchResults.count)")
                    completion(.success(searchResults))
                } catch {
                    print("❌ DEBUG: JSON Decode error: \(error)")
                    print("❌ DEBUG: Detailed error: \(String(describing: error))")
                    
                    // Try to parse error response
                    if let errorJson = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("📊 DEBUG: Error Response: \(errorJson)")
                    }
                    
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }

    // MARK: - Private

    enum HTTPMethod: String {
        case GET
        case PUT
        case POST
        case DELETE
    }

    private func createRequest(
        with url: URL?,
        type: HTTPMethod,
        completion: @escaping (URLRequest) -> Void
    ) {
        AuthManager.shared.withValidToken { token in
            guard let apiURL = url else {
                print("❌ DEBUG: createRequest - URL oluşturulamadı")
                return
            }
            
            // Log token bilgisini (ilk 10 karakteri güvenlik için)
            if let tokenPrefix = token.isEmpty ? nil : String(token.prefix(10)) {
                print("🔑 DEBUG: createRequest - Token kullanılıyor: \(tokenPrefix)...")
            } else {
                print("⚠️ DEBUG: createRequest - Token NULL veya EMPTY!")
            }
            
            var request = URLRequest(url: apiURL)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpMethod = type.rawValue
            request.timeoutInterval = 30
            
            print("🌐 DEBUG: createRequest - \(type.rawValue) request oluşturuldu: \(apiURL.absoluteString)")
            completion(request)
        }
    }
    private func prettyPrintJSON(data: Data) -> String? {
        do {
            let object = try JSONSerialization.jsonObject(with: data, options: [])
            let prettyData = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted])
            return String(data: prettyData, encoding: .utf8)
        } catch {
            print("❌ JSON Pretty Print Error: \(error)")
            return nil
        }
    }
    // MARK: - JSON Helper
    
    /// Converts JSON data to a pretty-printed string for easier debugging
  
}
