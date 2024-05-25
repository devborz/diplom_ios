//
//  CloudViewController.swift
//  CloudStore
//
//  Created by Усман Туркаев on 31.03.2023.
//

import UIKit
import PhotosUI
import Photos
import MobileCoreServices

final class ObjectViewModel: Hashable, Equatable {
    static func == (lhs: ObjectViewModel, rhs: ObjectViewModel) -> Bool {
        return lhs.model.id == rhs.model.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.model.id)
    }
    
    let model: Resource
    
    init(model: Resource) {
        self.model = model
    }
}

enum ContentSection {
    case main
}

final class CloudViewController: ViewController {
    
    enum Kind {
        case dir, shared
    }
    
    let kind: Kind
    
    let ownerID: Int64
    
    let sessionData: SessionData
    
    init(sessionData: SessionData, ownerID: Int64, kind: Kind = .dir) {
        self.sessionData = sessionData
        self.ownerID = ownerID
        self.kind = kind
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var path: String = "/"
    
    lazy var name: String = self.kind == .dir ? "Files" : "Shared"
    
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    
    var dataSource: UICollectionViewDiffableDataSource<ContentSection, ObjectViewModel>!
    
    lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(self.refresh), for: .valueChanged)
        control.backgroundColor = .clear
        return control
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.dataSource = .init(collectionView: self.collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "object", for: indexPath) as! ObjectCell
            cell.setup(itemIdentifier)
            return cell
        })
        self.loadData()
    }
    
    private func loadData() {
        let handler: ([Resource]?, CloudError?) -> Void = { [weak self] resources, error in
            self?.refreshControl.endRefreshing()
            guard error == nil, let resources else { return }
            var snapshot = NSDiffableDataSourceSnapshot<ContentSection, ObjectViewModel>()
            snapshot.appendSections([.main])
            snapshot.appendItems(resources.map { .init(model: $0) }, toSection: .main)
            DispatchQueue.main.async {
                self?.dataSource?.apply(snapshot, animatingDifferences: true)
            }
        }
        let request: APIRequest
        switch self.kind {
        case .dir:
            request = .getDirectoryContent(uid: self.ownerID, path: self.path, handler: handler)
        case .shared:
            request = .sharedResources(uid: self.ownerID, handler: handler)
        }
        request.make()
    }
    
    @objc func refresh() {
        self.loadData()
    }
    
    private func setupUI() {
        self.navigationItem.title = self.name
        self.view.backgroundColor = .systemBackground
        
        var items: [UIBarButtonItem] = []
        
        let optionsItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain,
                                        target: self, action: #selector(self.optionsTapped))
        items.append(optionsItem)
        if self.kind == .dir {
            
            let addFileItem = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain,
                                              target: self, action: #selector(self.addFileTapped))
            items.append(addFileItem)
        }
        self.navigationItem.rightBarButtonItems = items
        
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.collectionView)
        NSLayoutConstraint.activate([
            self.collectionView.topAnchor.constraint(equalTo: self.safeArea.topAnchor),
            self.collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.collectionView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.collectionView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
        ])
        self.collectionView.register(ObjectCell.self, forCellWithReuseIdentifier: "object")
        self.collectionView.backgroundColor = .secondarySystemBackground
        self.collectionView.delegate = self
        self.collectionView.refreshControl = self.refreshControl
        if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumLineSpacing = 5
            layout.minimumInteritemSpacing = 5
            layout.sectionInset = .init(top: 5, left: 5, bottom: 5, right: 5)
        }
    }
    
    func addMedia() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.selection = .default
        let vc = PHPickerViewController(configuration: config)
        vc.delegate = self
        vc.modalTransitionStyle = .coverVertical
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
    
    func addFile() {
        let vc = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        vc.modalTransitionStyle = .coverVertical
        vc.delegate = self
        self.present(vc, animated: true)
    }
    
    var createDirectoryAction: UIAlertAction?
    
    func addDirectory() {
        let alertController = UIAlertController(title: "Create directory", message: nil, preferredStyle: .alert)
        alertController.addTextField { [weak self] textField in
            textField.placeholder = "Name"
            textField.delegate = self
        }
        let path = self.path
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let createAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let strongSelf = self else { return }
            let text = alertController.textFields?.first?.text ?? ""
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            let request = APIRequest.createDirectory(uid: strongSelf.ownerID, path: path + "/\(text)") { error in
                dispatchGroup.leave()
            }
            request.make()
            dispatchGroup.notify(queue: .main) { [weak self] in
                self?.loadData()
            }
        }
        createAction.isEnabled = false
        self.createDirectoryAction = createAction
        alertController.addAction(cancelAction)
        alertController.addAction(createAction)
        self.present(alertController, animated: true)

    }
    
    @objc
    func optionsTapped() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if self.sessionData.uid == self.ownerID && self.path != "/" {
            let usersAction = UIAlertAction(title: "Users with access", style: .default) { [weak self] _ in
                guard let strongSelf = self else { return }
                strongSelf.showUsersWithAccess()
            }
            alertController.addAction(usersAction)
        }
        let signOutAction = UIAlertAction(title: "Sign Out", style: .destructive) { [weak self] _ in
            AuthService.logout()
            guard let strongSelf = self else { return }
            updateRootController(currentView: strongSelf.view)
        }
        alertController.addAction(signOutAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true)
    }
    
    @objc
    func addFileTapped() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let photosAction = UIAlertAction(title: "Photos", style: .default) { [weak self] _ in
            self?.addMedia()
        }
        let filesAction = UIAlertAction(title: "Files", style: .default) { [weak self] _ in
            self?.addFile()
        }
        let createDirectoryAction = UIAlertAction(title: "Create directory", style: .default) { [weak self] _ in
            self?.addDirectory()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(photosAction)
        alertController.addAction(filesAction)
        alertController.addAction(createDirectoryAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true)
    }
    
    func showUsersWithAccess() {
        let vc = UsersWithAccessController(sessionData: self.sessionData, path: self.path)
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .popover
        nav.modalTransitionStyle = .coverVertical
        self.present(nav, animated: true)
    }

}

extension CloudViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard urls.count == 1 else { return }
        let url = urls[0]
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        let request: APIRequest = .upload(uid: self.ownerID, fileURL: url,
                                          destination: self.path) { error in
            dispatchGroup.leave()
        }
        request.make()
        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.loadData()
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        
    }
}

extension CloudViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard results.count == 1 else { return }
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        let result = results[0]
        let path = self.path
        _ = result.itemProvider.loadFileRepresentation(for: .item) { [weak self] url, _, _ in
            guard let strongSelf = self, let url else { return }
            let request: APIRequest = .upload(uid: strongSelf.ownerID,
                                              fileURL: url,
                                              destination: path) { error in
                dispatchGroup.leave()
            }
            request.make()
        }
        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.loadData()
        }
    }
    
}

extension CloudViewController: UITextFieldDelegate {
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        self.createDirectoryAction?.isEnabled = textField.text != ""
    }

}

extension CloudViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, 
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (self.view.frame.width - 20) / 3,
                      height: (self.view.frame.width - 20) / 3 / 343 * 271 + 30)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let itemIdentifier = self.dataSource.itemIdentifier(for: indexPath) else { return }
        let model = itemIdentifier.model
        if itemIdentifier.model.resourceType == .dir {
            let viewController = CloudViewController(sessionData: self.sessionData, ownerID: model.ownerId)
            viewController.name = model.name
            
            viewController.path = (model.path == "." ? "" : model.path + "/") + model.name
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, 
                        contextMenuConfigurationForItemsAt indexPaths: [IndexPath],
                        point: CGPoint) -> UIContextMenuConfiguration? {
        guard let indexPath = indexPaths.first,
              let viewModel = self.dataSource.itemIdentifier(for: indexPath) else { return nil }
        let path = viewModel.model.path + "/" + viewModel.model.name
        return UIContextMenuConfiguration(actionProvider: { [weak self] suggestedActions in
            return UIMenu(children: [
                UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: [.destructive]) { [weak self] _ in
                    guard let strongSelf = self else {
                        return
                    }
                    let request = APIRequest.delete(uid: strongSelf.ownerID,
                                                    path: path) { error in
                        self?.loadData()
                    }
                    request.make()
                }
            ])
        })
    }
}

extension CloudViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, 
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let object = self.dataSource.itemIdentifier(for: indexPath) else { return nil }
        let config = UISwipeActionsConfiguration(actions: [
            .init(style: .destructive, title: "Delete", handler: { [weak self] _, _, _ in
                guard let strongSelf = self else { return }
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                let request = APIRequest.delete(uid: strongSelf.ownerID,
                                                path: strongSelf.path + "/" + object.model.name) { error in
                    guard error == nil else { return }
                    dispatchGroup.leave()
                }
                request.make()
                dispatchGroup.notify(queue: .main) { [weak self] in
                    guard let strongSelf = self else { return }
                    var snapshot = strongSelf.dataSource.snapshot()
                    snapshot.deleteItems([object])
                    strongSelf.dataSource.apply(snapshot, animatingDifferences: true)
                }
            })
        ])
        return config
    }
    
}
