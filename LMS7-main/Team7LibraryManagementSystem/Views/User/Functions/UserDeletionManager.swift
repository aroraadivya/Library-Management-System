//
//  UserDeletionManager.swift
//  Team7LibraryManagementSystem
//
//  Created by Rakshit  on 20/02/25.
//

import Foundation

import FirebaseFirestore

class UserDeletionManager {
    private let db = Firestore.firestore()
    private let userRole = UserDefaults.standard.string(forKey: "userRole") ?? ""

    // Admin can delete a librarian in the same library
    func deleteLibrarian(adminEmail: String, librarianEmail: String, completion: @escaping (Bool, String) -> Void) {
        guard userRole == "admin" else {
            completion(false, "Unauthorized action")
            return
        }
        
        let adminsRef = db.collection("admins").whereField("email", isEqualTo: adminEmail)
        let librariansRef = db.collection("librarians").whereField("email", isEqualTo: librarianEmail)
        
        adminsRef.getDocuments { adminSnapshot, adminError in
            if let adminError = adminError {
                completion(false, "Error fetching admin data: \(adminError.localizedDescription)")
                return
            }
            
            guard let adminDoc = adminSnapshot?.documents.first,
                  let adminLibraryId = adminDoc.data()["libraryId"] as? String else {
                completion(false, "Admin not found")
                return
            }
            
            librariansRef.getDocuments { librarianSnapshot, librarianError in
                if let librarianError = librarianError {
                    completion(false, "Error fetching librarian data: \(librarianError.localizedDescription)")
                    return
                }
                
                guard let librarianDoc = librarianSnapshot?.documents.first,
                      let librarianLibraryId = librarianDoc.data()["libraryId"] as? String else {
                    completion(false, "Librarian not found")
                    return
                }
                
                if adminLibraryId == librarianLibraryId {
                    let librarianID = librarianDoc.documentID
                    self.db.collection("librarians").document(librarianID).updateData(["isDeleted": true]) { error in
                        if let error = error {
                            completion(false, "Error deleting librarian: \(error.localizedDescription)")
                        } else {
                            completion(true, "Librarian successfully deleted")
                        }
                    }
                } else {
                    completion(false, "Admin cannot delete librarians from another library")
                }
            }
        }
    }
    
    // Librarian can delete a user
    func deleteUser(librarianEmail: String, userEmail: String, completion: @escaping (Bool, String) -> Void) {
        guard userRole == "librarian" else {
            completion(false, "Unauthorized action")
            return
        }
        
        let librariansRef = db.collection("librarians").whereField("email", isEqualTo: librarianEmail)
        let usersRef = db.collection("users").whereField("email", isEqualTo: userEmail)
        
        librariansRef.getDocuments { librarianSnapshot, librarianError in
            if let librarianError = librarianError {
                completion(false, "Error fetching librarian data: \(librarianError.localizedDescription)")
                return
            }
            
            guard librarianSnapshot?.documents.first != nil else {
                completion(false, "Librarian not found")
                return
            }
            
            usersRef.getDocuments { userSnapshot, userError in
                if let userError = userError {
                    completion(false, "Error fetching user data: \(userError.localizedDescription)")
                    return
                }
                
                guard let userDoc = userSnapshot?.documents.first else {
                    completion(false, "User not found")
                    return
                }
                
                let userID = userDoc.documentID
                self.db.collection("users").document(userID).updateData(["isDeleted": true]) { error in
                    if let error = error {
                        completion(false, "Error deleting user: \(error.localizedDescription)")
                    } else {
                        completion(true, "User successfully deleted")
                    }
                }
            }
        }
    }
    
    // Super Admin can delete anyone
    func deleteAnyUser(superAdminEmail: String, targetEmail: String, targetRole: String, completion: @escaping (Bool, String) -> Void) {
        guard userRole == "super admin" else {
            completion(false, "Unauthorized action")
            return
        }

        let validRoles = ["admins", "librarians", "users"]
        guard validRoles.contains(targetRole) else {
            completion(false, "Invalid role specified")
            return
        }
        
        let targetRef = db.collection(targetRole).whereField("email", isEqualTo: targetEmail)
        
        targetRef.getDocuments { targetSnapshot, error in
            if let error = error {
                completion(false, "Error fetching target data: \(error.localizedDescription)")
                return
            }
            
            guard let targetDoc = targetSnapshot?.documents.first else {
                completion(false, "Target user not found")
                return
            }
            
            let targetID = targetDoc.documentID
            self.db.collection(targetRole).document(targetID).updateData(["isDeleted": true]) { error in
                if let error = error {
                    completion(false, "Error deleting user: \(error.localizedDescription)")
                } else {
                    completion(true, "\(targetRole.capitalized) successfully deleted")
                }
            }
        }
    }
}
