//
//  AllModels.swift
//  Spotify
//
//  Created by Mesut Aygun on 5/16/24.
//

import Foundation
import UIKit

// MARK: - SearchResult

enum SearchResult {
    case artist(model: Artist)
    case album(model: Album)
    case track(model: AudioTrack)
    case playlist(model: Playlist)
}

struct SearchSection {
    let title: String
    let results: [SearchResult]
}

// MARK: - Responses

struct PlaylistResponse: Codable {
    let href: String?
    let limit: Int?
    let next: String?
    let offset: Int?
    let previous: String?
    let total: Int?
    let items: [Playlist]
    
    init(href: String?, limit: Int?, next: String?, offset: Int?, previous: String?, total: Int?, items: [Playlist]) {
        self.href = href
        self.limit = limit
        self.next = next
        self.offset = offset
        self.previous = previous
        self.total = total
        self.items = items
    }
    
    init(from decoder: Decoder) throws {
        print("🔍 DEBUG: PlaylistResponse decode ediliyor...")
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.href = try container.decodeIfPresent(String.self, forKey: .href)
            self.limit = try container.decodeIfPresent(Int.self, forKey: .limit)
            self.next = try container.decodeIfPresent(String.self, forKey: .next)
            self.offset = try container.decodeIfPresent(Int.self, forKey: .offset)
            self.previous = try container.decodeIfPresent(String.self, forKey: .previous)
            self.total = try container.decodeIfPresent(Int.self, forKey: .total)
            self.items = try container.decode([Playlist].self, forKey: .items)
            print("✅ DEBUG: PlaylistResponse başarıyla decode edildi, \(items.count) playlist")
        } catch {
            print("❌ DEBUG: PlaylistResponse decode hatası: \(error)")
            
            // Playlist items çözümlenemezse
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, _):
                    if key.stringValue == "items" {
                        print("⚠️ DEBUG: Playlist items anahtarı bulunamadı, boş liste kullanılıyor")
                        self.href = nil
                        self.limit = nil
                        self.next = nil
                        self.offset = nil
                        self.previous = nil
                        self.total = nil
                        self.items = []
                        return
                    }
                case .typeMismatch(_, let context):
                    if context.codingPath.last?.stringValue == "items" {
                        print("⚠️ DEBUG: Playlist items tip uyuşmazlığı, boş liste kullanılıyor")
                        self.href = nil
                        self.limit = nil
                        self.next = nil
                        self.offset = nil
                        self.previous = nil
                        self.total = nil
                        self.items = []
                        return
                    }
                case .valueNotFound(_, let context):
                    if context.codingPath.last?.stringValue == "items" {
                        print("⚠️ DEBUG: Playlist items değeri bulunamadı, boş liste kullanılıyor")
                        self.href = nil
                        self.limit = nil
                        self.next = nil
                        self.offset = nil
                        self.previous = nil
                        self.total = nil
                        self.items = []
                        return
                    }
                case .dataCorrupted(let context):
                    if context.codingPath.last?.stringValue == "items" {
                        print("⚠️ DEBUG: Playlist items verisi bozuk, boş liste kullanılıyor")
                        self.href = nil
                        self.limit = nil
                        self.next = nil
                        self.offset = nil
                        self.previous = nil
                        self.total = nil
                        self.items = []
                        return
                    }
                @unknown default:
                    break
                }
            }
            
            throw error
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case href, limit, next, offset, previous, total, items
    }
}

// ... [Diğer model kodları buraya devam edeceğini varsayalım] ...

// MARK: - View Models

// New Releases Cell ViewModel
struct NewReleasesCellViewModel {
    let name: String
    let artworkURL: URL?
    let numberOfTracks: Int
    let artistName: String
}

// Featured Playlist Cell ViewModel
struct FeaturedPlaylistCellViewModel {
    let name: String
    let artworkURL: URL?
    let creatorName: String
}

// Recommended Track Cell ViewModel
struct RecommendedTrackCellViewModel {
    let name: String
    let artistName: String
    let artworkURL: URL?
}

// MARK: - Common Models

// APIImage Model
struct APIImage: Codable {
    let url: String
    let height: Int?
    let width: Int?
}

// User Model
struct User: Codable {
    let display_name: String
    let external_urls: [String: String]
    let id: String
}

// Playlist Model
struct Playlist: Codable {
    let description: String?
    let external_urls: [String: String]
    let id: String
    let images: [APIImage]?
    let name: String
    let owner: User
    let public_access: Bool?
    let collaborative: Bool?
    let tracks: PlaylistTracksInfo?
    
    enum CodingKeys: String, CodingKey {
        case description, external_urls, id, images, name, owner
        case public_access = "public"
        case collaborative, tracks
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        description = try container.decodeIfPresent(String.self, forKey: .description)
        external_urls = try container.decode([String: String].self, forKey: .external_urls)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        owner = try container.decode(User.self, forKey: .owner)
        public_access = try container.decodeIfPresent(Bool.self, forKey: .public_access)
        collaborative = try container.decodeIfPresent(Bool.self, forKey: .collaborative)
        tracks = try container.decodeIfPresent(PlaylistTracksInfo.self, forKey: .tracks)
        
        // images null olabilir, bu durumda boş array kullan
        if let imagesData = try? container.decode([APIImage].self, forKey: .images) {
            images = imagesData
        } else {
            print("⚠️ DEBUG: Playlist için images null, boş array kullanılıyor")
            images = []
        }
    }
}

struct PlaylistTracksInfo: Codable {
    let href: String?
    let total: Int?
}

// Artist Model
struct Artist: Codable {
    let id: String
    let name: String
    let type: String
    let images: [APIImage]?
    let external_urls: [String: String]
}

// Album Model
struct Album: Codable {
    let album_type: String
    let available_markets: [String]
    let id: String
    var images: [APIImage]
    let name: String
    let release_date: String
    let total_tracks: Int
    let artists: [Artist]
}

// AudioTrack Model
struct AudioTrack: Codable {
    var album: Album?
    let artists: [Artist]
    let available_markets: [String]
    let disc_number: Int
    let duration_ms: Int
    let explicit: Bool
    let external_urls: [String: String]
    let id: String
    let name: String
    let preview_url: String?
}

// MARK: - API Response Models

// FeaturedPlaylistsResponse
struct FeaturedPlaylistsResponse: Codable {
    let message: String?
    let playlists: PlaylistResponse
    
    init(from decoder: Decoder) throws {
        print("🔍 DEBUG: FeaturedPlaylistsResponse decode ediliyor...")
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.message = try container.decodeIfPresent(String.self, forKey: .message)
            self.playlists = try container.decode(PlaylistResponse.self, forKey: .playlists)
            print("✅ DEBUG: FeaturedPlaylistsResponse başarıyla decode edildi")
        } catch {
            print("❌ DEBUG: FeaturedPlaylistsResponse decode hatası: \(error)")
            throw error
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case message, playlists
    }
}

// CategoryPlaylistsResponse
struct CategoryPlaylistsResponse: Codable {
    let playlists: PlaylistResponse
}

// RecommendedGenresResponse
struct RecommendedGenresResponse: Codable {
    let genres: [String]
}

// RecommendationsResponse
struct RecommendationsResponse: Codable {
    let tracks: [AudioTrack]
    let seeds: [RecommendationSeed]
}

struct RecommendationSeed: Codable {
    let afterFilteringSize: Int
    let afterRelinkingSize: Int
    let href: String?
    let id: String
    let initialPoolSize: Int
    let type: String
}

// NewReleasesResponse
struct NewReleasesResponse: Codable {
    let albums: AlbumsResponse
    
    init(from decoder: Decoder) throws {
        print("🔍 DEBUG: NewReleasesResponse decode ediliyor...")
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.albums = try container.decode(AlbumsResponse.self, forKey: .albums)
            print("✅ DEBUG: NewReleasesResponse başarıyla decode edildi")
        } catch {
            print("❌ DEBUG: NewReleasesResponse decode hatası: \(error)")
            throw error
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case albums
    }
}

struct AlbumsResponse: Codable {
    let href: String
    let limit: Int
    let next: String?
    let offset: Int
    let previous: String?
    let total: Int?  // Changed to optional to handle missing 'total' field
    let items: [Album]
    
    init(from decoder: Decoder) throws {
        print("🔍 DEBUG: AlbumsResponse decode ediliyor...")
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.href = try container.decode(String.self, forKey: .href)
            self.limit = try container.decode(Int.self, forKey: .limit)
            self.next = try container.decodeIfPresent(String.self, forKey: .next)
            self.offset = try container.decode(Int.self, forKey: .offset)
            self.previous = try container.decodeIfPresent(String.self, forKey: .previous)
            self.total = try container.decodeIfPresent(Int.self, forKey: .total)
            self.items = try container.decode([Album].self, forKey: .items)
            print("✅ DEBUG: AlbumsResponse başarıyla decode edildi, \(items.count) album")
        } catch {
            print("❌ DEBUG: AlbumsResponse decode hatası: \(error)")
            throw error
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case href, limit, next, offset, previous, total, items
    }
}

// Categories
struct AllCategoriesResponse: Codable {
    let categories: Categories
}

struct Categories: Codable {
    let items: [Category]
}

struct Category: Codable {
    let id: String
    let name: String
    let icons: [APIImage]
}

// Search Response
struct SearchResultsResponse: Codable {
    let albums: AlbumsResponse
    let artists: ArtistsResponse
    let playlists: PlaylistResponse
    let tracks: TracksResponse
}

struct ArtistsResponse: Codable {
    let items: [Artist]
}

struct TracksResponse: Codable {
    let items: [AudioTrack]
} 