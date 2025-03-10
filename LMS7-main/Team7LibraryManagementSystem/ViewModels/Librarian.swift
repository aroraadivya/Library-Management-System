////
////  Librarian.swift
////  Team7LibraryManagementSystem
////
////  Created by Taksh Joshi on 21/02/25.
////
//
import SwiftUI
import FirebaseFirestore
struct Librarian: Identifiable ,Codable{
    var id: String
    
    let userId: String
    let fullName: String
    let email: String
    let phone: String
    let isEmployee: Bool
    let role: String
    let createdAt: Timestamp
    var isSuspended: Bool = false
}
