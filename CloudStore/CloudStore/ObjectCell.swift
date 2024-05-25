//
//  ObjectCellCollectionViewCell.swift
//  CloudStore
//
//  Created by Усман Туркаев on 20.05.2024.
//

import UIKit

final class ObjectCell: UICollectionViewCell {
    
    weak var viewModel: ObjectViewModel?
    
    let imageView = UIImageView()
    
    let label = UILabel()
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.3) {
                self.contentView.backgroundColor = self.isHighlighted ? .systemBackground : .secondarySystemBackground
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
//        self.contentView.backgroundColor = .systemBackground
        self.contentView.layer.cornerRadius = 10
        self.contentView.clipsToBounds = true
        
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.imageView)
        self.imageView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 10).isActive = true
        self.imageView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -10).isActive = true
        self.imageView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 10).isActive = true
        self.imageView.contentMode = .scaleAspectFit
        
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.label)
        self.label.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 10).isActive = true
        self.label.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -10).isActive = true
        self.label.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -10).isActive = true
        self.label.heightAnchor.constraint(equalToConstant: 18).isActive = true
        self.label.topAnchor.constraint(equalTo: self.imageView.bottomAnchor, constant: 2).isActive = true
        
        self.label.font = .systemFont(ofSize: 12, weight: .medium)
        self.label.textAlignment = .center
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.contentView.backgroundColor = .secondarySystemBackground
    }
    
    func setup(_ viewModel: ObjectViewModel) {
        self.viewModel = viewModel
        self.label.text = viewModel.model.name
        switch viewModel.model.resourceType {
        case .dir:
            self.imageView.image = UIImage(named: "directory")
        case .file:
            self.imageView.image = UIImage(named: "file")
        }
    }
}
