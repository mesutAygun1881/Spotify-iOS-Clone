//
//  LibraryAlbumsViewController.swift
//  Spotify
//
//  Created by Mesut Aygun on 2/21/21.
//

import UIKit

class LibraryAlbumsViewController: UIViewController {

    var albums = [Album]()

    private let noAlbumsView = ActionLabelView()

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(
            SearchResultSubtitleTableViewCell.self,
            forCellReuseIdentifier: SearchResultSubtitleTableViewCell.identfier
        )
        tableView.isHidden = true
        tableView.backgroundColor = .black
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        setUpNoAlbumsView()
        fetchData()

        NotificationCenter.default.addObserver(
            forName: .albumSavedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.fetchData()
        }
    }

    private func setUpNoAlbumsView() {
        view.addSubview(noAlbumsView)
        noAlbumsView.delegate = self
        noAlbumsView.configure(with: ActionLabelViewViewModel(
            text: "You have not saved any albums yet.",
            actionTitle: "Browse"
        ))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        noAlbumsView.frame = CGRect(x: (view.width - 150) / 2, y: (view.height - 150) / 2, width: 150, height: 150)
        tableView.frame = view.bounds
    }

    private func fetchData() {
        albums.removeAll()
        APICaller.shared.getCurrentUserAlbums { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let albums):
                    self?.albums = albums
                    self?.updateUI()
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }

    private func updateUI() {
        noAlbumsView.isHidden = !albums.isEmpty
        tableView.isHidden = albums.isEmpty
        tableView.reloadData()
    }
}

extension LibraryAlbumsViewController: ActionLabelViewDelegate {
    func actionLabelViewDidTapButton(_ actionView: ActionLabelView) {
        tabBarController?.selectedIndex = 0
    }
}

extension LibraryAlbumsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albums.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: SearchResultSubtitleTableViewCell.identfier,
            for: indexPath
        ) as? SearchResultSubtitleTableViewCell else {
            return UITableViewCell()
        }

        let album = albums[indexPath.row]
        cell.configure(with: SearchResultSubtitleTableViewCellViewModel(
            title: album.name,
            subtitle: album.artists.first?.name ?? "-",
            imageURL: URL(string: album.images.first?.url ?? "")
        ))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let album = albums[indexPath.row]
        let vc = AlbumViewController(album: album)
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}
