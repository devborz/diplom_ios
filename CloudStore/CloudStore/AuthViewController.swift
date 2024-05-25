//
//  AuthViewController.swift
//  CloudStore
//
//  Created by Усман Туркаев on 31.03.2023.
//

import UIKit

final class AuthViewController: ViewController {
    
    let vStackView: UIStackView = UIStackView()
    
    let emailTextField: UITextField = UITextField()
    
    let passwordTextField: UITextField = UITextField()
    
    let loginButton: Button = Button()
    
    var vStackViewConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Login"
        
        self.view.backgroundColor = .systemBackground
        
        self.vStackView.axis = .vertical
        
        self.vStackView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.vStackView)
        NSLayoutConstraint.activate([
            self.vStackView.leftAnchor.constraint(equalTo: self.view.leftAnchor,
                                                  constant: 20),
            self.vStackView.rightAnchor.constraint(equalTo: self.view.rightAnchor,
                                                  constant: -20),
            self.vStackView.heightAnchor.constraint(equalToConstant: 172)
        ])
        
        self.vStackViewConstraint = self.vStackView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        self.vStackViewConstraint.isActive = true
        
        self.vStackView.spacing = 20
        self.vStackView.distribution = .fillEqually
        
        self.vStackView.addArrangedSubview(self.emailTextField)
        self.vStackView.addArrangedSubview(self.passwordTextField)
        self.vStackView.addArrangedSubview(self.loginButton)
        
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
        self.passwordTextField.textContentType = .password
        self.passwordTextField.delegate = self
        
        self.loginButton.isEnabled = false
        self.loginButton.backgroundColor = .systemBlue
        self.loginButton.setTitle("Login", for: .normal)
        self.loginButton.setTitleColor(.white, for: .normal)
        self.loginButton.setTitleColor(.white.withAlphaComponent(0.5), for: .highlighted)
        self.loginButton.layer.cornerRadius = 10
        self.loginButton.layer.cornerCurve = .continuous
        self.loginButton.clipsToBounds = true
        self.loginButton.titleLabel?.font = .systemFont(ofSize: 17,
                                                        weight: .semibold)
        self.loginButton.addTarget(self, action: #selector(self.loginTapped),
                                      for: .touchUpInside)
        
        let registerItem = UIBarButtonItem(title: "Register",
                                           style: .done, target: self,
                                           action: #selector(self.register))
        self.navigationItem.rightBarButtonItem = registerItem
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.didTap))
        self.view.addGestureRecognizer(gesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow),
                                               name:
                                                UIResponder.keyboardWillShowNotification, object: nil)
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
        let diff = size.height - (self.view.frame.height / 2 - 96)
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
    
    @objc func loginTapped() {
        let email = self.emailTextField.text ?? ""
        let password = self.passwordTextField.text ?? ""
        
        guard !email.isEmpty, !password.isEmpty else {
            return
        }
        self.startLoadingMode()
        AuthService.login(email: email, password: password) {[weak self] error in
            guard let strongSelf = self else { return }
            strongSelf.stopLoadingMode()
            if let error {
                
            } else {
                updateRootController(currentView: strongSelf.view)
            }
        }
    }
    
    @objc
    func register() {
        let vc = RegistrationViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func didTap() {
        self.emailTextField.endEditing(true)
        self.passwordTextField.endEditing(true)
    }

}

extension AuthViewController: UITextFieldDelegate {

    func textFieldDidChangeSelection(_ textField: UITextField) {
        let password = self.passwordTextField.text ?? ""
        let email = self.emailTextField.text ?? ""
        let isEnabled = password.count >= 8 && email.count >= 5
        self.loginButton.isEnabled = isEnabled
    }
    
}


