//
//  AddBooksView.swift
//  Team7LibraryManagementSystem
//
//  Created by Taksh Joshi on 18/02/25.
//

import SwiftUI
import FirebaseFirestore
import CodeScanner

struct AddBookView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchQuery = ""
    @State private var searchResults: [Book] = []
    @State private var selectedBook: Book?
    @State private var quantity = "1"
    @State private var location = ""
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var showAlert = false
    @State private var showingAddBook = false
    @State private var selectedLibrary: String = ""
    @State private var libraries: [Library] = []
    @State private var librarian: Librarian?
    @State private var isShowingScanner = false // For barcode scanner
    @State private var coverImage: UIImage? = nil
    var body: some View {
        NavigationStack {
            VStack {
                // Search Bar with Barcode Scanner
                HStack {
                    TextField("Search by title, author, or ISBN", text: $searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        isShowingScanner = true // Open scanner
                    }) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: searchBooks) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .padding()
                
                if isSearching {
                    ProgressView("Searching...")
                        .padding()
                } else if let selectedBook = selectedBook {
                    // Selected Book Details View
                    BookDetailsView(
                        book: selectedBook,
                        quantity: $quantity,
                        location: $location,
                        selectedLibrary: $selectedLibrary,
                        libraries: libraries,
                        onSave: addBookToLibrary,
                        onCancel: { self.selectedBook = nil }
                    )
                } else {
                    // Display search results
                    SearchResultsView(
                        searchResults: searchResults,
                        onBookSelect: { book in
                            selectedBook = book
                        }
                    )
                }
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
            .sheet(isPresented: $isShowingScanner) {
                CodeScannerView(codeTypes: [.ean13, .ean8], simulatedData: "9781234567890") { result in
                    switch result {
                    case .success(let code):
                        searchQuery = code.string // Update search field with scanned ISBN
                        isShowingScanner = false
                    case .failure(let error):
                        errorMessage = "Scan failed: \(error.localizedDescription)"
                        showAlert = true
                        isShowingScanner = false
                    }
                }
            }
        }
        .onAppear {
            fetchLibraries()
            fetchLibrarianData()
        }
    }
    
    private func fetchLibraries() {
        let db = Firestore.firestore()
        db.collection("libraries").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching libraries: \(error.localizedDescription)")
                self.errorMessage = "Error loading libraries: \(error.localizedDescription)"
                self.showAlert = true
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No libraries found")
                return
            }
            
            self.libraries = documents.compactMap { document in
                try? document.data(as: Library.self)
            }
            
            // Set default library if available
            if let firstLibrary = libraries.first, self.selectedLibrary.isEmpty {
                self.selectedLibrary = firstLibrary.id ?? ""
            }
        }
    }
    private func fetchLibrarianData() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            print("User ID not found")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("librarians").whereField("userId", isEqualTo: userId).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching librarian data: \(error.localizedDescription)")
                return
            }
            
            guard let document = snapshot?.documents.first else {
                print("Librarian document not found")
                return
            }
            
            do {
                self.librarian = try document.data(as: Librarian.self)
            } catch {
                print("Error decoding librarian data: \(error.localizedDescription)")
            }
        }
    }
    private func searchBooks() {
        guard !searchQuery.isEmpty else { return }
        isSearching = true
        searchResults.removeAll()
        
        let query = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        // Replace YOUR_API_KEY with your actual Google Books API key
        let apiKey = "AIzaSyBFi8ZtHZdI_avEm11ZJAMRkGNF1vBl8zY"
        let urlString = "https://www.googleapis.com/books/v1/volumes?q=\(query)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            isSearching = false
            errorMessage = "Invalid search query"
            showAlert = true
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.isSearching = false
                    self.errorMessage = error.localizedDescription
                    self.showAlert = true
                    return
                }
                
                guard let data = data else {
                    self.isSearching = false
                    self.errorMessage = "No data received"
                    self.showAlert = true
                    return
                }
                
                // First check for API error response
                if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorResponse["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    self.isSearching = false
                    self.errorMessage = message
                    self.showAlert = true
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(GoogleBooksResponse.self, from: data)
                    self.searchResults = (response.items ?? []).map { volume in
                        Book(
                            id: volume.id,
                            title: volume.volumeInfo.title,
                            authors: volume.volumeInfo.authors ?? [],
                            publisher: volume.volumeInfo.publisher,
                            publishedDate: volume.volumeInfo.publishedDate,
                            description: volume.volumeInfo.description,
                            pageCount: volume.volumeInfo.pageCount,
                            categories: volume.volumeInfo.categories,
                            coverImageUrl: volume.volumeInfo.imageLinks?.thumbnail ?? volume.volumeInfo.imageLinks?.smallThumbnail,
                            isbn13: volume.volumeInfo.industryIdentifiers?.first(where: { $0.type == "ISBN_13" })?.identifier,
                            language: volume.volumeInfo.language,
                            quantity: 0,
                            availableQuantity: 0,
                            location: "",
                            status: "available",
                            totalCheckouts: 0,
                            currentlyBorrowed: 0,
                            isAvailable: true,
                            libraryId: nil  // Add this line with nil as placeholder
                        )
                        
                    }
                    self.isSearching = false
                } catch {
                    print("Decoding error:", error)
                    self.isSearching = false
                    self.errorMessage = "Failed to parse response. Please try again."
                    self.showAlert = true
                }
            }
        }.resume()
    }
    
    private func addBookToLibrary() {
        guard let book = selectedBook else { return }
        guard let quantityInt = Int(quantity), quantityInt > 0 else {
            errorMessage = "Please enter a valid quantity"
            showAlert = true
            return
        }
        guard !selectedLibrary.isEmpty else {
            errorMessage = "Please select a library"
            showAlert = true
            return
        }
        guard let librarianData = librarian else {
            errorMessage = "Librarian data not available"
            showAlert = true
            return
        }
        var coverImageBase64: String? = nil
        if let imageUrl = book.coverImageUrl, let url = URL(string: imageUrl),
           let imageData = try? Data(contentsOf: url), let image = UIImage(data: imageData) {
            coverImageBase64 = convertImageToBase64(image)
            
        }
//        print("image : \(image)" )
        let db = Firestore.firestore()
        let bookData: [String: Any] = [
            "bookId": book.id,
            "title": book.title,
            "authors": book.authors,
            "publisher": book.publisher ?? "",
            "publishedDate": book.publishedDate ?? "",
            "description": book.description ?? "",
            "pageCount": book.pageCount ?? 0,
            "categories": book.categories ?? [],
            "coverImageUrl": book.coverImageUrl ?? "",
            "coverImageBase64": coverImageBase64 ?? "",
            "isbn13": book.isbn13 ?? "",
            "language": book.language ?? "",
            
            "quantity": quantityInt,
            "availableQuantity": quantityInt,
            "location": location,
            "addedDate": Timestamp(),
            "lastUpdated": Timestamp(),
            "status": "available",
            
            "totalCheckouts": 0,
            "currentlyBorrowed": 0,
            "isAvailable": true,
            
            // Add these new fields
            "libraryId": selectedLibrary,
            "addedBy": librarianData.id,
            "addedByName": librarianData.fullName
        ]
        
        db.collection("books")
            .whereField("isbn13", isEqualTo: book.isbn13 ?? "")
            .whereField("libraryId", isEqualTo: selectedLibrary)
            .getDocuments { snapshot, error in
                if let error = error {
                    self.errorMessage = "Error checking book: \(error.localizedDescription)"
                    self.showAlert = true
                    return
                }
                
                if let existingBook = snapshot?.documents.first {
                    let currentQuantity = existingBook.data()["quantity"] as? Int ?? 0
                    let currentAvailable = existingBook.data()["availableQuantity"] as? Int ?? 0
                    
                    existingBook.reference.updateData([
                        "quantity": currentQuantity + quantityInt,
                        "availableQuantity": currentAvailable + quantityInt,
                        "lastUpdated": Timestamp(),
                        "updatedBy": librarianData.id,
                        "updatedByName": librarianData.fullName
                    ]) { error in
                        if let error = error {
                            self.errorMessage = "Error updating book: \(error.localizedDescription)"
                            self.showAlert = true
                        } else {
                            self.dismiss()
                        }
                    }
                } else {
                    db.collection("books").addDocument(data: bookData) { error in
                        if let error = error {
                            self.errorMessage = "Error adding book: \(error.localizedDescription)"
                            self.showAlert = true
                        } else {
                            let inventoryData: [String: Any] = [
                                "bookId": book.id,
                                "totalCopies": quantityInt,
                                "availableCopies": quantityInt,
                                "location": location,
                                "libraryId": selectedLibrary,
                                "addedBy": librarianData.id,
                                "lastInventoryDate": Timestamp()
                            ]
                            
                            db.collection("inventory").addDocument(data: inventoryData) { error in
                                if let error = error {
                                    print("Error creating inventory: \(error.localizedDescription)")
                                }
                                
                                // Add transaction record
                                let transactionData: [String: Any] = [
                                    "bookId": book.id,
                                    "bookTitle": book.title,
                                    "transactionType": "book_added",
                                    "quantity": quantityInt,
                                    "performedBy": librarianData.id,
                                    "performedByName": librarianData.fullName,
                                    "libraryId": selectedLibrary,
                                    "timestamp": Timestamp()
                                ]
                                
                                db.collection("transactions").addDocument(data: transactionData) { error in
                                    if let error = error {
                                        print("Error recording transaction: \(error.localizedDescription)")
                                    }
                                    self.dismiss()
                                }
                            }
                        }
                    }
                }
            }
        
    }
    private func convertImageToBase64(_ image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.1) else { return nil }
        return imageData.base64EncodedString()
    }
}
    
    struct SearchResultsView: View {
        let searchResults: [Book]
        let onBookSelect: (Book) -> Void
        
        var body: some View {
            if searchResults.isEmpty {
                Text("No books found")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(searchResults) { book in
                    Button(action: { onBookSelect(book) }) {
                        HStack(spacing: 12) {
                            // Book Cover with safe image loading
                            if let imageUrl = book.getImageUrl() {
                                AsyncImage(url: imageUrl) { image in
                                    image.resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 60, height: 80)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 60, height: 80)
                                }
                                .cornerRadius(4)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(book.title)
                                    .font(.headline)
                                if !book.authors.isEmpty {
                                    Text(book.authors.joined(separator: ", "))
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                if let publisher = book.publisher {
                                    Text(publisher)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    struct BookDetailsView: View {
        let book: Book
        @Binding var quantity: String
        @Binding var location: String
        @Binding var selectedLibrary: String // Add this binding
        let libraries: [Library] // Add this property
        let onSave: () -> Void
        let onCancel: () -> Void
        
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Book Cover
                    BookImageView(
                        url: book.getImageUrl(),
                        width: UIScreen.main.bounds.width - 32,
                        height: 300
                    )
                    
                    // Book Details
                    VStack(alignment: .leading, spacing: 10) {
                        Text(book.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("By " + book.authors.joined(separator: ", "))
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if let publisher = book.publisher {
                            Text("Publisher: \(publisher)")
                                .font(.subheadline)
                        }
                        
                        if let publishedDate = book.publishedDate {
                            Text("Published: \(publishedDate)")
                                .font(.subheadline)
                        }
                        
                        if let isbn = book.isbn13 {
                            Text("ISBN: \(isbn)")
                                .font(.subheadline)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Quantity and Location Inputs
                    VStack(spacing: 15) {
                        TextField("Quantity", text: $quantity)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                                        
                        TextField("Shelf Location", text: $location)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                        Picker("Select Library", selection: $selectedLibrary) {
                            ForEach(libraries) { library in
                                Text(library.name)
                                    .tag(library.id ?? "")
                                }
                            }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding()
                    
                    
                    // Action Buttons
                    HStack {
                        Button("Cancel") {
                            onCancel()
                        }
                        .foregroundColor(.red)
                        
                        Spacer()
                        
                        Button("Add to Library") {
                            onSave()
                        }
                        .disabled(quantity.isEmpty || location.isEmpty)
                    }
                    .padding()
                    
                }
                
            }
        }
    }
    
    // Utility Image View

