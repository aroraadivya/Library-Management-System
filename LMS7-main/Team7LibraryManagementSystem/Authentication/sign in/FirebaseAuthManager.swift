//
//  FirebaseAuthManager.swift
//  Team7test
//
//  Created by Hardik Bhardwaj on 13/02/25.
//

import FirebaseAuth
import FirebaseFirestore
import Network
class FirebaseAuthManager {
    static let shared = FirebaseAuthManager()
    
    private init() {}
    
    
    func fetchUserId(email: String, role: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        
        // Determine the collection name based on the role
        let collectionName: String
        switch role.lowercased() {
        case "admin":
            collectionName = "admins"
        case "librarian":
            collectionName = "librarians"
        case "user":
            collectionName = "users"
        default:
            print("❌ Invalid role: \(role)")
            completion(nil)
            return
        }
        
        print("Querying Firestore for email: \(email) in collection: \(collectionName)")
        
        // Query the appropriate collection
        db.collection(collectionName)
            .whereField("email", isEqualTo: email)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching user ID: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    print("❌ No document found for email: \(email) in collection: \(collectionName)")
                    completion(nil)
                    return
                }
                
                // Fetch the userId field
                let userId = document.data()["userId"] as? String
                if userId == nil {
                    print("❌ userId field is missing in the document")
                } else {
                    print("✅ Fetched userId: \(userId!) from collection: \(collectionName)")
                }
                completion(userId)
            }
    }
    
     func verifyUserRole(email: String, role: String, completion: @escaping (Bool, String) -> Void) {
        let collectionName: String
        
        switch role.lowercased() {
        case "admin":
            collectionName = "admins"
        case "librarian":
            collectionName = "librarians"
        case "user":
            collectionName = "users"
        default:
            completion(false, "Invalid role selection")
            return
        }
        
        let db = Firestore.firestore()
        db.collection(collectionName).whereField("email", isEqualTo: email).getDocuments { snapshot, error in
            if let error = error {
                completion(false, "Error checking role: \(error.localizedDescription)")
            } else if let snapshot = snapshot, !snapshot.documents.isEmpty {
                completion(true, "")
            } else {
                completion(false, "Access denied: Email does not belong to the selected role")
            }
        }
    }
    
    
    
    
    
    
    func signIn(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Check network connectivity first
        guard NetworkMonitor.shared.isConnected else {
            completion(.failure(NSError(domain: "", code: -1009, userInfo: [NSLocalizedDescriptionKey: "No internet connection. Please check your network and try again."])))
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let userId = authResult?.user.uid else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])))
                return
            }
            
            let db = Firestore.firestore()
            
            // First check admins collection
            db.collection("admins").whereField("email", isEqualTo: email).getDocuments { snapshot, error in
                if let error = error {
                    if (error as NSError).code == 50 { // Network is down error
                        completion(.failure(NSError(domain: "", code: -1009, userInfo: [NSLocalizedDescriptionKey: "Network connection lost. Please try again."])))
                        return
                    }
                    completion(.failure(error))
                    return
                }
                
                if let document = snapshot?.documents.first {
                    completion(.success("admins"))
                    return
                }
                
                // If not admin, check librarians collection
                db.collection("librarians").whereField("email", isEqualTo: email).getDocuments { snapshot, error in
                    if let document = snapshot?.documents.first {
                        let data = document.data()
                        let role = data["role"] as? String ?? ""
                        completion(.success(role))
                    } else {
                        completion(.success("user"))
                    }
                }
            }
        }
    }
}

// Create a NetworkMonitor class
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    @Published private(set) var isConnected = true
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }

    
    // Sign Out
    func signOut() -> Error? {
        do {
            try Auth.auth().signOut()
            return nil
        } catch let error {
            return error
        }
    }
    
    // Add the resetPassword function
    func resetPassword(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
