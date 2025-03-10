//import SwiftUI
//import FirebaseAuth
//import FirebaseFirestore
//
//struct UserBooksViewForLibrarian: View {
//    var userId: String
//    @State private var issuedBooks: [Book] = []
//    @State private var userName: String = ""
//    let columns = [GridItem(.flexible()), GridItem(.flexible())] // Two-column grid layout
//    
//    var body: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 16) {
//                LazyVGrid(columns: columns, spacing: 16) {
//                    ForEach(issuedBooks, id: \.id) { book in
//                        NavigationLink(destination: FineManagementView(book: book, userId: userId)) {
//                            MyBookCardViewforLibrarian(
//                                imageName: book.coverImageUrl ?? "default_cover",
//                                title: book.title,
//                                author: book.authors.first ?? "Unknown Author",
//                                description: book.description ?? "No description available.",
//                                status: book.status,
//                                statusColor: book.status == "Overdue" ? .red : (book.status == "Currently Issued" ? .green : .gray),
//                                fine: book.status == "Overdue" ? "₹50" : nil
//                            )
//                        }
//                        .buttonStyle(PlainButtonStyle())
//                    }
//                }
//                .padding(.horizontal)
//            }
//            .padding(.top, 10)
//        }
//        .navigationTitle(userName.isEmpty ? "User's Books" : "\(userName)'s Books")
//        .onAppear {
//            fetchUserDetails()
//        }
//    }
//    
//    private func fetchUserDetails() {
//        let db = Firestore.firestore()
//        db.collection("users").document(userId).getDocument { document, error in
//            if let error = error {
//                print("Error fetching user details: \(error.localizedDescription)")
//                return
//            }
//            
//            if let document = document, document.exists, let data = document.data() {
//                // Get user's name
//                let firstName = data["firstName"] as? String ?? ""
//                let lastName = data["lastName"] as? String ?? ""
//                self.userName = firstName + " " + lastName
//                
//                // Get user's email and fetch books
//                if let email = data["email"] as? String {
//                    fetchIssuedBookISBNs(email: email)
//                } else {
//                    print("Email not found for userId: \(userId)")
//                }
//            }
//        }
//    }
//    
//    private func fetchIssuedBookISBNs(email: String) {
//        let db = Firestore.firestore()
//        db.collection("issued_books").whereField("email", isEqualTo: email).getDocuments { snapshot, error in
//            if let error = error {
//                print("Error fetching issued book ISBNs: ", error)
//                return
//            }
//            
//            let isbnList = snapshot?.documents.compactMap { $0.data()["isbn13"] as? String } ?? []
//            fetchBookDetails(isbnList)
//        }
//    }
//    
//    private func fetchBookDetails(_ isbnList: [String]) {
//        let db = Firestore.firestore()
//        
//        guard !isbnList.isEmpty else {
//            print("No ISBNs found for issued books")
//            return
//        }
//        
//        db.collection("books").whereField("isbn13", in: isbnList).getDocuments { snapshot, error in
//            if let error = error {
//                print("Error fetching book details: ", error)
//                return
//            }
//            
//            issuedBooks = snapshot?.documents.compactMap { doc in
//                let data = doc.data()
//                return Book(
//                    id: data["bookId"] as? String ?? UUID().uuidString,
//                    title: data["title"] as? String ?? "Unknown Title",
//                    authors: data["authors"] as? [String] ?? ["Unknown Author"],
//                    publisher: data["publisher"] as? String,
//                    publishedDate: data["publishedDate"] as? String,
//                    description: data["description"] as? String,
//                    pageCount: data["pageCount"] as? Int,
//                    categories: data["categories"] as? [String],
//                    coverImageUrl: data["coverImageUrl"] as? String,
//                    isbn13: data["isbn13"] as? String,
//                    language: data["language"] as? String,
//                    quantity: data["quantity"] as? Int ?? 0,
//                    availableQuantity: data["availableQuantity"] as? Int ?? 0,
//                    location: data["location"] as? String ?? "Unknown",
//                    status: data["status"] as? String ?? "Unknown",
//                    totalCheckouts: data["totalCheckouts"] as? Int ?? 0,
//                    currentlyBorrowed: data["currentlyBorrowed"] as? Int ?? 0,
//                    isAvailable: data["isAvailable"] as? Bool ?? false,
//                    libraryId: data["libraryId"] as? String
//                )
//            } ?? []
//        }
//    }
//}
//
//struct MyBookCardViewforLibrarian: View {
//    var imageName: String
//    var title: String
//    var author: String
//    var description: String
//    var status: String
//    var statusColor: Color
//    var fine: String? = nil
//    
//    var body: some View {
//        VStack(alignment: .leading) {
//            Image(imageName)
//                .resizable()
//                .scaledToFit()
//                .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180)
//                .cornerRadius(10)
//                .padding(.horizontal, 10)
//            
//            Text(title)
//                .font(.headline)
//                .foregroundColor(.black)
//            
//            Text(author)
//                .font(.subheadline)
//                .foregroundColor(.gray)
//            
//            Text(description)
//                .font(.footnote)
//                .foregroundColor(.black)
//                .lineLimit(2)
//            
//            Spacer()
//            
//            HStack(spacing: 8) {
//                Text(status)
//                    .font(.footnote)
//                    .padding(.horizontal, 8)
//                    .padding(.vertical, 4)
//                    .background(statusColor.opacity(0.2))
//                    .foregroundColor(statusColor)
//                    .cornerRadius(8)
//                
//                if let fine = fine {
//                    Text("Fine: \(fine)")
//                        .font(.footnote)
//                        .padding(.horizontal, 8)
//                        .padding(.vertical, 4)
//                        .background(Color.red.opacity(0.2))
//                        .foregroundColor(.red)
//                        .cornerRadius(8)
//                }
//            }
//        }
//        .frame(maxWidth: .infinity)
//        .padding()
//        .background(Color.white)
//        .cornerRadius(12)
//        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
//    }
//}
//
//#Preview {
//    UserBooksViewForLibrarian(userId: "exampleUserId")
//}
//
