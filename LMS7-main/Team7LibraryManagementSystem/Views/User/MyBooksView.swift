import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MyBooksView: View {
    @State private var issuedBooks: [Book] = []
    let columns = [GridItem(.flexible()), GridItem(.flexible())] // Two-column grid layout
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(issuedBooks, id: \.id) { book in
                            NavigationLink(destination: UserBookDetailView(isbn13: book.isbn13 ?? "-1")) {
                                MyBookCardView(
                                    imageUrl: book.coverImageUrl,
                                    title: book.title,
                                    author: book.authors.first ?? "Unknown Author",
                                    description: book.description ?? "No description available.",
                                    status: book.status,
                                    statusColor: getStatusColor(for: book.status),
                                    fine: book.status == "Overdue" ? "₹50" : nil
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                //.padding(.top, 10)
            }
            .navigationTitle("My Books")
            .onAppear {
                fetchIssuedBookISBNs()
            }
        }
    }


    private func fetchIssuedBookISBNs() {
        let db = Firestore.firestore()
        guard let userEmail = Auth.auth().currentUser?.email else {
            print("No logged-in user found")
            return
        }
        
        var allBooksData: [(String, String)] = []
        let dispatchGroup = DispatchGroup()
        
        // Fetch issued books
        dispatchGroup.enter()
        db.collection("issued_books").whereField("email", isEqualTo: userEmail).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching issued book ISBNs: ", error)
            } else {
                let issuedBooksData = snapshot?.documents.compactMap { doc -> (String, String)? in
                    if let isbn = doc.data()["isbn13"] as? String,
                       let status = doc.data()["status"] as? String {
                        return (isbn, status)
                    }
                    return nil
                } ?? []
                
                allBooksData.append(contentsOf: issuedBooksData)
            }
            dispatchGroup.leave()
        }
        
        // Fetch prebooked books
        dispatchGroup.enter()
        db.collection("PreBook").whereField("userEmail", isEqualTo: userEmail).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching prebooked books: ", error)
            } else {
                let prebookedBooksData = snapshot?.documents.compactMap { doc -> (String, String)? in
                    if let isbn = doc.data()["isbn13"] as? String,
                       var prebookStatus = doc.data()["status"] as? String,
                       let expiresAtTimestamp = doc.data()["expiresAt"] as? Timestamp,
                       let libraryId = doc.data()["libraryId"] as? String {  // Ensure libraryId is available

                        let currentTime = Timestamp(date: Date())

                        // Check if expiresAt time has passed
                        if expiresAtTimestamp.seconds < currentTime.seconds && prebookStatus != "Confirmed" {
                            prebookStatus = "Time Over"
                            updatePreBookStatusToTimeOver(forEmail: userEmail, libraryId: libraryId) { success, error in
                                if success {
                                    print("Successfully updated PreBook status for ISBN: \(isbn)")
                                } else {
                                    print("Failed to update PreBook status for ISBN: \(isbn). Error: \(error?.localizedDescription ?? "Unknown error")")
                                }
                            }
                        } else {
                            // Determine display status based on prebook status
                            switch prebookStatus {
                            case "Pending":
                                prebookStatus = "PreBooked"
                            case "Confirmed":
                                prebookStatus = "PreBook Confirmed"
                            default:
                                prebookStatus = "Unknown"
                            }
                        }
                        
                        return (isbn, prebookStatus)
                    }
                    return nil
                } ?? []
                
                allBooksData.append(contentsOf: prebookedBooksData)
            }
            dispatchGroup.leave()
        }
        
        // Once both issued and prebooked books are fetched, retrieve their details
        dispatchGroup.notify(queue: .main) {
            fetchBookDetails(allBooksData)
        }
    }

    
    func updatePreBookStatusToTimeOver(forEmail userEmail: String, libraryId: String, completion: @escaping (Bool, Error?) -> Void) {
        let db = Firestore.firestore()
        
        let preBookRef = db.collection("PreBook")
            .whereField("userEmail", isEqualTo: userEmail)
            .whereField("libraryId", isEqualTo: libraryId)
        
        preBookRef.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching prebook document: \(error.localizedDescription)")
                completion(false, error)
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("No matching PreBook document found.")
                completion(false, nil)
                return
            }
            
            let currentTime = Timestamp(date: Date())
            
            for document in documents {
                let docRef = document.reference
                
                if let expiresAt = document.data()["expiresAt"] as? Timestamp {
                    if expiresAt.seconds < currentTime.seconds {
                        // Update the status to "Time Over"
                        docRef.updateData(["status": "Time Over"]) { error in
                            if let error = error {
                                print("Error updating document status: \(error.localizedDescription)")
                                completion(false, error)
                            } else {
                                print("Successfully updated status to Time Over for document: \(document.documentID)")
                                completion(true, nil)
                            }
                        }
                    }
                }
            }
        }
    }


//
    /// Fetches book details from the "books" collection using ISBNs
    private func fetchBookDetails(_ issuedBooksData: [(String, String)]) {
        let db = Firestore.firestore()
        let isbnList = issuedBooksData.map { $0.0 } // Extract ISBNs only
        
        guard !isbnList.isEmpty else {
            print("No ISBNs found for issued books")
            return
        }
        
        db.collection("books").whereField("isbn13", in: isbnList).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching book details: ", error)
                return
            }
            
            let bookData = snapshot?.documents.compactMap { doc -> Book? in
                let data = doc.data()
                let isbn = data["isbn13"] as? String ?? ""
                
                // Get status from issuedBooksData
                let status = issuedBooksData.first(where: { $0.0 == isbn })?.1 ?? "Unknown"
                
                // Get coverImageUrl - this could be a regular URL or base64 string
                let coverImageUrl = data["coverImageUrl"] as? String
                
                return Book(
                    id: data["bookId"] as? String ?? UUID().uuidString,
                    title: data["title"] as? String ?? "Unknown Title",
                    authors: data["authors"] as? [String] ?? ["Unknown Author"],
                    publisher: data["publisher"] as? String,
                    publishedDate: data["publishedDate"] as? String,
                    description: data["description"] as? String,
                    pageCount: data["pageCount"] as? Int,
                    categories: data["categories"] as? [String],
                    coverImageUrl: coverImageUrl, // This could be base64 or regular URL
                    isbn13: isbn,
                    language: data["language"] as? String,
                    quantity: data["quantity"] as? Int ?? 0,
                    availableQuantity: data["availableQuantity"] as? Int ?? 0,
                    location: data["location"] as? String ?? "Unknown",
                    status: status, // Set independent status
                    totalCheckouts: data["totalCheckouts"] as? Int ?? 0,
                    currentlyBorrowed: data["currentlyBorrowed"] as? Int ?? 0,
                    isAvailable: data["isAvailable"] as? Bool ?? false,
                    libraryId: data["libraryId"] as? String
                )
            } ?? []
            
            issuedBooks = bookData
        }
    }

    
    private func getStatusColor(for status: String) -> Color {
        switch status {
        case "Borrowed":
            return .green
        case "Returned":
            return .gray
        case "Overdue":
            return .red
        case "PreBooked":
            return .blue
        case "Not Collected":
            return .orange
        case "PreBook Confirmed":
            return .green
        default:
            return .gray
        }
    }

    
    struct MyBookCardView: View {
        var imageUrl: String? // Changed from imageName to imageUrl to better reflect what it is
        var title: String
        var author: String
        var description: String
        var status: String
        var statusColor: Color
        var fine: String? = nil
        
        // State for decoded image
        @State private var decodedImage: UIImage? = nil
        
        var body: some View {
            VStack(alignment: .leading) {
                // Cover image handling both remote URLs and base64
                if let decodedImage = decodedImage {
                    // Show decoded base64 image
                    Image(uiImage: decodedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180)
                        .cornerRadius(10)
                        .padding(.horizontal, 10)
                } else if let imageUrl = imageUrl, !imageUrl.isEmpty {
                    // Show remote image or handle placeholder
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                        case .empty, .failure:
                            // Placeholder when image can't be loaded
                            Image(systemName: "book.fill")
                                .resizable()
                                .scaledToFit()
                                .padding(40)
                                .foregroundColor(.gray.opacity(0.5))
                        @unknown default:
                            ProgressView()
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180)
                    .cornerRadius(10)
                    .padding(.horizontal, 10)
                } else {
                    // Placeholder when no image is available
                    Image(systemName: "book.fill")
                        .resizable()
                        .scaledToFit()
                        .padding(40)
                        .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180)
                        .cornerRadius(10)
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.horizontal, 10)
                }
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
                
                Text(author)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(description)
                    .font(.footnote)
                    .foregroundColor(.black)
                    .lineLimit(2)
                
                Spacer()
                
                // Status Badge
                HStack(spacing: 8) {
                    Text(status)
                        .font(.footnote)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(8)
                    
                    if let fine = fine {
                        Text("Fine: \(fine)")
                            .font(.footnote)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            .onAppear {
                // Try to decode base64 image if available
                decodeBase64Image()
            }
        }
        
        // Decode base64 image if present in imageUrl
        private func decodeBase64Image() {
            if let imageUrl = imageUrl,
               imageUrl.starts(with: "data:image") || imageUrl.hasPrefix("data:image") {
                // Extract base64 part after comma
                let components = imageUrl.components(separatedBy: ",")
                if components.count > 1,
                   let imageData = Data(base64Encoded: components[1]) {
                    decodedImage = UIImage(data: imageData)
                }
            }
        }
    }
}

#Preview{
    MyBooksView()
}
