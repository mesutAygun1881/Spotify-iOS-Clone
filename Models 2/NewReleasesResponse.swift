//
//  NewReleasesResponse.swift
//  Spotify
//
//  Created by Mesut Aygun on 2/15/21.
//

import Foundation

struct NewReleasesResponse: Codable {
    let albums: AlbumsResponse
}

struct AlbumsResponse: Codable {
    let items: [Album]
}

struct Album: Codable {
    let album_type: String
    let available_markets: [String]
    let id: String
    var images: [APIImage]
    let name: String
    let release_date: String
    let total_tracks: Int
    let artists: [Artist]

    enum CodingKeys: String, CodingKey {
        case album_type
        case available_markets
        case id
        case images
        case name
        case release_date
        case total_tracks
        case artists
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        album_type = try container.decodeIfPresent(String.self, forKey: .album_type) ?? "unknown"
        available_markets = try container.decodeIfPresent([String].self, forKey: .available_markets) ?? []
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        images = try container.decodeIfPresent([APIImage].self, forKey: .images) ?? []
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Untitled"
        release_date = try container.decodeIfPresent(String.self, forKey: .release_date) ?? "-"
        total_tracks = try container.decodeIfPresent(Int.self, forKey: .total_tracks) ?? 0
        artists = try container.decodeIfPresent([Artist].self, forKey: .artists) ?? []
    }
}
