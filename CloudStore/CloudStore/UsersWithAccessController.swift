//
//  UsersWithAccessController.swift
//  CloudStore
//
//  Created by Усман Туркаев on 21.05.2024.
//

import UIKit

final class UsersWithAccessController: UITableViewController {
    
    let path: String
    
    let sessionData: SessionData
    
    init(sessionData: SessionData, path: String) {
        self.sessionData = sessionData
        self.path = path
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var dataSource: UITableViewDiffableDataSource<ContentSection, UserModel>?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Users"
        self.dataSource = .init(tableView: self.tableView, cellProvider: { tableView, indexPath, itemIdentifier in
            let cell = tableView.dequeueReusableCell(withIdentifier: "user", for: indexPath)
            var config = cell.defaultContentConfiguration()
            config.text = itemIdentifier.email
            config.secondaryText = itemIdentifier.write ? "Read & Write" : "Read"
            config.textProperties.font = .systemFont(ofSize: 16, weight: .semibold)
            config.textProperties.color = .label
            config.secondaryTextProperties.font = .systemFont(ofSize: 14, weight: .medium)
            config.secondaryTextProperties.color = .secondaryLabel
            cell.contentConfiguration = config
            return cell
        })
        self.dataSource?.defaultRowAnimation = .fade
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "user")
        self.loadData()
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(self.refresh), for: .valueChanged)
        control.backgroundColor = .clear
        self.refreshControl = control
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain,
                                                                 target: self, action: #selector(self.addTapped))
    }
    
    @objc func addTapped() {
        let vc = ShareAccessController(nibName: nil, bundle: nil)
        vc.path = self.path
        vc.sessionData = self.sessionData
        vc.completion = { [weak self] in
            self?.loadData()
        }
        let nav = UINavigationController(rootViewController: vc)
        self.present(nav, animated: true)
    }
    
    @objc func refresh() {
        self.loadData()
    }
    
    func loadData() {
        let request = APIRequest.sharedUsers(uid: self.sessionData.uid,
                                             path: self.path) { [weak self] users, error in
            self?.refreshControl?.endRefreshing()
            guard error == nil, let users else { return }
            var snapshot = NSDiffableDataSourceSnapshot<ContentSection, UserModel>()
            snapshot.appendSections([.main])
            snapshot.appendItems(users, toSection: .main)
            DispatchQueue.main.async {
                self?.dataSource?.apply(snapshot, animatingDifferences: true)
            }
        }
        request.make()
    }
    
    override func tableView(_ tableView: UITableView, 
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let model = self.dataSource?.itemIdentifier(for: indexPath) else { return nil }
        return .init(actions: [
            .init(style: .destructive, title: "Delete", handler: { [weak self] _, _, _ in
                guard let strongSelf = self else { return }
                let request = APIRequest.deleteAccess(uid: strongSelf.sessionData.uid,
                                                      path: strongSelf.path, email: model.email) { error in
                    self?.loadData()
                }
                request.make()
            })
        ])
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, 
                            commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard let model = self.dataSource?.itemIdentifier(for: indexPath) else { return }
        if editingStyle == .delete {
            tableView.deleteRows(at: [indexPath], with: .fade)
            let request = APIRequest.deleteAccess(uid: self.sessionData.uid,
                                                  path: self.path, email: model.email) { error in
                
            }
            request.make()
        }
    }

}
