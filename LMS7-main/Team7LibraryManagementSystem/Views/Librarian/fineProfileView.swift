////
////  UserProfileView.swift
////  Team7LibraryManagementSystem
////
////  Created by Hardik Bhardwaj on 27/02/25.
////
//
//
//import SwiftUI
//import FirebaseFirestore
//struct UserProfileViewLibrarian: View {
//    var userID: String // Passed from previous screen
//    @State private var userName: String = "John Doe"
//    @State private var userEmail: String = "user@example.com"
//    @State private var totalFine: Double = 0.0
//    @State private var borrowedBooks: [LibraryBookLibrarian] = []
//
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 15) {
//                // User Info
//                VStack {
//                    Text(userName)
//                        .font(.title)
//                        .fontWeight(.bold)
//
//                    Text(userEmail)
//                        .font(.headline)
//                        .foregroundColor(.gray)
//                }
//                .padding(.top, 10)
//
//                // Fine Card
//                VStack(spacing: 5) {
//                    Text("Total Imposed Fine")
//                        .font(.headline)
//                        .foregroundColor(.gray)
//
//                    Text("$\(totalFine, specifier: "%.2f")")
//                        .font(.title)
//                        .fontWeight(.bold)
//                        .foregroundColor(.red)
//                }
//                .padding(12)
//                .frame(maxWidth: .infinity)
//                .background(Color.white)
//                .cornerRadius(12)
//
//                // Borrowed Books Section
//                VStack(alignment: .leading, spacing: 10) {
//                    Text("Borrowed Books")
//                        .font(.title2)
//                        .fontWeight(.bold)
//                        .padding(.horizontal)
//
//                    ForEach(borrowedBooks, id: \.isbn) { book in
//                        BookCardLibrarian(book: book, returnAction: {
//                                                  returnBook(email: userEmail, isbn: book.isbn)
//                                              })
//                    }
//                }
//                .padding(.top, 10)
//            }
//            .padding()
//            .background(Color(.systemGray6))
//        }
//        .onAppear {
//            fetchUserData()
//        }
//    }
//    
//    func returnBook(email: String, isbn: String) {
//           let db = Firestore.firestore()
//
//           db.collection("issued_books")
//               .whereField("email", isEqualTo: email)
//               .whereField("isbn13", isEqualTo: isbn)
//               .getDocuments { snapshot, error in
//                   guard let documents = snapshot?.documents, !documents.isEmpty, error == nil else {
//                       print("❌ Error finding issued book: \(error?.localizedDescription ?? "Unknown error")")
//                       return
//                   }
//
//                   for document in documents {
//                       document.reference.updateData(["status": "Returned"]) { error in
//                           if let error = error {
//                               print("❌ Error updating book status: \(error.localizedDescription)")
//                           } else {
//                               print("✅ Book marked as Returned!")
//
//                               // Update Available Quantity
//                               updateBookAvailability(isbn: isbn, db: db)
//                           }
//                       }
//                   }
//               }
//       }
//
//       // Update Book Availability
//       func updateBookAvailability(isbn: String, db: Firestore) {
//           db.collection("books")
//               .whereField("isbn13", isEqualTo: isbn)
//               .getDocuments { snapshot, error in
//                   guard let document = snapshot?.documents.first, error == nil else {
//                       print("❌ Error fetching book for quantity update: \(error?.localizedDescription ?? "Unknown error")")
//                       return
//                   }
//
//                   let currentQuantity = document.data()["availableQuantity"] as? Int ?? 0
//
//                   document.reference.updateData(["availableQuantity": currentQuantity + 1]) { error in
//                       if let error = error {
//                           print("❌ Error updating available quantity: \(error.localizedDescription)")
//                       } else {
//                           print("✅ Book quantity updated successfully!")
//
//                           DispatchQueue.main.async {
//                               self.borrowedBooks.removeAll { $0.isbn == isbn }
//                           }
//                       }
//                   }
//               }
//       }
//
//    // Fetch User Email using `userId`
//    func fetchUserEmail(userID: String, completion: @escaping (String?) -> Void) {
//        let db = Firestore.firestore()
//        
//        print("Fetching email for user ID: \(userID)")
//        
//        db.collection("users")
//            .whereField("userId", isEqualTo: userID)
//            .getDocuments { snapshot, error in
//                if let error = error {
//                    print("Error fetching user email: \(error.localizedDescription)")
//                    completion(nil)
//                    return
//                }
//                
//                guard let document = snapshot?.documents.first else {
//                    print("User document not found")
//                    completion(nil)
//                    return
//                }
//                
//                let email = document.data()["email"] as? String
//                completion(email)
//            }
//    }
//
//    func fetchUserData() {
//        let db = Firestore.firestore()
//        
//        fetchUserEmail(userID: userID) { email in
//            guard let email = email else {
//                print("Email not found")
//                return
//            }
//            
//            DispatchQueue.main.async {
//                self.userEmail = email
//            }
//
//            print("Updated User Email: \(email)")
//            
//            // Now, fetch issued books AFTER the email is updated
//            db.collection("issued_books")
//                .whereField("email", isEqualTo: email) // Use updated email
//                .getDocuments { snapshot, error in
//                    guard let documents = snapshot?.documents, error == nil else {
//                        print("Error fetching issued books: \(error?.localizedDescription ?? "Unknown error")")
//                        return
//                    }
//                    
//                    var totalFineAmount: Double = 0
//                    var bookISBNs: [String] = []
//                    
//                    for document in documents {
//                        let data = document.data()
//                        totalFineAmount += (data["fine"] as? Double ?? 0)
//                        if let isbn = data["isbn13"] as? String {
//                            bookISBNs.append(isbn)
//                        }
//                    }
//                    
//                    DispatchQueue.main.async {
//                        self.totalFine = totalFineAmount
//                    }
//
//                    // Fetch book details only if ISBNs exist
//                    if !bookISBNs.isEmpty {
//                        self.fetchBookDetails(isbns: bookISBNs)
//                    } else {
//                        print("No books found for user.")
//                    }
//                }
//        }
//    }
//
//
//    // Fetch issued books for a specific email
//    func fetchIssuedBooks(for email: String) {
//        let db = Firestore.firestore()
//
//        db.collection("issued_books")
//            .whereField("email", isEqualTo: email)
//            .getDocuments { snapshot, error in
//                guard let documents = snapshot?.documents, error == nil else {
//                    print("Error fetching issued books: \(error?.localizedDescription ?? "Unknown error")")
//                    return
//                }
//
//                var totalFineAmount: Double = 0
//                var bookISBNs: [String] = []
//
//                for document in documents {
//                    let data = document.data()
//                    totalFineAmount += (data["fine"] as? Double ?? 0)
//
//                    if let isbn = data["isbn13"] as? String {
//                        bookISBNs.append(isbn)
//                    }
//                }
//
//                DispatchQueue.main.async {
//                    self.totalFine = totalFineAmount
//                }
//
//                // Fetch book details
//                fetchBookDetails(isbns: bookISBNs)
//            }
//    }
//
//    // Fetch Book Details from Books Collection and Update UI
//    func fetchBookDetails(isbns: [String]) {
//        let db = Firestore.firestore()
//        var books: [LibraryBookLibrarian] = []
//
//        let group = DispatchGroup()
//
//        for isbn in isbns {
//            group.enter()
//            db.collection("books")
//                 .whereField("isbn13", isEqualTo: isbn)
//                .getDocuments { snapshot, error in
//                    defer { group.leave() }
//
//                    guard let document = snapshot?.documents.first, error == nil else {
//                        print("Book not found for ISBN: \(isbn)")
//                        return
//                    }
//
//                    let data = document.data()
//
//                    let book = LibraryBookLibrarian(
//                        isbn: isbn,
//                        title: data["title"] as? String ?? "Unknown Title",
//                        author: data["author"] as? String ?? "Unknown Author",
//                        image: "book.fill" // Placeholder image
//                    )
//
//                    DispatchQueue.main.async {
//                        books.append(book)
//                    }
//                }
//        }
//
//        group.notify(queue: .main) {
//            DispatchQueue.main.async {
//                self.borrowedBooks = books // Ensure books are updated properly
//            }
//        }
//    }
//}
//
//// MARK: - LibraryBookLibrarian Model
//struct LibraryBookLibrarian: Identifiable {
//    var id: String { isbn }
//    var isbn: String
//    var title: String
//    var author: String
//    var image: String
//}
//
//// MARK: - BookCardLibrarian View
//struct BookCardLibrarian: View {
//    var book: LibraryBookLibrarian
//    var returnAction: () -> Void
//    var body: some View {
//        HStack(spacing: 12) {
//            Image(systemName: book.image)
//                .resizable()
//                .scaledToFit()
//                .frame(width: 50, height: 70)
//                .background(Color.white)
//                .cornerRadius(6)
//
//            VStack(alignment: .leading, spacing: 3) {
//                Text(book.title)
//                    .font(.headline)
//                    .lineLimit(1)
//                    .truncationMode(.tail)
//                Text(book.author)
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//                    .lineLimit(1)
//                    .truncationMode(.tail)
//            }
//            Spacer()
//
//            Button(action:
//                returnAction
//                // Handle return book action
//            ) {
//                Text("Return")
//                    .font(.subheadline)
//                    .fontWeight(.bold)
//                    .padding(.horizontal, 12)
//                    .padding(.vertical, 6)
//                    .background(Color.red)
//                    .foregroundColor(.white)
//                    .cornerRadius(6)
//            }
//        }
//        .padding(.horizontal)
//        .padding(.vertical, 10)
//        .background(Color.white)
//        .cornerRadius(10)
//        .padding(.horizontal, 10)
//    }
//}
//
//
//
//
//// MARK: - Preview
//struct UserProfileViewLibrarian_Previews: PreviewProvider {
//    static var previews: some View {
//        UserProfileViewLibrarian(userID: "sampleUserID")
//    }
//}


import SwiftUI
import FirebaseFirestore

struct UserProfileViewLibrarian: View {
    var userID: String // Passed from previous screen
    @State private var userName: String = "John Doe"
    @State private var userEmail: String = "user@example.com"
    @State private var totalFine: Double = 0.0
    @State private var borrowedBooks: [LibraryBookLibrarian] = []
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // User Profile Header
                VStack(spacing: 16) {
                    // User Avatar
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 4) {
                        Text(userName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(userEmail)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal)
                
                // Fine Card
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.title2)
                            .foregroundColor(totalFine > 0 ? .red : .green)
                        
                        Text("Total Imposed Fine")
                            .font(.headline)
                    }
                    
                    Text("$\(totalFine, specifier: "%.2f")")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(totalFine > 0 ? .red : .green)
                        .padding(.bottom, 4)
                    
                    if totalFine > 0 {
                        Text("Please pay at the library counter")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No pending fine")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal)
                
                // Borrowed Books Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Borrowed Books")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text("\(borrowedBooks.count) books")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    if borrowedBooks.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "books.vertical")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary.opacity(0.5))
                            
                            Text("No books borrowed")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    } else {
                        ForEach(borrowedBooks) { book in
                            BookCardLibrarian(book: book, returnAction: {
                                returnBook(email: userEmail, isbn: book.isbn)
                            })
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("User Fine")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchUserData()
        }
    }
    
    
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 20) {
//                // User Profile Header
//                VStack(spacing: 16) {
//                    // User Avatar
//                    Image(systemName: "person.circle.fill")
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .frame(width: 80, height: 80)
//                        .foregroundColor(.blue)
//                    
//                    VStack(spacing: 4) {
//                        Text(userName)
//                            .font(.title2)
//                            .fontWeight(.bold)
//                        
//                        Text(userEmail)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                }
//                .frame(maxWidth: .infinity)
//                .padding(.vertical, 24)
//                .background(
//                    RoundedRectangle(cornerRadius: 16)
//                        .fill(Color(.systemBackground))
//                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
//                )
//                .padding(.horizontal)
//                
//                // Fine Card
//                VStack(spacing: 10) {
//                    HStack {
//                        Image(systemName: "dollarsign.circle.fill")
//                            .font(.title2)
//                            .foregroundColor(totalFine > 0 ? .red : .green)
//                        
//                        Text("Total Imposed Fine")
//                            .font(.headline)
//                    }
//                    
//                    Text("$\(totalFine, specifier: "%.2f")")
//                        .font(.system(size: 36, weight: .bold, design: .rounded))
//                        .foregroundColor(totalFine > 0 ? .red : .green)
//                        .padding(.bottom, 4)
//                    
//                    if totalFine > 0 {
//                        Text("Please pay at the library counter")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                    } else {
//                        Text("No pending fine")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                    }
//                }
//                .frame(maxWidth: .infinity)
//                .padding(.vertical, 20)
//                .background(
//                    RoundedRectangle(cornerRadius: 16)
//                        .fill(Color(.systemBackground))
//                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
//                )
//                .padding(.horizontal)
//                
//                // Borrowed Books Section
//                VStack(alignment: .leading, spacing: 16) {
//                    HStack {
//                        Text("Borrowed Books")
//                            .font(.title3)
//                            .fontWeight(.bold)
//                        
//                        Spacer()
//                        
//                        Text("\(borrowedBooks.count) books")
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                    .padding(.horizontal)
//                    
//                    if borrowedBooks.isEmpty {
//                        VStack(spacing: 12) {
//                            Image(systemName: "books.vertical")
//                                .font(.system(size: 40))
//                                .foregroundColor(.secondary.opacity(0.5))
//                            
//                            Text("No books borrowed")
//                                .font(.headline)
//                                .foregroundColor(.secondary)
//                        }
//                        .frame(maxWidth: .infinity)
//                        .padding(.vertical, 40)
//                        .background(
//                            RoundedRectangle(cornerRadius: 12)
//                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
//                        )
//                        .padding(.horizontal)
//                    } else {
//                        ForEach(borrowedBooks) { book in
//                            BookCardLibrarian(book: book, returnAction: {
//                                returnBook(email: userEmail, isbn: book.isbn)
//                            })
//                        }
//                    }
//                }
//            }
//            .padding(.vertical)
//        }
//        .background(Color(.systemGroupedBackground).ignoresSafeArea())
//        .navigationTitle("User Fine")
//        .navigationBarTitleDisplayMode(.inline)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarTrailing) {
//                Button(role: .destructive) {
//                    showDeleteConfirmation = true
//                } label: {
//                    Image(systemName: "trash")
//                }
//            }
//        }
//        .alert("Delete User", isPresented: $showDeleteConfirmation) {
//            Button("Cancel", role: .cancel) { }
//            Button("Delete", role: .destructive) {
//               // deleteUser()
//                UserDeletionManager.shared.deleteUser(email: userEmail)
//            }
//        } message: {
//            Text("Are you sure you want to delete this user? This action cannot be undone.")
//        }
//        .onAppear {
//            fetchUserData()
//        }
//    }
    
    // Existing functions remain the same
    func returnBook(email: String, isbn: String) {
        let db = Firestore.firestore()
        
        db.collection("issued_books")
            .whereField("email", isEqualTo: email)
            .whereField("isbn13", isEqualTo: isbn)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents, !documents.isEmpty, error == nil else {
                    print("❌ Error finding issued book: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                for document in documents {
                    document.reference.updateData(["status": "Returned"]) { error in
                        if let error = error {
                            print("❌ Error updating book status: \(error.localizedDescription)")
                        } else {
                            print("✅ Book marked as Returned!")
                            
                            // Update Available Quantity
                            updateBookAvailability(isbn: isbn, db: db)
                        }
                    }
                }
            }
    }
    
    // Update Book Availability
    func updateBookAvailability(isbn: String, db: Firestore) {
        db.collection("books")
            .whereField("isbn13", isEqualTo: isbn)
            .getDocuments { snapshot, error in
                guard let document = snapshot?.documents.first, error == nil else {
                    print("❌ Error fetching book for quantity update: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let currentQuantity = document.data()["availableQuantity"] as? Int ?? 0
                
                document.reference.updateData(["availableQuantity": currentQuantity + 1]) { error in
                    if let error = error {
                        print("❌ Error updating available quantity: \(error.localizedDescription)")
                    } else {
                        print("✅ Book quantity updated successfully!")
                        
                        DispatchQueue.main.async {
                            self.borrowedBooks.removeAll { $0.isbn == isbn }
                        }
                    }
                }
            }
    }
    
    // Fetch User Email using `userId`
    func fetchUserEmail(userID: String, completion: @escaping (String?,String?,String?) -> Void) {
        let db = Firestore.firestore()
        
        print("Fetching email for user ID: \(userID)")
        
        db.collection("users")
            .whereField("userId", isEqualTo: userID)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching user email: \(error.localizedDescription)")
                    completion(nil,nil,nil)
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    print("User document not found")
                    completion(nil,nil,nil)
                    return
                }
                
                let email = document.data()["email"] as? String
                
                let firstName = document.data()["firstName"] as? String
                let lastName = document.data()["lastName"] as? String
                
                completion(email, firstName, lastName)
               
                
               // completion(email)
            }
    }
    func fetchUserData() {
        let db = Firestore.firestore()
        
        fetchUserEmail(userID: userID) { email, firstName, lastName in
            guard let email = email else {
                print("Email not found")
                return
            }
            
            let firstNameUnwrapped = firstName ?? ""
            let lastNameUnwrapped = lastName ?? ""
            
            self.userName = "\(firstNameUnwrapped) \(lastNameUnwrapped)".trimmingCharacters(in: .whitespaces)
            print("User Name: \(self.userName)")
            
            DispatchQueue.main.async {
                self.userEmail = email
            }
            
            print("Updated User Email: \(email)")
            
            // Fetch only books where email matches and status is "Borrowed"
            db.collection("issued_books")
                .whereField("email", isEqualTo: email) // Filter by email
                .whereField("status", isEqualTo: "Borrowed") // Filter by status
                .getDocuments { snapshot, error in
                    guard let documents = snapshot?.documents, error == nil else {
                        print("Error fetching issued books: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    var totalFineAmount: Double = 0
                    var bookISBNs: [String] = []
                    
                    for document in documents {
                        let data = document.data()
                        totalFineAmount += (data["fine"] as? Double ?? 0)
                        if let isbn = data["isbn13"] as? String {
                            bookISBNs.append(isbn)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.totalFine = totalFineAmount
                    }
                    
                    // Fetch book details only if ISBNs exist
                    if !bookISBNs.isEmpty {
                        self.fetchBookDetails(isbns: bookISBNs)
                    } else {
                        print("No borrowed books found for user.")
                    }
                }
        }
    }
    

    
    // Fetch Book Details from Books Collection and Update UI
    func fetchBookDetails(isbns: [String]) {
        let db = Firestore.firestore()
        var books: [LibraryBookLibrarian] = []
        
        let group = DispatchGroup()
        
        for isbn in isbns {
            group.enter()
            db.collection("books")
                .whereField("isbn13", isEqualTo: isbn)
                .getDocuments { snapshot, error in
                    defer { group.leave() }
                    
                    guard let document = snapshot?.documents.first, error == nil else {
                        print("Book not found for ISBN: \(isbn)")
                        return
                    }
                    
                    let data = document.data()
                    
                    let book = LibraryBookLibrarian(
                        isbn: isbn,
                        title: data["title"] as? String ?? "Unknown Title",
                        author: data["author"] as? String ?? "Unknown Author",
                        image: "book.fill" // Placeholder image
                    )
                    
                    DispatchQueue.main.async {
                        books.append(book)
                    }
                }
        }
        
        group.notify(queue: .main) {
            DispatchQueue.main.async {
                self.borrowedBooks = books // Ensure books are updated properly
            }
        }
    }
}

// MARK: - LibraryBookLibrarian Model
struct LibraryBookLibrarian: Identifiable {
    var id: String { isbn }
    var isbn: String
    var title: String
    var author: String
    var image: String
}

// MARK: - BookCardLibrarian View
struct BookCardLibrarian: View {
    var book: LibraryBookLibrarian
    var returnAction: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Book Cover
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 60, height: 80)
                
                Image(systemName: book.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.blue)
            }
            
            // Book Details
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text("ISBN: \(book.isbn)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Return Button
            Button(action: returnAction) {
                Text("Return")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
                    .foregroundColor(.white)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

// MARK: - Preview
struct UserProfileViewLibrarian_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileViewLibrarian(userID: "sampleUserID")
    }
}
