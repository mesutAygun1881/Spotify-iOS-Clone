//
//  Artist.swift
//  Spotify
//
//  Created by Mesut Aygun on 2/14/21.
//

import Foundation

struct Artist: Codable {
    let id: String
    let name: String
    let type: String
    let images: [APIImage]
    let external_urls: [String: String]

    enum CodingKeys: String, CodingKey {
        case id, name, type, images, external_urls
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unknown Artist"
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "artist"
        images = try container.decodeIfPresent([APIImage].self, forKey: .images) ?? []
        external_urls = try container.decodeIfPresent([String: String].self, forKey: .external_urls) ?? [:]
    }
}
