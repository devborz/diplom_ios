//
//  RegistrationViewController.swift
//  CloudStore
//
//  Created by Усман Туркаев on 31.03.2023.
//

import UIKit
import Foundation

final class RegistrationViewController: ViewController {

    let vStackView: UIStackView = UIStackView()
    
    let emailTextField: UITextField = UITextField()
    
    let passwordTextField: UITextField = UITextField()
    
    let repeatPasswordTextField: UITextField = UITextField()
    
    let registerButton: Button = Button()
    
    var vStackViewConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Register"
        
        self.view.backgroundColor = .systemBackground
        
        self.vStackView.axis = .vertical
        
        self.vStackView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.vStackView)
        NSLayoutConstraint.activate([
            self.vStackView.leftAnchor.constraint(equalTo: self.view.leftAnchor,
                                                  constant: 20),
            self.vStackView.rightAnchor.constraint(equalTo: self.view.rightAnchor,
                                                  constant: -20),
            self.vStackView.heightAnchor.constraint(equalToConstant: 236)
        ])
        
        self.vStackViewConstraint = self.vStackView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        self.vStackViewConstraint.isActive = true
        
        self.vStackView.spacing = 20
        self.vStackView.distribution = .fillEqually
        
        self.vStackView.addArrangedSubview(self.emailTextField)
        self.vStackView.addArrangedSubview(self.passwordTextField)
        self.vStackView.addArrangedSubview(self.repeatPasswordTextField)
        self.vStackView.addArrangedSubview(self.registerButton)
        
        self.emailTextField.placeholder = "Email"
        self.emailTextField.keyboardType = .emailAddress
        self.emailTextField.font = .systemFont(ofSize: 17)
        self.emailTextField.borderStyle = .roundedRect
        self.emailTextField.autocorrectionType = .no
        self.emailTextField.autocapitalizationType = .none
        self.emailTextField.delegate = self
        
        self.passwordTextField.placeholder = "Password"
        self.passwordTextField.keyboardType = .asciiCapable
        self.passwordTextField.font = .systemFont(ofSize: 17)
        self.passwordTextField.borderStyle = .roundedRect
        self.passwordTextField.autocorrectionType = .no
        self.passwordTextField.autocapitalizationType = .none
        self.passwordTextField.isSecureTextEntry = true
        self.passwordTextField.textContentType = .newPassword
        self.passwordTextField.delegate = self
        
        self.repeatPasswordTextField.placeholder = "Repeat password"
        self.repeatPasswordTextField.keyboardType = .asciiCapable
        self.repeatPasswordTextField.font = .systemFont(ofSize: 17)
        self.repeatPasswordTextField.borderStyle = .roundedRect
        self.repeatPasswordTextField.autocorrectionType = .no
        self.repeatPasswordTextField.autocapitalizationType = .none
        self.repeatPasswordTextField.isSecureTextEntry = true
        self.repeatPasswordTextField.textContentType = .newPassword
        self.repeatPasswordTextField.delegate = self
        
        self.registerButton.isEnabled = false
        self.registerButton.backgroundColor = .systemBlue
        self.registerButton.setTitle("Register", for: .normal)
        self.registerButton.setTitleColor(.white, for: .normal)
        self.registerButton.setTitleColor(.white.withAlphaComponent(0.5), for: .highlighted)
        self.registerButton.layer.cornerRadius = 10
        self.registerButton.layer.cornerCurve = .continuous
        self.registerButton.clipsToBounds = true
        self.registerButton.titleLabel?.font = .systemFont(ofSize: 17,
                                                        weight: .semibold)
        self.registerButton.addTarget(self, action: #selector(self.registerTapped),
                                      for: .touchUpInside)
        
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.didTap))
        self.view.addGestureRecognizer(gesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow),
                                                name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide),
                                                name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc
    func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        let size = keyboardFrame.size
        let diff = size.height - (self.view.frame.height / 2 - 128)
        if diff > 0 {
            self.vStackViewConstraint.constant = -diff
            UIView.animate(withDuration: duration) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @objc
    func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        self.vStackViewConstraint.constant = 0
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func registerTapped() {
        let email = self.emailTextField.text ?? ""
        let password = self.passwordTextField.text ?? ""
        let passwordRepeat = self.repeatPasswordTextField.text ?? ""
        
        guard !email.isEmpty, !password.isEmpty, password == passwordRepeat else {
            return
        }
        
        self.startLoadingMode()
        AuthService.register(email: email, password: password) { [weak self] error in
            guard let strongSelf = self else { return }
            strongSelf.stopLoadingMode()
            if let error {
                print(error)
            } else {
                updateRootController(currentView: strongSelf.view)
            }
        }
    }
    
    @objc func didTap() {
        self.emailTextField.endEditing(true)
        self.passwordTextField.endEditing(true)
        self.repeatPasswordTextField.endEditing(true)
    }

}

extension RegistrationViewController: UITextFieldDelegate {

    func textFieldDidChangeSelection(_ textField: UITextField) {
        let password2 = self.repeatPasswordTextField.text ?? ""
        let password = self.passwordTextField.text ?? ""
        let email = self.emailTextField.text ?? ""
        let isEnabled = password.count >= 8 && email.count >= 5 && password == password2
        self.registerButton.isEnabled = isEnabled
    }
    
}
