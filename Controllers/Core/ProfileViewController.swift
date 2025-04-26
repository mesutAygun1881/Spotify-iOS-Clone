//
//  ProfileViewController.swift
//  Spotify
//
//  Created by Mesut Aygun on 2/14/21.
//

import SDWebImage
import UIKit



class ProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.isHidden = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .black
        return tableView
    }()

    private var models = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profile"
        view.backgroundColor = .black
        navigationController?.navigationBar.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]

        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        fetchProfile()
        configureSignOutButton()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }

    private func configureSignOutButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Sign Out",
            style: .done,
            target: self,
            action: #selector(didTapSignOut)
        )
        navigationItem.rightBarButtonItem?.tintColor = .systemRed
    }

    @objc private func didTapSignOut() {
        let actionSheet = UIAlertController(title: "Sign Out",
                                            message: "Are you sure you want to sign out?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Sign Out", style: .destructive, handler: { _ in
            AuthManager.shared.signOut { success in
                if success {
                    DispatchQueue.main.async {
                        let navVC = UINavigationController(rootViewController: WelcomeViewController())
                        navVC.navigationBar.prefersLargeTitles = true
                        navVC.viewControllers.first?.navigationItem.largeTitleDisplayMode = .always
                        UIApplication.shared.windows.first?.rootViewController = navVC
                        UIApplication.shared.windows.first?.makeKeyAndVisible()
                    }
                }
            }
        }))
        present(actionSheet, animated: true)
    }

    private func fetchProfile() {
        APICaller.shared.getCurrentUserProfile { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let model):
                    self?.updateUI(with: model)
                case .failure(let error):
                    print("Profile Error: \(error.localizedDescription)")
                    self?.failedToGetProfile()
                }
            }
        }
    }

    private func updateUI(with model: UserProfile) {
        tableView.isHidden = false
        models = [
            "👤 Full Name: \(model.display_name)",
            "📧 Email Address: \(model.email)",
            "🆔 User ID: \(model.id)",
            "💳 Plan: \(model.product.capitalized)"
        ]
        createTableHeader(with: model.images.first?.url)
        tableView.reloadData()
    }

    private func createTableHeader(with string: String?) {
        guard let urlString = string, let url = URL(string: urlString) else {
            return
        }

        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.width, height: view.width / 1.5))
        headerView.backgroundColor = .black

        let imageSize: CGFloat = headerView.height / 2
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageSize, height: imageSize))
        imageView.center = headerView.center
        imageView.contentMode = .scaleAspectFill
        imageView.sd_setImage(with: url, completed: nil)
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageSize / 2
        imageView.layer.borderWidth = 3
        imageView.layer.borderColor = UIColor.white.cgColor

        headerView.addSubview(imageView)
        tableView.tableHeaderView = headerView
    }

    private func failedToGetProfile() {
        let label = UILabel()
        label.text = "Failed to load profile."
        label.textColor = .lightGray
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.frame = CGRect(x: 0, y: view.center.y - 20, width: view.frame.width, height: 40)
        view.addSubview(label)
    }

    // MARK: - TableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = models[indexPath.row]
        cell.textLabel?.textColor = .white
        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        cell.backgroundColor = .black
        cell.selectionStyle = .none
        return cell
    }
}
