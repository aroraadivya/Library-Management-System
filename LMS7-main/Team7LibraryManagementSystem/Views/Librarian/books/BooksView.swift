//
//  BooksView.swift
//  Team7LibraryManagementSystem
//
//  Created by Taksh Joshi on 18/02/25.
//

import SwiftUI
import FirebaseFirestore

struct BooksView: View {
    @State  var books: [Book] = []
    @State private var searchText = ""
    @State private var showingAddBook = false
    @State private var isShowingFilter = false
    @State private var selectedSort: SortOption = .title
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var currentLibrarianId: String = ""
    @State private var assignedLibraryId: String = ""
    
    enum SortOption {
        case title, author, publishedDate
    }
    
    // Add these debug print statements to the filteredBooks computed property
    var filteredBooks: [Book] {
        print("DEBUG: Assigned Library ID: \(assignedLibraryId)")
        print("DEBUG: Total Books: \(books.count)")
        
        // First filter by library ID if it's available
        let libraryFiltered = assignedLibraryId.isEmpty ? books : books.filter { book in
            if let bookLibraryId = book.libraryId {
                print("DEBUG: Comparing book \(book.title) - Book LibraryId: \(bookLibraryId), Assigned: \(assignedLibraryId)")
                return bookLibraryId == assignedLibraryId
            }
            print("DEBUG: Book \(book.title) has no libraryId")
            return false
        }
        
        print("DEBUG: After library filtering: \(libraryFiltered.count) books")
        
        // Then apply search text filter
        let textFiltered = libraryFiltered.filter { book in
            searchText.isEmpty ||
            book.title.localizedCaseInsensitiveContains(searchText) ||
            book.authors.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Finally sort
        switch selectedSort {
        case .title:
            return textFiltered.sorted { $0.title < $1.title }
        case .author:
            return textFiltered.sorted { $0.authors.first ?? "" < $1.authors.first ?? "" }
        case .publishedDate:
            return textFiltered.sorted { $0.publishedDate ?? "" < $1.publishedDate ?? "" }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Search and Filter Section
                    HStack {
                        TextField("Search books", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(10)
                            .padding(.horizontal)
                        
                        // Sort Button
                        Menu {
                            Button("Sort by Title") { selectedSort = .title }
                            Button("Sort by Author") { selectedSort = .author }
                            Button("Sort by Published Date") { selectedSort = .publishedDate }
                        } label: {
                            Image(systemName: "arrow.up.and.down.text.horizontal")
                                .foregroundColor(.blue)
                                .padding(.trailing)
                        }
                    }
                    .padding(.top)
                    
                    // Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(
                            icon: "book.fill",
                            title: "\(books.count)",
                            subtitle: "Total Books",
                            color: .blue
                        )
                        
                        StatCard(
                            icon: "book.closed.fill",
                            title: "\(books.reduce(0) { $0 + $1.currentlyBorrowed })",
                            subtitle: "Borrowed Books",
                            color: .green
                        )
                        
                        StatCard(
                            icon: "books.vertical",
                            title: "\(books.reduce(0) { $0 + $1.availableQuantity })",
                            subtitle: "Available Copies",
                            color: .purple
                        )
                        
                        StatCard(
                            icon: "arrow.clockwise",
                            title: "\(books.reduce(0) { $0 + $1.totalCheckouts })",
                            subtitle: "Total Checkouts",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                    
                    // Books List
                    if isLoading {
                        ProgressView("Loading Books...")
                        
                            .padding()
                    } else if filteredBooks.isEmpty {
                        NoResultsView()
                    } else {
                        BookListView(books: filteredBooks)
                    }
                }
            }
            .navigationTitle("Library Books")
            .navigationBarItems(
                trailing: Button(action: { showingAddBook = true }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $showingAddBook) {
                AddBookView()
            }
            .onAppear {
                fetchLibrarianData()
                fetchBooks()
            }
        }
    }
    private func fetchLibrarianData() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            print("DEBUG: User ID not found")
            return
        }
        
        print("DEBUG: Fetching librarian data for userId: \(userId)")
        
        let db = Firestore.firestore()
        db.collection("librarians").whereField("userId", isEqualTo: userId).getDocuments { snapshot, error in
            if let error = error {
                print("DEBUG: Error fetching librarian data: \(error.localizedDescription)")
                return
            }
            
            print("DEBUG: Found \(snapshot?.documents.count ?? 0) librarian documents")
            
            guard let document = snapshot?.documents.first else {
                print("DEBUG: Librarian document not found")
                return
            }
            
            do {
                if let librarian = try? document.data(as: Librarian.self) {
                    self.currentLibrarianId = librarian.id
                    print("DEBUG: Found librarian ID: \(librarian.id)")
                    
                    // Fetch the assigned library
                    db.collection("librarian_assignments")
                        .whereField("librarianId", isEqualTo: self.currentLibrarianId)
                        .getDocuments { snapshot, error in
                            if let error = error {
                                print("DEBUG: Error fetching assignments: \(error.localizedDescription)")
                                return
                            }
                            
                            print("DEBUG: Found \(snapshot?.documents.count ?? 0) assignment documents")
                            
                            if let document = snapshot?.documents.first,
                               let libraryId = document.data()["libraryId"] as? String {
                                self.assignedLibraryId = libraryId
                                print("DEBUG: Librarian assigned to library: \(libraryId)")
                                
                                // Force a UI refresh after setting the libraryId
                                self.books = self.books
                            } else {
                                print("DEBUG: No library assignment found for librarian")
                            }
                        }
                }
            } catch {
                print("DEBUG: Error decoding librarian data: \(error.localizedDescription)")
            }
        }
    }
    func fetchBooks() {
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        db.collection("books").addSnapshotListener { snapshot, error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error fetching books: \(error.localizedDescription)"
                return
            }
            
            guard let documents = snapshot?.documents else {
                errorMessage = "No books found"
                return
            }
            
            books = documents.compactMap { document -> Book? in
                let data = document.data()
                
                return Book(
                    id: document.documentID,
                    title: data["title"] as? String ?? "",
                    authors: data["authors"] as? [String] ?? [],
                    publisher: data["publisher"] as? String,
                    publishedDate: data["publishedDate"] as? String,
                    description: data["description"] as? String,
                    pageCount: data["pageCount"] as? Int,
                    categories: data["categories"] as? [String],
                    coverImageUrl: data["coverImageUrl"] as? String,
                    isbn13: data["isbn13"] as? String,
                    language: data["language"] as? String,
                    
                    quantity: data["quantity"] as? Int ?? 0,
                    availableQuantity: data["availableQuantity"] as? Int ?? 0,
                    location: data["location"] as? String ?? "",
                    status: data["status"] as? String ?? "available",
                    totalCheckouts: data["totalCheckouts"] as? Int ?? 0,
                    currentlyBorrowed: data["currentlyBorrowed"] as? Int ?? 0,
                    isAvailable: data["isAvailable"] as? Bool ?? true,
                    libraryId: data["libraryId"] as? String // Add this line to capture libraryId
                )
            }
        }
    }

    // Update the onAppear modifier in body
    
}

struct BookListView: View {
    let books: [Book]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                ForEach(books) { book in
                    NavigationLink(destination: BookDetailView(book: book)) {
                        BookCard(book: book)
                    }
                }
            }
            .padding()
        }
    }
}

struct BookCard: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 12) {
               
                
                if let coverImageUrl = book.coverImageUrl,
                   let imageUrl = URL(string: coverImageUrl) {
                   
                    AsyncImage(url: imageUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 80, height: 120)
                    .cornerRadius(8)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 120)
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.headline)
                    
                    Text(book.authors.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if let isbn = book.isbn13 {
                        Text("ISBN: \(isbn)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Available: \(book.availableQuantity)/\(book.quantity)")
                            .font(.caption)
                            .foregroundColor(book.isAvailable ? .green : .red)
                        
                        Spacer()
                        
                        Text(book.location)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            HStack {
                NavigationLink(destination: BookDetailView(book: book)) {
                    Text("View Details")
                        .buttonStyle(.bordered)
                }
                
                Spacer()
                
                // Status indicator
                Text(book.status.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(getStatusColor(book.status).opacity(0.2))
                    .foregroundColor(getStatusColor(book.status))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func getStatusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "available":
            return .green
        case "borrowed":
            return .orange
        case "reserved":
            return .blue
        default:
            return .gray
        }
    }
}


struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.system(size: 50))
            
            Text("Error")
                .font(.headline)
                .foregroundColor(.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

struct NoResultsView: View {
    var body: some View {
        VStack {
            Image(systemName: "book.fill")
                .foregroundColor(.gray.opacity(0.5))
                .font(.system(size: 50))
            
            Text("No Books Found")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Try adjusting your search or add a new book")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

#Preview{
    BooksView()
}
