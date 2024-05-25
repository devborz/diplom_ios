//
//  API.swift
//  CloudStore
//
//  Created by Усман Туркаев on 31.03.2023.
//

import Foundation
import MobileCoreServices
import UIKit

enum HTTPMethod: String {
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case get = "GET"
}

struct SessionData: Codable {
    var uid: Int64
    var token: String
}

struct Credentials: Codable {
    var email: String
    var password: String
}

extension Encodable {

    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }
}

func parse<T: Codable>(json: Data) -> T? {
    return try? JSONDecoder().decode(T.self, from: json)
}

enum APIRequest {
    case register(credentials: Credentials, handler: (_ result: SessionData?, _ error: CloudError?) -> Void)
    case login(credentials: Credentials, handler: (_ result: SessionData?, _ error: CloudError?) -> Void)
    case logout(token: String, handler: (_ error: CloudError?) -> Void)
    case upload(uid: Int64, fileURL: URL, destination: String, handler: (_ error: CloudError?) -> Void)
    case getDirectoryContent(uid: Int64, path: String, handler: (_ resources: [Resource]?, _ error: CloudError?) -> Void)
    case delete(uid: Int64, path: String, handler: (_ error: CloudError?) -> Void)
    case createDirectory(uid: Int64, path: String, handler: (_ error: CloudError?) -> Void)
    case sharedResources(uid: Int64, handler: (_ resources: [Resource]?, _ error: CloudError?) -> Void)
    case sharedUsers(uid: Int64, path: String, (_ resources: [UserModel]?, _ error: CloudError?) -> Void)
    case shareAccess(uid: Int64, path: String, email: String, write: Bool, handler: (_ error: CloudError?) -> Void)
    case deleteAccess(uid: Int64, path: String, email: String, handler: (_ error: CloudError?) -> Void)
    
    private var host: String {
        return "http://127.0.0.1:8080"
    }
    
    private var path: String {
        switch self {
        case .register:
            return "/auth/register"
        case .login:
            return "/auth/login"
        case .logout:
            return "/auth/logout"
        case .upload(let uid, _, let destination, _):
            return "/v1/resources/\(uid)?path=\(destination)"
        case .getDirectoryContent(let uid, let path, _):
            return "/v1/resources/\(uid)?path=\(path)"
        case .delete(let uid, let path, _):
            return "/v1/resources/\(uid)?path=\(path)"
        case .createDirectory(let uid, let path, _):
            return "/v1/resources/\(uid)?path=\(path)"
        case .sharedResources:
            return "/v1/sharedresources"
        case .sharedUsers(let uid, let path, _):
            return "/v1/resources/\(uid)/access?path=\(path)"
        case .shareAccess(_, let path, let email, let write, _):
            return "/v1/rights?path=\(path)&email=\(email)&write=\(write)"
        case .deleteAccess(_, let path, let email, _):
            return "/v1/rights?path=\(path)&email=\(email)"
        }
    }
    
    private var method: HTTPMethod {
        switch self {
        case .register:
            return .post
        case .login:
            return .post
        case .logout:
            return .post
        case .upload:
            return .post
        case .getDirectoryContent:
            return .get
        case .delete:
            return .delete
        case .createDirectory:
            return .put
        case .sharedResources:
            return .get
        case .sharedUsers:
            return .get
        case .shareAccess:
            return .post
        case .deleteAccess:
            return .delete
        }
    }
    
    private var addAuthHeader: Bool {
        switch self {
        case .login, .register: 
            return false
        default: 
            return true
        }
    }
    
    private func handler(_ response: HTTPURLResponse?, _ data: Data?, _ error: Error?) {
        var error: CloudError = .error
        if let response, response.statusCode == 200 {
            switch self {
            case .register(_, let handler):
                if let data, let result: SessionData = parse(json: data) {
                    handler(result, nil)
                } else {
                    handler(nil, error)
                }
            case .login(_, let handler):
                if let data,
                    let result: SessionData = parse(json: data) {
                    handler(result, nil)
                } else {
                    handler(nil, error)
                }
            case .logout(_, let handler):
                handler(nil)
            case .upload(_, _, _, let handler):
                handler(nil)
            case .getDirectoryContent(_, _, let handler):
                if let data,
                    let list: ResourcesList = parse(json: data) {
                    handler(list.Resources, nil)
                } else {
                    handler(nil, error)
                }
            case .delete(_, _, let handler):
                handler(nil)
            case .createDirectory(_, _, let handler):
                handler(nil)
            case .sharedResources(_, let handler):
                if let data,
                    let list: ResourcesList = parse(json: data) {
                    handler(list.Resources, nil)
                } else {
                    handler(nil, error)
                }
            case .sharedUsers(_, _, let handler):
                if let data,
                    let list: UserList = parse(json: data) {
                    handler(list.Users, nil)
                } else {
                    handler(nil, error)
                }
            case .shareAccess(_, _, _, _, let handler):
                handler(nil)
            case .deleteAccess(_, _, _, let handler):
                handler(nil)
            }
            return
        } else if let data, let dict = dict(data), let cloudError = getCloudError(dict) {
            error = cloudError
        }
        switch self {
        case .register(_, let handler):
            handler(nil, error)
        case .login(_,  let handler):
            handler(nil, error)
        case .logout(_, let handler):
            handler(error)
        case .upload(_, _, _, let handler):
            handler(error)
        case .getDirectoryContent(_, _, let handler):
            handler(nil, error)
        case .delete(_, _, let handler):
            handler(error)
        case .createDirectory(_, _, let handler):
            handler(error)
        case .sharedResources(_, let handler):
            handler(nil, error)
        case .sharedUsers(_, _, let handler):
            handler(nil, error)
        case .shareAccess(_, _, _, _, let handler):
            handler(error)
        case .deleteAccess(_, _, _, let handler):
            handler(error)
        }
    }
    
    func make() {
        let url = URL(string: self.host + self.path)!
        var request = URLRequest(url: url)
        if self.addAuthHeader, let sessionData = AuthService.getSessionData() {
            request.addValue("Bearer \(sessionData.token)", forHTTPHeaderField: "Authorization")
        }
        request.httpMethod = self.method.rawValue
        switch self {
        case .register(let credentials, _):
            request.httpBody = json(credentials.dictionary ?? [:])
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            URLSession.shared.task(with: request, completion: self.handler)
        case .login(let credentials, _):
            request.httpBody = json(credentials.dictionary ?? [:])
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            URLSession.shared.task(with: request, completion: self.handler)
        case .upload(_, let fileURL, _, _):
            let boundary = UUID().uuidString
            let fileName = fileURL.lastPathComponent
            let mimetype = mimeType(for: fileName)
            let paramName = "file"
            let fileData = try? Data(contentsOf: fileURL)
            var data = Data()
            data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"\(paramName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)
            data.append(fileData!)
            data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            request.setValue(String(data.count), forHTTPHeaderField: "Content-Length")
            request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            URLSession.shared.uploadTask(with: request, data: data, completion: self.handler)
        default:
            URLSession.shared.task(with: request, completion: self.handler)
        }
    }
}

enum CloudError: Int {
    case error
    case invalidData
    case shortPassword
    case wrongPassword
    case emailIsAlreadyTaken
    case invalidEmail
    case registration
    case invalidAuthToken
    case missingAuthToken
    case invalidCredentials
    case login
    case missingFilePath
    case invalidFilePath
    case resourceAlreadyExists
    
    var message: String {
        switch self {
        case .invalidData:
            return "invalid data"
        case .shortPassword:
            return "the password must be longer than 16 characters"
        case .wrongPassword:
            return "the password must include uppercase and lowercase letters, numbers, and special characters"
        case .emailIsAlreadyTaken:
            return "email is already taken"
        case .invalidEmail:
            return "invalid email"
        case .registration:
            return "registration failed"
        case .invalidAuthToken:
            return "invalid authentication token"
        case .missingAuthToken:
            return "missing authentication token"
        case .invalidCredentials:
            return "invalid credentials"
        case .login:
            return "login failed"
        case .missingFilePath:
            return "missing filepath"
        case .invalidFilePath:
            return "invalid filepath"
        case .resourceAlreadyExists:
            return "resource with the same path already exists"
        case .error:
            return "error"
        }
    }
}

func getCloudError(_ dict: [String : Any]) -> CloudError? {
    guard let error = dict["error"] as? [String : Any],
          let code = error["code"] as? Int else {
        return nil
    }
    return CloudError(rawValue: code) ?? .error
}

func json<T>(_ object: T) -> Data? {
    return try? JSONSerialization.data(withJSONObject: object)
}

func dict(_ data: Data) -> [String: Any]? {
    return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
}

func array(_ data: Data) -> [[String: Any]]? {
    return try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
}

extension URLSession {
    
    func task(with request: URLRequest,
              completion: @escaping (_ response: HTTPURLResponse?, _ data: Data?, _ error: Error?) -> Void) {
        let task = self.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                completion(response as? HTTPURLResponse, data, error)
            }
        }
        task.resume()
    }
    
    func uploadTask(with request: URLRequest, data: Data,
              completion: @escaping (_ response: HTTPURLResponse?, _ data: Data?, _ error: Error?) -> Void) {
        let task = self.uploadTask(with: request, from: data) { data, response, error in
            DispatchQueue.main.async {
                completion(response as? HTTPURLResponse, data, error)
            }
        }
        task.resume()
    }
}

func mimeType(for path: String) -> String {
    let pathExtension = URL(fileURLWithPath: path).pathExtension as NSString
    guard
        let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, nil)?.takeRetainedValue(),
        let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue()
    else {
        return "application/octet-stream"
    }

    return mimetype as String
}
