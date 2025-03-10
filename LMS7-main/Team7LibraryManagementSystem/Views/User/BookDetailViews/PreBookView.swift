import SwiftUI
import FirebaseFirestore
import FirebaseFirestore

struct PreBookView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedLibrary: Library? = nil
    @State private var showConfirmation = false
    @State private var isBookingConfirmed = false
    @State private var libraries: [Library] = []
    
    
    let isbn: String
    
    var body: some View {
        NavigationStack {
            VStack {
                if let selectedLibrary = selectedLibrary {
                    VStack(spacing: 16) {
                        Text("You are booking *The Art of Innovation* at **\(selectedLibrary.name)**.")
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Text("Location: \(selectedLibrary.address.city), \(selectedLibrary.address.state)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.bottom)
                    }
                } else {
                    if libraries.isEmpty {
                        Text("Fetching libraries...")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        List(libraries, id: \..id) { library in
                            Button(action: {
                                selectedLibrary = library
                                showConfirmation = true
                            }) {
                                VStack(alignment: .leading) {
                                    Text(library.name)
                                        .font(.headline)
                                    Text("Location: \(library.address.city), \(library.address.state)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(selectedLibrary?.id == library.id ? Color.blue.opacity(0.1) : Color.clear)
                                .cornerRadius(10)
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle("Pre-Book")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                fetchLibrariesForBook(isbn: isbn)
            }
            
            if showConfirmation {
                VStack {
                    Text("Confirm Booking")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding()
                    
                    Text("You are booking *The Art of Innovation* at **\(selectedLibrary?.name ?? "")**.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        guard let libraryId = selectedLibrary?.id else {
                               print("Error: Library ID is nil")
                               return
                           }
                        
                        fetchUserEmail { email in
                            if let email = email {
                                print("User email: \(email)")
                                preBookBook(isbn: isbn, userEmail: email, libraryId: libraryId)
                            } else {
                                print("Failed to retrieve email")
                            }
                        }
                        isBookingConfirmed = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            dismiss()
                        }
                    }) {
                        Text("Confirm Booking")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom))
                .animation(.spring(), value: showConfirmation)
            }
//
        }
    }
    
    func fetchUserEmail(completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        
        // Retrieve userId from UserDefaults
        if let userId = UserDefaults.standard.string(forKey: "userId") {
            db.collection("users").document(userId).getDocument { document, error in
                if let error = error {
                    print("Error fetching user data: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                if let document = document, document.exists {
                    if let email = document.data()?["email"] as? String {
                        completion(email)
                        return
                    }
                }
                
                completion(nil) // Return nil if email is not found
            }
        } else {
            print("User ID not found in UserDefaults")
            completion(nil)
        }
    }
    
    
    
    func preBookBook(isbn: String, userEmail: String, libraryId: String) {
        let db = Firestore.firestore()
        let booksCollection = db.collection("books")
        let preBookCollection = db.collection("PreBook")

        // Step 1: Check if the book is already pre-booked by the same user
        preBookCollection
            .whereField("isbn13", isEqualTo: isbn)
            .whereField("userEmail", isEqualTo: userEmail)
            .whereField("libraryId", isEqualTo: libraryId)
            .whereField("status", isEqualTo: "Pending")
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error checking existing pre-booking: \(error.localizedDescription)")
                    return
                }

                if let documents = snapshot?.documents, !documents.isEmpty {
                    print("Book is already pre-booked by this user.")
                    return
                }

                // Step 2: Check if the book is available for pre-booking
                booksCollection
                    .whereField("isbn13", isEqualTo: isbn)
                    .whereField("libraryId", isEqualTo: libraryId)
                    .getDocuments { (snapshot, error) in
                        if let error = error {
                            print("Error fetching book: \(error.localizedDescription)")
                            return
                        }

                        guard let documents = snapshot?.documents, !documents.isEmpty else {
                            print("No book found with this ISBN in the library.")
                            return
                        }

                        for document in documents {
                            let bookData = document.data()
                            let totalCheckouts = bookData["totalCheckouts"] as? Int ?? 0
                            let availableQuantity = bookData["availableQuantity"] as? Int ?? 0

                            if totalCheckouts >= availableQuantity {
                                print("Book is not available for pre-booking.")
                                return
                            }

                            // Step 3: Proceed with pre-booking
                            let currentTime = Timestamp(date: Date()) // Current timestamp
                            let expirationTime = Timestamp(date: Calendar.current.date(byAdding: .hour, value: 3, to: Date())!) // Expiry in 3 hours
//                            let expirationTime = Timestamp(date: Calendar.current.date(byAdding: .second, value: 30, to: Date())!)


                            let preBookData: [String: Any] = [
                                "isbn13": isbn,
                                "userEmail": userEmail,
                                "libraryId": libraryId,
                                "createdAt": currentTime,
                                "expiresAt": expirationTime,
                                "status": "Pending"  // Initially set as "Pending"
                            ]

                            preBookCollection.addDocument(data: preBookData) { error in
                                if let error = error {
                                    print("Error pre-booking the book: \(error.localizedDescription)")
                                } else {
                                    print("Book successfully pre-booked!")

                                    // Step 4: Increment totalCheckouts for the book
                                    updateBookTotalCheckouts(isbn: isbn, libraryId: libraryId)
                                }
                            }
                        }
                    }
            }
    }

    func updateBookTotalCheckouts(isbn: String, libraryId: String) {
        let db = Firestore.firestore()
        let booksCollection = db.collection("books")

        booksCollection
            .whereField("isbn13", isEqualTo: isbn)
            .whereField("libraryId", isEqualTo: libraryId)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching book: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("No book found with this ISBN in the library.")
                    return
                }

                for document in documents {
                    let bookRef = document.reference

                    bookRef.updateData([
                        "totalCheckouts": FieldValue.increment(Int64(1))
                    ]) { error in
                        if let error = error {
                            print("Error updating totalCheckouts: \(error.localizedDescription)")
                        } else {
                            print("totalCheckouts updated successfully.")
                        }
                    }
                }
            }
    }
    
    
    func fetchLibrariesForBook(isbn: String) {
        let db = Firestore.firestore()
        db.collection("books").whereField("isbn13", isEqualTo: isbn).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching books: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No books found for ISBN \(isbn)")
                return
            }
            
            let libraryIds = documents.compactMap { $0.data()["libraryId"] as? String }
            
            if libraryIds.isEmpty {
                return
            }
            
            let dispatchGroup = DispatchGroup()
            var fetchedLibraries: [Library] = []
            
            for libraryId in libraryIds {
                dispatchGroup.enter()
                db.collection("libraries").document(libraryId).getDocument { librarySnapshot, error in
                    defer { dispatchGroup.leave() }
                    
                    if let error = error {
                        print("Error fetching library: \(error.localizedDescription)")
                        return
                    }
                    
                    if let libraryData = try? librarySnapshot?.data(as: Library.self) {
                        fetchedLibraries.append(libraryData)
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.libraries = fetchedLibraries
            }
        }
    }
}
