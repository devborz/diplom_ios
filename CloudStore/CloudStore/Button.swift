//
//  Button.swift
//  CloudStore
//
//  Created by Усман Туркаев on 07.05.2023.
//

import UIKit

final class Button: UIButton {
    
    override var isEnabled: Bool {
        didSet {
            self.alpha = self.isEnabled ? 1 : 0.5
        }
    }
}
