


import SwiftUI
import FirebaseFirestore

class WishlistManager: ObservableObject {
    @Published var wishlist: [String] = [] // Store book IDs
    private var db = Firestore.firestore()
    
   // var userId = "3vdPNzYHz3T7k6fqbmGrkLondNz2" // Replace with actual user authentication
    var userId: String {
        UserDefaults.standard.string(forKey: "userId") ?? ""
    }

    init() {
        fetchWishlist()
    }
    
    func fetchWishlist() {
        db.collection("wishlist")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching wishlist: \(error)")
                    return
                }
                self.wishlist = snapshot?.documents.compactMap { $0["bookId"] as? String } ?? []
            }
    }
    
    func addToWishlist(bookId: String) {
        print("Book id coming from heart = \(bookId)")
        let wishlistRef = db.collection("wishlist")
        let query = wishlistRef
            .whereField("userId", isEqualTo: userId)
            .whereField("bookId", isEqualTo: bookId)
        
        query.getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error checking wishlist: \(error)")
                return
            }
            
            if snapshot?.documents.isEmpty == false {
                print("⚠️ Book already in wishlist")
                return
            }
            
            // Add book to wishlist
            wishlistRef.addDocument(data: [
                "userId": self.userId,
                "bookId": bookId
            ]) { error in
                if let error = error {
                    print("❌ Error adding to wishlist: \(error)")
                } else {
                    DispatchQueue.main.async {
                        self.wishlist.append(bookId)
                        print("✅ Book \(bookId) added to wishlist")
                        self.fetchWishlist()
                    }
                }
            }
        }
    }
    
    
    func checkIfBookIsInWishlist(bookId: String, completion: @escaping (Bool) -> Void) {
        let wishlistRef = db.collection("wishlist")
        let query = wishlistRef
            .whereField("userId", isEqualTo: userId)
            .whereField("bookId", isEqualTo: bookId)

        query.getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error checking wishlist: \(error)")
                completion(false)
                return
            }

            let isInWishlist = !(snapshot?.documents.isEmpty ?? true)
            print("🟢 Checking if book \(bookId) is in wishlist: \(isInWishlist)")
            completion(isInWishlist)
        }
    }

    
    func removeFromWishlist(bookId: String) {
        let wishlistRef = db.collection("wishlist")
        let query = wishlistRef
            .whereField("userId", isEqualTo: userId)
            .whereField("bookId", isEqualTo: bookId)
        
        query.getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error finding wishlist entry: \(error)")
                return
            }
            
            guard let document = snapshot?.documents.first else {
                print("⚠️ Wishlist entry not found")
                return
            }
            
            // Delete the document
            wishlistRef.document(document.documentID).delete { error in
                if let error = error {
                    print("❌ Error removing from wishlist: \(error)")
                } else {
                    DispatchQueue.main.async {
                        self.wishlist.removeAll { $0 == bookId }
                        print("✅ Book \(bookId) removed from wishlist")
                        self.fetchWishlist()
                    }
                }
            }
        }
    }
}
