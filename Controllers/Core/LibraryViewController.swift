//
//  LibraryViewController.swift
//  Spotify
//
//  Created by Mesut Aygun on 2/14/21.
//
import UIKit

class LibraryViewController: UIViewController {

    private let playlistsVC = LibraryPlaylistsViewController()
    private let albumsVC = LibraryAlbumsViewController()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .black
        return scrollView
    }()

    private let toggleView: LibraryToggleView = {
        let toggle = LibraryToggleView()
        toggle.backgroundColor = .black
        return toggle
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Library"
        view.backgroundColor = .black

        navigationController?.navigationBar.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]

        view.addSubview(toggleView)
        toggleView.delegate = self

        view.addSubview(scrollView)
        scrollView.contentSize = CGSize(width: view.width * 2, height: scrollView.height)
        scrollView.delegate = self

        addChildren()
        updateBarButtons()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        toggleView.frame = CGRect(x: 0, y: view.safeAreaInsets.top, width: view.width, height: 55)
        scrollView.frame = CGRect(
            x: 0,
            y: toggleView.frame.maxY,
            width: view.width,
            height: view.height - toggleView.frame.maxY
        )
    }

    private func updateBarButtons() {
        switch toggleView.state {
        case .playlist:
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .add,
                target: self,
                action: #selector(didTapAdd)
            )
            navigationItem.rightBarButtonItem?.tintColor = .systemGreen
        case .album:
            navigationItem.rightBarButtonItem = nil
        }
    }

    @objc private func didTapAdd() {
        playlistsVC.showCreatePlaylistAlert()
    }

    private func addChildren() {
        addChild(playlistsVC)
        scrollView.addSubview(playlistsVC.view)
        playlistsVC.view.frame = CGRect(x: 0, y: 0, width: scrollView.width, height: scrollView.height)
        playlistsVC.view.backgroundColor = .black
        playlistsVC.didMove(toParent: self)

        addChild(albumsVC)
        scrollView.addSubview(albumsVC.view)
        albumsVC.view.frame = CGRect(x: view.width, y: 0, width: scrollView.width, height: scrollView.height)
        albumsVC.view.backgroundColor = .black
        albumsVC.didMove(toParent: self)
    }
}

// MARK: - Scroll Delegate

extension LibraryViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x >= (view.width - 100) {
            toggleView.update(for: .album)
            updateBarButtons()
        } else {
            toggleView.update(for: .playlist)
            updateBarButtons()
        }
    }
}

// MARK: - Toggle Delegate

extension LibraryViewController: LibraryToggleViewDelegate {
    func libraryToggleViewDidTapPlaylists(_ toggleView: LibraryToggleView) {
        scrollView.setContentOffset(.zero, animated: true)
        updateBarButtons()
    }

    func libraryToggleViewDidTapAlbums(_ toggleView: LibraryToggleView) {
        scrollView.setContentOffset(CGPoint(x: view.width, y: 0), animated: true)
        updateBarButtons()
    }
}
