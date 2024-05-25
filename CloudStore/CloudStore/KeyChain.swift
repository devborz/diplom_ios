//
//  KeyChain.swift
//  CloudStore
//
//  Created by Усман Туркаев on 19.05.2024.
//

import Foundation
import Security

final class Defaults {
    
    static var uid: Int64? {
        get {
            if let str = UserDefaults.standard.string(forKey: "uid") {
                return Int64(str)
            } else {
                return nil
            }
        }
        set {
            if let newValue {
                UserDefaults.standard.setValue(String(newValue), forKey: "uid")
            } else {
                UserDefaults.standard.setValue(nil, forKey: "uid")
            }
        }
    }
    
}

struct SessionKeyChain: SessionDataStore {
    
    let service: String = "CloudStore"
    
    func save(_ data: SessionData) {
        let sensData = data.token.data(using: .utf8)!
        let account = String(data.uid)
        Defaults.uid = data.uid
        let query = [
            kSecValueData: sensData,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: String(data.uid)
        ] as CFDictionary
            
        let saveStatus = SecItemAdd(query, nil)
     
        if saveStatus != errSecSuccess {
            print("Error: \(saveStatus)")
        }
        
        if saveStatus == errSecDuplicateItem {
            update(sensData, account: account)
        }
    }
    
    func update(_ data: Data, account: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as CFDictionary
            
        let updatedData = [kSecValueData: data] as CFDictionary
        SecItemUpdate(query, updatedData)
    }
    
    func delete() {
        guard let uid = Defaults.uid else { return }
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: self.service,
            kSecAttrAccount: String(uid)
        ] as CFDictionary
            
        SecItemDelete(query)
    }
    
    func get() -> SessionData? {
        guard let uid = Defaults.uid else { return nil }
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: self.service,
            kSecAttrAccount: String(uid),
            kSecReturnData: true
        ] as CFDictionary
            
        var result: AnyObject?
        SecItemCopyMatching(query, &result)
        if let data = result as? Data, 
            let token = String(data: data, encoding: .utf8) {
            return .init(uid: uid, token: token)
        } else {
            return nil
        }
    }
    
    
}

