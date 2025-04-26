import Foundation
import UIKit

class SpotifyAppRemoteManager: NSObject {
    static let shared = SpotifyAppRemoteManager()

    var appRemote: SPTAppRemote?
    private let clientID = AuthManager.shared.clientID
    private let redirectURI = URL(string: AuthManager.shared.redirectURI)!
    
    var isConnected: Bool {
        return appRemote?.isConnected ?? false
    }

    override init() {
        super.init()
        appRemote = SPTAppRemote(configuration: SPTConfiguration(clientID: clientID, redirectURL: redirectURI), logLevel: 0)
        appRemote?.delegate = self
    }

    func connect(accessToken: String) {
        appRemote?.connectionParameters.accessToken = accessToken
        appRemote?.connect()
    }

    func disconnect() {
        appRemote?.disconnect()
    }

    func fetchNowPlaying(completion: @escaping (SPTAppRemotePlayerState?) -> Void) {
        guard let playerAPI = appRemote?.playerAPI, isConnected else {
            // If not connected, return mock data for testing
            completion(SPTAppRemotePlayerState.mockPlayerState())
            return
        }

        playerAPI.getPlayerState { result, error in
            if let error = error {
                print("❌ Now Playing Error: \(error.localizedDescription)")
                completion(nil)
            } else if let playerState = result as? SPTAppRemotePlayerState {
                completion(playerState)
            } else {
                completion(nil)
            }
        }
    }
    
    func fetchQueue(completion: @escaping ([SPTAppRemoteTrack]?) -> Void) {
        guard let playerAPI = appRemote?.playerAPI, isConnected else {
            // Return mock data for testing
            let queue = SPTAppRemoteQueue()
            completion(queue.tracks)
            return
        }
        
        playerAPI.getPlayerQueue { result, error in
            if let error = error {
                print("❌ Queue Error: \(error.localizedDescription)")
                completion(nil)
            } else if let queue = result as? SPTAppRemoteQueue {
                completion(queue.tracks)
            } else {
                completion(nil)
            }
        }
    }
    
    func fetchPlaylist(for trackURI: String, completion: @escaping (String?) -> Void) {
        guard let contentAPI = appRemote?.contentAPI, isConnected else {
            completion("Mock Playlist")
            return
        }
        
        // This is a simplified approach - the actual implementation would depend on Spotify API's capabilities
        // In reality, you might need to fetch user's playlists and check if the track is in any of them
        completion("Current Playlist") // Placeholder
    }
}

extension SpotifyAppRemoteManager: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("✅ Connected to Spotify App Remote")
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("❌ Spotify App Remote connection failed: \(error?.localizedDescription ?? "No error")")
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("🔌 Disconnected from Spotify App Remote")
    }
} 