//
//  ViewController.swift
//  CloudStore
//
//  Created by Усман Туркаев on 07.05.2023.
//

import UIKit

class ViewController: UIViewController {
    
    private let loadingView = LoadingView()
    
    var safeArea: UILayoutGuide {
        return self.view.safeAreaLayoutGuide
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func startLoadingMode() {
        self.loadingView.alpha = 0
        let view = self.navigationController?.view ?? self.view!
        view.addSubview(self.loadingView)
        self.loadingView.frame = view.frame
        UIView.animate(withDuration: 0.5) {
            self.loadingView.alpha = 1
        }
        self.loadingView.startAnimating()
    }
    
    func stopLoadingMode() {
        UIView.animate(withDuration: 0.5) {
            self.loadingView.alpha = 0
        } completion: { _ in
            self.loadingView.removeFromSuperview()
        }
        self.loadingView.stopAnimating()
    }

    final class LoadingView: UIView {
        
        private let activityView: UIActivityIndicatorView = .init(style: .medium)
         
        private let blurView: UIVisualEffectView = .init(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.blurView.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(self.blurView)
            NSLayoutConstraint.activate([
                self.blurView.topAnchor.constraint(equalTo: self.topAnchor),
                self.blurView.leftAnchor.constraint(equalTo: self.leftAnchor),
                self.blurView.rightAnchor.constraint(equalTo: self.rightAnchor),
                self.blurView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
            ])
            
            self.activityView.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(self.activityView)
            NSLayoutConstraint.activate([
                self.activityView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                self.activityView.centerXAnchor.constraint(equalTo: self.centerXAnchor)
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func startAnimating() {
            self.activityView.startAnimating()
        }
        
        func stopAnimating() {
            self.activityView.stopAnimating()
        }
    }
}
