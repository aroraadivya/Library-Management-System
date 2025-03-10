//import SwiftUI
//
//struct UserSearchView: View {
//    @State private var searchText = ""
//    @State private var isSearching = false
//    @StateObject private var booksViewModel = BooksViewModel()
//
//    var filteredBooks: [Book] {
//        guard !searchText.isEmpty else { return [] }
//        return booksViewModel.books.filter { book in
//            book.title.localizedCaseInsensitiveContains(searchText) ||
//            book.authors.contains { $0.localizedCaseInsensitiveContains(searchText) }
//        }
//    }
//
//    var body: some View {
//        NavigationStack {
//            VStack {
//                // Search Bar
//                HStack {
//                    HStack {
//                        Image(systemName: "magnifyingglass")
//                            .foregroundColor(.gray)
//                            .padding(.leading, 10)
//
//                        TextField("Search books", text: $searchText)
//                            .padding(5)
//                            .onChange(of: searchText) { _ in
//                                isSearching = !searchText.isEmpty
//                            }
//                    }
//                    .padding(1)
//                    .background(Color(.systemGray6))
//                    .cornerRadius(10)
//
//                    if isSearching {
//                        Button("Cancel") {
//                            searchText = ""
//                            isSearching = false
//                            // Dismiss keyboard
//                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//                        }
//                        .transition(.move(edge: .trailing))
//                    }
//                }
//                .padding()
//                .animation(.default, value: isSearching)
//
//                // Search Results
//                if filteredBooks.isEmpty && !searchText.isEmpty {
//                    // No Results State
//                    VStack {
//                        Image(systemName: "doc.text.magnifyingglass")
//                            .resizable()
//                            .aspectRatio(contentMode: .fit)
//                            .frame(width: 100, height: 100)
//                            .foregroundColor(.gray)
//
//                        Text("No books found")
//                            .foregroundColor(.gray)
//                    }
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                } else {
//                    // Search Results
//                    ScrollView {
//                        LazyVGrid(columns: [
//                            GridItem(.flexible(), spacing: 16),
//                            GridItem(.flexible(), spacing: 16)
//                        ], spacing: 16) {
//                            ForEach(filteredBooks) { book in
//                                NavigationLink(destination: UserBookDetailView(isbn13: book.isbn13 ?? "-1")) {
//                                    UserBookCard(book: book, wishlistManager: WishlistManager())
//                                }
//                            }
//                        }
//                        .padding()
//                    }
//                }
//            }
//            .navigationTitle("Search")
//            .navigationBarTitleDisplayMode(.inline)
//            .onAppear {
//                // Ensure books are loaded
//                booksViewModel.fetchBooks()
//            }
//        }
//    }
//}
//
//struct UserSearchView_Previews: PreviewProvider {
//    static var previews: some View {
//        UserSearchView()
//    }
//}

import SwiftUI

struct UserSearchView: View {
    @State private var searchText = ""
    @State private var isSearching = false
    @StateObject private var booksViewModel = BooksViewModel()
    
    var displayedBooks: [Book] {
        if searchText.isEmpty {
            return Array(booksViewModel.books.prefix(6)) // Show first 6 books when search is empty
        } else {
            return booksViewModel.books.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.authors.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search Bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .padding(.leading, 10)
                        
                        TextField("Search books", text: $searchText)
                            .padding(5)
                            .onChange(of: searchText) { _ in
                                isSearching = !searchText.isEmpty
                            }
                    }
                    .padding(1)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    if isSearching {
                        Button("Cancel") {
                            searchText = ""
                            isSearching = false
                            // Dismiss keyboard
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        .transition(.move(edge: .trailing))
                    }
                }
                .padding()
                .animation(.default, value: isSearching)
                
                // Search Results or Default Books
                if displayedBooks.isEmpty {
                    // No Results State
                    VStack {
                        Image(systemName: "doc.text.magnifyingglass")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                        
                        Text("No books found")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Show Books
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 25),
                            GridItem(.flexible(), spacing: 25)
                        ], spacing: 16) {
                            ForEach(displayedBooks) { book in
                                NavigationLink(destination: UserBookDetailView(isbn13: book.isbn13 ?? "-1")) {
                                    UserBookCard(book: book, wishlistManager: WishlistManager())
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Ensure books are loaded
                booksViewModel.fetchBooks()
            }
        }
    }
}

struct UserSearchView_Previews: PreviewProvider {
    static var previews: some View {
        UserSearchView()
    }
}
