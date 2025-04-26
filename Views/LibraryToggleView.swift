//
//  LibraryToggleView.swift
//  Spotify
//
//  Created by Mesut Aygun on 2/21/21.
//

import UIKit

protocol LibraryToggleViewDelegate: AnyObject {
    func libraryToggleViewDidTapPlaylists(_ toggleView: LibraryToggleView)
    func libraryToggleViewDidTapAlbums(_ toggleView: LibraryToggleView)
}

class LibraryToggleView: UIView {

    enum State {
        case playlist
        case album
    }

    var state: State = .playlist

    weak var delegate: LibraryToggleViewDelegate?

    private let playlistButton: UIButton = {
        let button = UIButton()
        button.setTitle("Playlists", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        return button
    }()

    private let albumsButton: UIButton = {
        let button = UIButton()
        button.setTitle("Albums", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        return button
    }()

    private let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGreen
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 2
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        addSubview(playlistButton)
        addSubview(albumsButton)
        addSubview(indicatorView)

        playlistButton.addTarget(self, action: #selector(didTapPlaylists), for: .touchUpInside)
        albumsButton.addTarget(self, action: #selector(didTapAlbums), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    @objc private func didTapPlaylists() {
        state = .playlist
        animateIndicator()
        delegate?.libraryToggleViewDidTapPlaylists(self)
    }

    @objc private func didTapAlbums() {
        state = .album
        animateIndicator()
        delegate?.libraryToggleViewDidTapAlbums(self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let buttonWidth = frame.width / 2
        playlistButton.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: frame.height - 6)
        albumsButton.frame = CGRect(x: buttonWidth, y: 0, width: buttonWidth, height: frame.height - 6)
        layoutIndicator()
    }

    private func animateIndicator() {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            self.layoutIndicator()
        }
    }

    func layoutIndicator() {
        let buttonWidth = frame.width / 2
        indicatorView.frame = CGRect(
            x: state == .playlist ? 0 : buttonWidth,
            y: frame.height - 4,
            width: buttonWidth,
            height: 3
        )
    }

    func update(for state: State) {
        self.state = state
        animateIndicator()
    }
}
