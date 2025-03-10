import SwiftUI
import Firebase

struct WishlistView: View {
    @State private var books: [Book] = []
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    if books.isEmpty {
                        Text("Your wishlist is empty.")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ForEach(books, id: \.id) { book in
                            NavigationLink(destination: UserBookDetailView(isbn13: book.isbn13 ?? "-1")) {
                                WishlistItemView(book: book, removeAction: {
                                    removeFromWishlist(bookId: book.id)
                                })
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                        }
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Wishlist")
            .onAppear {
                fetchBooksFromWishlist()
            }
        }
    }
    
    private func fetchBooksFromWishlist() {
        let userId = UserDefaults.standard.string(forKey: "userId") ?? ""
        
        db.collection("wishlist")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching wishlist: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("❌ No wishlist items found for userId: \(userId)")
                    return
                }
                
                let bookIds = documents.compactMap { $0.data()["bookId"] as? String }
                
                DispatchQueue.main.async {
                    self.books.removeAll()
                }
                
                let dispatchGroup = DispatchGroup()
                
                for bookId in bookIds {
                    dispatchGroup.enter()
                    
                    db.collection("books").whereField("bookId", isEqualTo: bookId).getDocuments { snapshot, error in
                        defer { dispatchGroup.leave() }
                        
                        if let error = error {
                            print("❌ Error fetching book \(bookId): \(error.localizedDescription)")
                            return
                        }
                        
                        guard let document = snapshot?.documents.first else {
                            print("❌ No book found for bookId: \(bookId)")
                            return
                        }
                        
                        do {
                            let book = try document.data(as: Book.self)
                            DispatchQueue.main.async {
                                self.books.append(book)
                            }
                        } catch {
                            print("❌ Error decoding book \(bookId): \(error)")
                        }
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    print("✅ All books fetched and updated!")
                }
            }
    }
    
    // 🔥 Remove Book from Wishlist
    private func removeFromWishlist(bookId: String) {
        let userId = UserDefaults.standard.string(forKey: "userId") ?? ""
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
            
            wishlistRef.document(document.documentID).delete { error in
                if let error = error {
                    print("❌ Error removing from wishlist: \(error)")
                } else {
                    DispatchQueue.main.async {
                        self.books.removeAll { $0.id == bookId } // ✅ Remove book from local list
                        print("✅ Book \(bookId) removed from wishlist")
                    }
                }
            }
        }
    }
}

// 🔹 Wishlist Card View
struct WishlistItemView: View {
    var book: Book
    var removeAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .topTrailing) { // 🔥 Keep cross inside the card
                HStack(spacing: 8) {
                    // ✅ Placeholder Image (Replace with AsyncImage if fetching from URL)
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 110)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(book.title)
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Text(book.authors.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text(book.description ?? "")
                            .font(.footnote)
                            .foregroundColor(.black)
                            .lineLimit(2)
                        
                        Button(action: {
                            // Preview action
                        }) {
//                            HStack {
//                                Image(systemName: "book.fill")
//                                Text("Preview")
//                            }
//                            .font(.footnote)
//                            .padding(.horizontal, 12)
//                            .padding(.vertical, 6)
//                            .background(Color.blue.opacity(0.2))
//                            .foregroundColor(.blue)
//                            .cornerRadius(12)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                
                // 🔹 Subtle Grey Cross Button
                Button(action: removeAction) {
                    Image(systemName: "xmark.circle") // 🔥 Subtle cross
                        .foregroundColor(.gray) // 🔥 Grey color
                        .font(.caption) // 🔥 Smaller size
                        .opacity(0.6) // 🔥 Less intrusive
                }
                .padding(6)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Text("")
                        .font(.subheadline)
                        .foregroundColor(.black)
                }
                
                Spacer()
                
//                Image(systemName: "chevron.right")
//                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
            
            //Divider()
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.vertical, 6) // Space between cards
    }
}

// 🔹 Preview
struct Wishlist_Previews: PreviewProvider {
    static var previews: some View {
        WishlistView()
    }
}
