//
//  User.swift
//  Team7LibraryManagementSystem
//
//  Created by Taksh Joshi on 25/02/25.
//

import Foundation
struct UserProfile: Codable {
    let userId: String
    var firstName: String
    var lastName: String
    var email: String
   // var dob: String
    var gender: String
    let role: String
    var isDeleted: Bool
    var language: [String]
    var genre: [String]
    var mobileNumber: String
    var profileImageUrl: String?
}
