
import UIKit
import SpotifyiOS
import SDWebImage




final class ControlPlaybackViewController: UIViewController {
    
    private let albumImageView = UIImageView()
    private let trackLabel = UILabel()
    private let artistLabel = UILabel()
    private let albumLabel = UILabel()
    
    private let playPauseButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let prevButton = UIButton(type: .system)
    private let openSpotifyButton = UIButton(type: .system)

    private var isPlaying: Bool = false
    private var playbackTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        title = "Now Playing"
        setupUI()
        fetchCurrentPlayback()
        startPlaybackTimer()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchCurrentPlayback() // Her göründüğünde yeniden güncelle
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let imageSize: CGFloat = view.frame.width - 80
        albumImageView.frame = CGRect(x: 40, y: view.safeAreaInsets.top + 40, width: imageSize, height: imageSize)
        trackLabel.frame = CGRect(x: 20, y: albumImageView.frame.maxY + 10, width: view.frame.width - 40, height: 30)
        artistLabel.frame = CGRect(x: 20, y: trackLabel.frame.maxY + 5, width: view.frame.width - 40, height: 25)
        albumLabel.frame = CGRect(x: 20, y: artistLabel.frame.maxY + 5, width: view.frame.width - 40, height: 25)
        prevButton.frame = CGRect(x: 40, y: albumLabel.frame.maxY + 20, width: 60, height: 60)
        playPauseButton.frame = CGRect(x: (view.frame.width - 60)/2, y: albumLabel.frame.maxY + 20, width: 60, height: 60)
        nextButton.frame = CGRect(x: view.frame.width - 100, y: albumLabel.frame.maxY + 20, width: 60, height: 60)
        openSpotifyButton.frame = CGRect(x: 40, y: nextButton.frame.maxY + 30, width: view.frame.width - 80, height: 50)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchCurrentPlayback() // Spotify'da mevcut çalanı her gelişte yeniden al
    }
    private func setupUI() {
        albumImageView.contentMode = .scaleAspectFill
        albumImageView.clipsToBounds = true
        albumImageView.layer.cornerRadius = 8
        view.addSubview(albumImageView)

        [trackLabel, artistLabel, albumLabel].forEach {
            $0.textAlignment = .center
            $0.textColor = .white
            view.addSubview($0)
        }

        trackLabel.font = .boldSystemFont(ofSize: 22)
        artistLabel.font = .systemFont(ofSize: 18)
        albumLabel.font = .italicSystemFont(ofSize: 16)

        playPauseButton.tintColor = .white
        playPauseButton.addTarget(self, action: #selector(didTapPlayPause), for: .touchUpInside)

        nextButton.setImage(UIImage(systemName: "forward.fill"), for: .normal)
        nextButton.tintColor = .white
        nextButton.addTarget(self, action: #selector(didTapNext), for: .touchUpInside)

        prevButton.setImage(UIImage(systemName: "backward.fill"), for: .normal)
        prevButton.tintColor = .white
        prevButton.addTarget(self, action: #selector(didTapPrevious), for: .touchUpInside)

        openSpotifyButton.setTitle("📲 Spotify'ı Aç", for: .normal)
        openSpotifyButton.tintColor = .white
        openSpotifyButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        openSpotifyButton.backgroundColor = .systemGreen
        openSpotifyButton.layer.cornerRadius = 10
        openSpotifyButton.addTarget(self, action: #selector(openSpotify), for: .touchUpInside)

        view.addSubview(playPauseButton)
        view.addSubview(nextButton)
        view.addSubview(prevButton)
        view.addSubview(openSpotifyButton)
    }

    private func startPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.fetchCurrentPlayback()
        }
    }

    private func fetchCurrentPlayback() {
        APICaller.shared.getCurrentlyPlayingTrack { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    guard let track = response.item else {
                        self?.updateUIForNoTrack()
                        return
                    }
                    let trackURI = "spotify:track:\(track.id)"
                    self?.storeLastTrackURI(trackURI)
                    print("🎵 DEBUG: Mevcut parça: \(track.name) - URI: \(trackURI)")

                    self?.trackLabel.text = track.name
                    self?.artistLabel.text = track.artists.first?.name
                    self?.albumLabel.text = track.album?.name
                    self?.isPlaying = response.is_playing ?? false
                    self?.updatePlayPauseIcon()

                    if let url = URL(string: track.album?.images.first?.url ?? "") {
                        self?.albumImageView.sd_setImage(with: url)
                    }

                case .failure:
                    self?.updateUIForNoTrack()
                }
            }
        }
    }

    private func updateUIForNoTrack() {
        trackLabel.text = "No song playing"
        artistLabel.text = ""
        albumLabel.text = ""
        albumImageView.image = UIImage(systemName: "music.note")
        isPlaying = false
        updatePlayPauseIcon()
    }

    private func updatePlayPauseIcon() {
        let iconName = isPlaying ? "pause.fill" : "play.fill"
        playPauseButton.setImage(UIImage(systemName: iconName), for: .normal)
    }

    @objc private func didTapPlayPause() {
        if isPlaying {
            APICaller.shared.togglePlayback { [weak self] success in
                if success {
                    self?.isPlaying = false
                    DispatchQueue.main.async {
                        self?.updatePlayPauseIcon()
                    }
                }
            }
        } else {
            APICaller.shared.resumePlayback { [weak self] success in
                if success {
                    self?.isPlaying = true
                    DispatchQueue.main.async {
                        self?.updatePlayPauseIcon()
                        self?.fetchCurrentPlayback()
                    }
                } else {
                    print("❌ Devam ettirme başarısız. Son parçayı tekrar başlatılıyor...")
                    if let uri = self?.loadLastTrackURI() {
                        APICaller.shared.startPlayback(trackUri: uri) { started in
                            if started {
                                self?.isPlaying = true
                                DispatchQueue.main.async {
                                    self?.updatePlayPauseIcon()
                                    self?.fetchCurrentPlayback()
                                }
                            } else {
                                print("❌ Başlatılamadı: \(uri)")
                            }
                        }
                    }
                }
            }
        }
    }

    @objc private func didTapNext() {
        APICaller.shared.skipToNext { [weak self] success in
            if success {
                self?.fetchCurrentPlayback()
            }
        }
    }

    @objc private func didTapPrevious() {
        APICaller.shared.skipToPrevious { [weak self] success in
            if success {
                self?.fetchCurrentPlayback()
            }
        }
    }

    @objc private func openSpotify() {
        if let url = URL(string: "spotify://") {
            UIApplication.shared.open(url, options: [:]) { success in
                print(success ? "✅ Spotify uygulaması açıldı" : "❌ Spotify açılamadı")
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playbackTimer?.invalidate()
    }

    // MARK: - Son parça URI saklama

    private let lastTrackKey = "last_played_track_uri"

    private func storeLastTrackURI(_ uri: String) {
        UserDefaults.standard.set(uri, forKey: lastTrackKey)
        print("💾 DEBUG: Track URI saklandı: \(uri)")
    }

    private func loadLastTrackURI() -> String? {
        let uri = UserDefaults.standard.string(forKey: lastTrackKey)
        print("📦 DEBUG: Saklanan URI alındı: \(uri ?? "yok")")
        return uri
    }
}
