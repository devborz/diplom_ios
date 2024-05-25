//
//  Models.swift
//  CloudStore
//
//  Created by Усман Туркаев on 19.05.2024.
//

import Foundation

struct ResourcesList: Codable {
    var Resources: [Resource]
}

enum ResourceType: String {
    case dir, file
}

struct Resource: Codable {
    var id: Int64
    var path: String
    var name: String
    var ownerId: Int64
    var created: String
    var type: String
    
    var resourceType: ResourceType {
        if type == "dir" {
            return .dir
        } else {
            return .file
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case path = "Path"
        case name = "Name"
        case ownerId = "OwnerID"
        case created = "Created"
        case type = "Type"
    }
}

struct UserList: Codable {
    var Users: [UserModel]
}

struct UserModel: Codable, Hashable, Equatable {
    static func == (lhs: UserModel, rhs: UserModel) -> Bool {
        return lhs.email == rhs.email && lhs.write == rhs.write
    }
    
    let email: String
    let write: Bool
    
    enum CodingKeys: String, CodingKey {
        case email = "Email"
        case write = "Write"
    }
}

