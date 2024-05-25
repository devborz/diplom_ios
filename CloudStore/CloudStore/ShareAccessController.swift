//
//  ShareAccessController.swift
//  CloudStore
//
//  Created by Усман Туркаев on 21.05.2024.
//

import UIKit

final class ShareAccessController: UIViewController {
    
    var sessionData: SessionData!
    
    var path: String!
    
    var completion: (() -> Void)?
    
    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var switchControl: UISwitch!
    
    lazy var addAction = UIBarButtonItem(title: "Add", style: .done, 
                                         target: self, action: #selector(self.addTapped))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addAction.isEnabled = false
        self.navigationItem.title = "Share access"
        self.navigationItem.rightBarButtonItem = self.addAction
    }
    
    @objc
    func addTapped() {
        let request = APIRequest.shareAccess(uid: self.sessionData.uid,
                                             path: self.path,
                                             email: self.textField.text ?? "",
                                             write: self.switchControl.isOn) { error in
            
        }
        request.make()
        self.navigationController?.dismiss(animated: true)
        self.completion?()
    }
    
    
    @IBAction func textFieldChanged(_ sender: Any) {
        self.addAction.isEnabled = !(self.textField.text ?? "").isEmpty
    }
    
    
    @IBAction func textFieldEditingDidEnd(_ sender: Any) {
        self.textField.endEditing(true)
    }
    
    
    @IBAction func switchChaghed(_ sender: Any) {
    }
    
}
