//
//  Auth.swift
//  CloudStore
//
//  Created by Усман Туркаев on 19.05.2024.
//

import Foundation
import Security

protocol SessionDataStore {
    func save(_ data: SessionData)
    
    func delete()
    
    func get() -> SessionData?
}

final class AuthService {
    
    private static var sessionDataStore: SessionDataStore = SessionKeyChain()
    
    static var isAuthenticated: Bool {
        return AuthService.getSessionData() != nil
    }
    
    fileprivate static func saveSessionData(_ data: SessionData) {
        AuthService.sessionDataStore.save(data)
    }

    fileprivate static func deleteSession() {
        AuthService.sessionDataStore.delete()
    }

    static func getSessionData() -> SessionData? {
        return AuthService.sessionDataStore.get()
    }
    
    static func register(email: String, password: String, handler: @escaping (_ error: String?) -> Void) {
        let request: APIRequest = .register(credentials: .init(email: email, password: password)) { result, error in
            if let result {
                AuthService.saveSessionData(result)
                handler(nil)
            } else {
                handler(error?.message ?? CloudError.error.message)
            }
        }
        request.make()
    }
    
    static func login(email: String, password: String, handler: @escaping (_ error: String?) -> Void) {
        let request: APIRequest = .login(credentials: .init(email: email, password: password)) { result, error in
            if let result {
                AuthService.saveSessionData(result)
                handler(nil)
            } else {
                handler(error?.message ?? CloudError.error.message)
            }
        }
        request.make()
    }
    
    static func logout() {
        guard let sessionData = AuthService.getSessionData() else {
            return
        }
        AuthService.deleteSession()
        let request: APIRequest = .logout(token: sessionData.token) { _ in }
        request.make()
    }
    
}



