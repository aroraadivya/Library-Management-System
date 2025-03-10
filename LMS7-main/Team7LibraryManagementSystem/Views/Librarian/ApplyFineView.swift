import SwiftUI
import FirebaseFirestore

// MARK: - Issued Book Model
struct LibraryIssuedBook: Identifiable {
    let id: String
    let isbn13: String
    let issueDate: Date
    let dueDate: Date
    let fine: Double
    let status: String
}

// MARK: - Firebase User Manager
class LibraryUserManager: ObservableObject {
    @Published var issuedBooks: [LibraryIssuedBook] = []
    @Published var totalFine: Double = 0.0
    
    private let db = Firestore.firestore()
    
    // Fetch issued books for a user
    func fetchIssuedBooks(for userEmail: String) {
        db.collection("issued_books")
            .whereField("email", isEqualTo: userEmail)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                self.issuedBooks = documents.map { doc in
                    let data = doc.data()
                    return LibraryIssuedBook(
                        id: doc.documentID,
                        isbn13: data["isbn13"] as? String ?? "Unknown",
                        issueDate: (data["issue_date"] as? Timestamp)?.dateValue() ?? Date(),
                        dueDate: (data["due_date"] as? Timestamp)?.dateValue() ?? Date(),
                        fine: data["fine"] as? Double ?? 0.0,
                        status: data["status"] as? String ?? "Unknown"
                    )
                }
                
                // Calculate total fine
                self.totalFine = self.issuedBooks.reduce(0) { $0 + $1.fine }
            }
    }
}

// MARK: - SwiftUI View
struct LibraryFineView: View {
    @StateObject private var userManager = LibraryUserManager()
    let userEmail: String
    
    var body: some View {
        VStack {
            // Total Fine
            Text("Total Fine: ₹\(userManager.totalFine, specifier: "%.2f")")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            List(userManager.issuedBooks) { book in
                HStack {
                    VStack(alignment: .leading) {
                        Text("ISBN: \(book.isbn13)")
                            .font(.headline)
                        Text("Fine: ₹\(book.fine, specifier: "%.2f")")
                            .foregroundColor(.red)
                        Text("Status: \(book.status)")
                            .foregroundColor(book.status == "Borrowed" ? .blue : .green)
                    }
                }
            }
        }
        .onAppear {
            userManager.fetchIssuedBooks(for: userEmail)
        }
    }
}

// MARK: - Preview
struct LibraryFineView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryFineView(userEmail: "v@gmail.com")
    }
}


