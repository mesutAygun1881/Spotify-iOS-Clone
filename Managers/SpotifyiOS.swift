import Foundation
import UIKit

/// This is a mock implementation of the SpotifyiOS SDK for development and testing
/// For production, replace this file with the real SpotifyiOS.framework

// MARK: - SPTAppRemote

class SPTAppRemote: NSObject {
    var isConnected: Bool
    weak var delegate: SPTAppRemoteDelegate?
    var connectionParameters: SPTAppRemoteConnectionParameters
    var playerAPI: SPTAppRemotePlayerAPI?
    var contentAPI: SPTAppRemoteContentAPI?
    var imageAPI: SPTAppRemoteImageAPI?
    
    init(configuration: SPTConfiguration, logLevel: Int) {
        self.isConnected = false
        self.connectionParameters = SPTAppRemoteConnectionParameters()
        self.playerAPI = SPTAppRemotePlayerAPI()
        self.contentAPI = SPTAppRemoteContentAPI()
        self.imageAPI = SPTAppRemoteImageAPI()
        super.init()
    }
    
    func connect() {
        // Simulating connection to Spotify
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isConnected = true
            self?.delegate?.appRemoteDidEstablishConnection(self!)
        }
    }
    
    func disconnect() {
        isConnected = false
        delegate?.appRemote(self, didDisconnectWithError: nil)
    }
    
    func handleAuthCallback(withURL url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        // Mock implementation
        return true
    }
}

// MARK: - SPTConfiguration

class SPTConfiguration: NSObject {
    var clientID: String
    var redirectURL: URL
    
    init(clientID: String, redirectURL: URL) {
        self.clientID = clientID
        self.redirectURL = redirectURL
        super.init()
    }
}

// MARK: - SPTAppRemoteConnectionParameters

class SPTAppRemoteConnectionParameters: NSObject {
    var accessToken: String?
}

// MARK: - SPTAppRemoteDelegate

protocol SPTAppRemoteDelegate: AnyObject {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote)
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?)
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?)
}

// MARK: - SPTAppRemotePlayerState

class SPTAppRemotePlayerState: NSObject {
    var track: SPTAppRemoteTrack
    var playbackPosition: TimeInterval
    var playbackSpeed: Double
    var isPaused: Bool
    var playbackOptions: SPTAppRemotePlaybackOptions
    var repeatMode: Int
    var shuffleMode: Int
    
    init(trackData: [String: String]) {
        self.track = SPTAppRemoteTrack(trackData: trackData)
        self.playbackPosition = 0
        self.playbackSpeed = 1.0
        self.isPaused = false
        self.playbackOptions = SPTAppRemotePlaybackOptions()
        self.repeatMode = 0
        self.shuffleMode = 0
        super.init()
    }
    
    // Create a mock player state to display sample data
    static func mockPlayerState() -> SPTAppRemotePlayerState {
        return SPTAppRemotePlayerState(trackData: [
            "name": "Shape of You",
            "artist": "Ed Sheeran",
            "album": "÷ (Divide)"
        ])
    }
}

// MARK: - SPTAppRemoteTrack

class SPTAppRemoteTrack: NSObject {
    var name: String
    var artist: SPTAppRemoteArtist
    var album: SPTAppRemoteAlbum
    var duration: TimeInterval
    var imageIdentifier: String?
    var URI: String
    
    init(trackData: [String: String]) {
        self.name = trackData["name"] ?? "Unknown Track"
        self.artist = SPTAppRemoteArtist(name: trackData["artist"] ?? "Unknown Artist")
        self.album = SPTAppRemoteAlbum(name: trackData["album"] ?? "Unknown Album")
        self.duration = 180
        self.URI = "spotify:track:mocktrack"
        super.init()
    }
}

// MARK: - SPTAppRemoteArtist

class SPTAppRemoteArtist: NSObject {
    var name: String
    var URI: String
    
    init(name: String) {
        self.name = name
        self.URI = "spotify:artist:mockartist"
        super.init()
    }
}

// MARK: - SPTAppRemoteAlbum

class SPTAppRemoteAlbum: NSObject {
    var name: String
    var URI: String
    
    init(name: String) {
        self.name = name
        self.URI = "spotify:album:mockalbum"
        super.init()
    }
}

// MARK: - SPTAppRemotePlaybackOptions

class SPTAppRemotePlaybackOptions: NSObject {
    var isShuffling: Bool
    var repeatMode: Int
    
    override init() {
        self.isShuffling = false
        self.repeatMode = 0
        super.init()
    }
}

// MARK: - SPTAppRemotePlayerAPI

class SPTAppRemotePlayerAPI: NSObject {
    func getPlayerState(callback: @escaping (Any?, Error?) -> Void) {
        // Return a mock player state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            callback(SPTAppRemotePlayerState.mockPlayerState(), nil)
        }
    }
    
    func getPlayerQueue(callback: @escaping (Any?, Error?) -> Void) {
        // Return a mock queue
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let queue = SPTAppRemoteQueue()
            callback(queue, nil)
        }
    }
}

// MARK: - SPTAppRemoteQueue

class SPTAppRemoteQueue: NSObject {
    var tracks: [SPTAppRemoteTrack] {
        return [
            SPTAppRemoteTrack(trackData: ["name": "Perfect", "artist": "Ed Sheeran", "album": "÷ (Divide)"]),
            SPTAppRemoteTrack(trackData: ["name": "Castle on the Hill", "artist": "Ed Sheeran", "album": "÷ (Divide)"]),
            SPTAppRemoteTrack(trackData: ["name": "Galway Girl", "artist": "Ed Sheeran", "album": "÷ (Divide)"]),
            SPTAppRemoteTrack(trackData: ["name": "Dive", "artist": "Ed Sheeran", "album": "÷ (Divide)"]),
            SPTAppRemoteTrack(trackData: ["name": "Happier", "artist": "Ed Sheeran", "album": "÷ (Divide)"])
        ]
    }
}

// MARK: - SPTAppRemoteContentAPI

class SPTAppRemoteContentAPI: NSObject {
    func fetchContentItem(forURI URI: String, callback: @escaping (Any?, Error?) -> Void) {
        // Mock implementation
        callback(nil, nil)
    }
}

// MARK: - SPTAppRemoteImageAPI

class SPTAppRemoteImageAPI: NSObject {
    func fetchImage(forItem item: SPTAppRemoteTrack, with size: CGSize, callback: @escaping (UIImage?, Error?) -> Void) {
        // Return a placeholder image
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            callback(UIImage(systemName: "music.note"), nil)
        }
    }
} 