//
//  ViewController.swift
//  Spotify
//
//  Created by Mesut Aygun on 2/14/21.
//

import UIKit

enum BrowseSectionType {
    case newReleases(viewModels: [NewReleasesCellViewModel]) // 1
    case featuredPlaylists(viewModels: [FeaturedPlaylistCellViewModel]) // 2
    case recommendedTracks(viewModels: [RecommendedTrackCellViewModel]) // 3

    var title: String {
        switch self {
        case .newReleases:
            return "New Released Albums"
        case .featuredPlaylists:
            return "Featured Playlists"
        case .recommendedTracks:
            return "Recommended"
        }
    }
}



import UIKit
import SDWebImage

final class HomeViewController: UIViewController, UICollectionViewDelegate {
    private var newAlbums: [Album] = []

    private let scrollView = UIScrollView()
    private let contentView = UIStackView()

    private let nowPlayingImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private let nowPlayingTitleLabel = UILabel()
    private let nowPlayingArtistLabel = UILabel()
    private let nowPlayingAlbumLabel = UILabel()

    private var albumsCollectionView: UICollectionView!
    private var nowPlayingTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Spotify"
       
        view.backgroundColor = .black

        setupLayout()
        fetchNowPlaying()
        startNowPlayingUpdates()
        fetchNewReleases()
    }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.axis = .vertical
        contentView.spacing = 24
        contentView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        let nowPlayingStack = UIStackView(arrangedSubviews: [nowPlayingImageView, nowPlayingTitleLabel, nowPlayingArtistLabel, nowPlayingAlbumLabel])
        nowPlayingStack.axis = .vertical
        nowPlayingStack.alignment = .center
        nowPlayingStack.spacing = 8

        nowPlayingTitleLabel.font = .boldSystemFont(ofSize: 20)
        nowPlayingTitleLabel.textColor = .white
        nowPlayingArtistLabel.textColor = .lightGray
        nowPlayingAlbumLabel.textColor = .gray

        contentView.addArrangedSubview(nowPlayingStack)

        nowPlayingImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nowPlayingImageView.heightAnchor.constraint(equalToConstant: 200),
            nowPlayingImageView.widthAnchor.constraint(equalToConstant: 200)
        ])

        let label = UILabel()
        label.text = "🎉 New Releases"
        label.font = .boldSystemFont(ofSize: 18)
        label.textColor = .white
        label.textAlignment = .left
        contentView.addArrangedSubview(label)

        let layout = UICollectionViewFlowLayout()
        let itemSize = (view.bounds.width - 40) / 3
        layout.itemSize = CGSize(width: itemSize, height: itemSize + 35)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 20

        albumsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        albumsCollectionView.backgroundColor = .black
        albumsCollectionView.dataSource = self
        albumsCollectionView.delegate = self
        albumsCollectionView.register(NewAlbumCell.self, forCellWithReuseIdentifier: NewAlbumCell.identifier)
        albumsCollectionView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addArrangedSubview(albumsCollectionView)
        albumsCollectionView.heightAnchor.constraint(equalToConstant: 420).isActive = true
    }

    private func fetchNowPlaying() {
        APICaller.shared.getCurrentlyPlayingTrack { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    guard let track = response.item else {
                        self?.nowPlayingTitleLabel.text = "No song is currently playing."
                        self?.nowPlayingArtistLabel.text = "Please open the Spotify app."
                        self?.nowPlayingAlbumLabel.text = ""
                        self?.nowPlayingImageView.image = UIImage(systemName: "music.note")
                        self?.nowPlayingImageView.tintColor = .lightGray
                        return
                    }

                    self?.nowPlayingTitleLabel.text = "🎵 \(track.name)"
                    self?.nowPlayingArtistLabel.text = "👤 \(track.artists.first?.name ?? "-")"
                    self?.nowPlayingAlbumLabel.text = "💿 \(track.album?.name ?? "-")"

                    if let url = URL(string: track.album?.images.first?.url ?? "") {
                        self?.nowPlayingImageView.sd_setImage(with: url)
                    }
                case .failure(let error):
                    print("NowPlaying Error: \(error.localizedDescription)")
                    self?.nowPlayingTitleLabel.text = "No song is currently playing."
                    self?.nowPlayingArtistLabel.text = "Please open the Spotify app."
                    self?.nowPlayingAlbumLabel.text = ""
                    self?.nowPlayingImageView.image = UIImage(systemName: "music.note")
                    self?.nowPlayingImageView.tintColor = .lightGray
                }
            }
        }
    }

    private func startNowPlayingUpdates() {
        nowPlayingTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.fetchNowPlaying()
        }
    }

    private func fetchNewReleases() {
        AuthManager.shared.validateAndRefreshTokenIfNeeded { [weak self] success in
            guard success else { return }

            APICaller.shared.getNewReleases { result in
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        self?.newAlbums = response.albums.items
                        self?.albumsCollectionView.reloadData()
                        print("✅ UI güncellendi: \(response.albums.items.count) albüm yüklendi.")
                    }
                case .failure(let error):
                    print("❌ NewReleases Error: \(error.localizedDescription)")
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        nowPlayingTimer?.invalidate()
    }
}

extension HomeViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return newAlbums.count
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let album = newAlbums[indexPath.row]
        let vc = AlbumViewController(album: album)
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewAlbumCell.identifier, for: indexPath) as? NewAlbumCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: newAlbums[indexPath.row])
        return cell
    }
}
final class PlaylistCell: UICollectionViewCell {
    static let identifier = "PlaylistCell"

    private let imageView = UIImageView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .darkGray
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center

        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: contentView.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 6),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with playlist: Playlist) {
        imageView.sd_setImage(with: URL(string: playlist.images.first?.url ?? ""))
        titleLabel.text = playlist.name
    }
}
import UIKit

final class NowPlayingView: UIView {

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 22)
        return label
    }()

    private let artistLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 18)
        return label
    }()

    private let albumLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray
        label.font = .italicSystemFont(ofSize: 16)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(imageView)
        addSubview(nameLabel)
        addSubview(artistLabel)
        addSubview(albumLabel)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let imageSize: CGFloat = 100
        imageView.frame = CGRect(x: 20, y: 0, width: imageSize, height: imageSize)
        nameLabel.frame = CGRect(x: imageView.frame.maxX + 12, y: 0, width: frame.width - imageSize - 40, height: 30)
        artistLabel.frame = CGRect(x: imageView.frame.maxX + 12, y: nameLabel.frame.maxY + 4, width: frame.width - imageSize - 40, height: 25)
        albumLabel.frame = CGRect(x: imageView.frame.maxX + 12, y: artistLabel.frame.maxY + 4, width: frame.width - imageSize - 40, height: 25)
    }

    public func configure(with track: AudioTrack) {
        nameLabel.text = track.name
        artistLabel.text = track.artists.first?.name
        albumLabel.text = track.album?.name
        if let url = URL(string: track.album?.images.first?.url ?? "") {
            imageView.sd_setImage(with: url)
        }
    }
}
import UIKit

final class AlbumGridDataSource: NSObject, UICollectionViewDataSource {

    var viewModels: [NewReleasesCellViewModel] = []

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModels.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: AlbumCell.identifier,
            for: indexPath
        ) as? AlbumCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: viewModels[indexPath.row])
        return cell
    }
}
import UIKit

final class AlbumCell: UICollectionViewCell {
    static let identifier = "AlbumCell"

    private let imageView = UIImageView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .darkGray
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2

        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = CGRect(x: 5, y: 5, width: contentView.frame.width - 10, height: contentView.frame.width - 10)
        titleLabel.frame = CGRect(x: 5, y: imageView.frame.maxY + 5, width: contentView.frame.width - 10, height: 35)
    }

    public func configure(with viewModel: NewReleasesCellViewModel) {
        imageView.sd_setImage(with: viewModel.artworkURL)
        titleLabel.text = viewModel.name
    }
}
import UIKit

extension UIImageView {
    func loadImage(from url: URL) {
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = image
                }
            }
        }
    }
}
import UIKit
import SDWebImage

class NewAlbumCell: UICollectionViewCell {
    static let identifier = "NewAlbumCell"
    
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .darkGray
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: contentView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with album: Album) {
        imageView.sd_setImage(with: URL(string: album.images.first?.url ?? ""))
        titleLabel.text = album.name
    }
}


