//
//  TabBarViewController.swift
//  Spotify
//
//  Created by Mesut Aygun on 2/14/21.
//

import UIKit


class TabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.barTintColor = .white
            tabBar.backgroundColor = .white
            tabBar.isTranslucent = false
            tabBar.tintColor = .label
            tabBar.unselectedItemTintColor = .gray
        let vc1 = HomeViewController()
        //let vc2 = SearchViewController()
        let vc3 = LibraryViewController()
        let vc4 = ControlPlaybackViewController()
        let vc5 = ProfileViewController() // 👈 Yeni eklendi

        vc1.title = "Browse"
        //vc2.title = "Search"
        vc3.title = "Library"
        vc4.title = "Control"
        vc5.title = "Profile" // 👈 Yeni başlık

        vc1.navigationItem.largeTitleDisplayMode = .always
       // vc2.navigationItem.largeTitleDisplayMode = .always
        vc3.navigationItem.largeTitleDisplayMode = .always
        vc4.navigationItem.largeTitleDisplayMode = .always
        vc5.navigationItem.largeTitleDisplayMode = .always // 👈 Eklendi

        let nav1 = UINavigationController(rootViewController: vc1)
        //let nav2 = UINavigationController(rootViewController: vc2)
        let nav3 = UINavigationController(rootViewController: vc3)
        let nav4 = UINavigationController(rootViewController: vc4)
        let nav5 = UINavigationController(rootViewController: vc5) // 👈 Eklendi

        nav1.navigationBar.tintColor = .label
       // nav2.navigationBar.tintColor = .label
        nav3.navigationBar.tintColor = .label
        nav4.navigationBar.tintColor = .label
        nav5.navigationBar.tintColor = .label // 👈 Eklendi

        nav1.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), tag: 1)
       // nav2.tabBarItem = UITabBarItem(title: "Search", image: UIImage(systemName: "magnifyingglass"), tag: 2)
        nav3.tabBarItem = UITabBarItem(title: "Library", image: UIImage(systemName: "music.note.list"), tag: 3)
        nav4.tabBarItem = UITabBarItem(title: "Control", image: UIImage(systemName: "play.circle"), tag: 4)
        nav5.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person.circle"), tag: 5) // 👈 Eklendi

        nav1.navigationBar.prefersLargeTitles = true
       // nav2.navigationBar.prefersLargeTitles = true
        nav3.navigationBar.prefersLargeTitles = true
        nav4.navigationBar.prefersLargeTitles = true
        nav5.navigationBar.prefersLargeTitles = true // 👈 Eklendi

        setViewControllers([nav1, nav3, nav4, nav5], animated: false)
    }
}
