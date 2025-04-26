//
//  Playlist.swift
//  Spotify
//
//  Created by Mesut Aygun on 2/14/21.
//

import Foundation

struct Playlist: Codable {
    let description: String?
    let external_urls: [String: String]
    let id: String
    let images: [APIImage]
    let name: String
    let owner: User

    enum CodingKeys: String, CodingKey {
        case description
        case external_urls
        case id
        case images
        case name
        case owner
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        description = try? container.decodeIfPresent(String.self, forKey: .description)
        external_urls = try container.decode([String: String].self, forKey: .external_urls)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        owner = try container.decode(User.self, forKey: .owner)

        // Önemli kısım: null ise [] ver
        images = (try? container.decode([APIImage].self, forKey: .images)) ?? []
    }
}
