


import SwiftUI
import FirebaseFirestore

struct UserHomeView: View {
    var body: some View {
        TabView {
            
            HomeScreen()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            MyBooksView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("My Books")
                }
            
            UserSearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search Books")
                }
            
            WishlistView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Wishlist")
                }
            
            UserEventsView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Events")
                }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct HomeScreen: View {
    @StateObject private var booksViewModel = BooksViewModel()
    @State private var searchText = ""
    
    @State private var showUserProfile = false
    @State private var showUserNotification = false
    @State private var showSearchView = false
    
//    @State var events: [EventModel] = []
//    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Search Bar
//                    NavigationLink(destination: UserSearchView()) {
//                        HStack {
//                            Image(systemName: "magnifyingglass")
//                                .foregroundColor(.gray)
//                                .padding(.leading, 10)
//
//                            Text("Search")
//                                .foregroundColor(.gray)
//                                .padding(5)
//                        }
//                        .padding(1)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .background(Color(.systemGray6))
//                        .cornerRadius(10)
//                    }
//                    .padding(.horizontal)
                    
                    // Books You May Like Section
                    if booksViewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        BooksSection(
                            title: "Books You May Like",
                            books: recommendedBooks
                        )
                        
                        QuoteCard(
                            text: "A reader lives a thousand lives before he dies.",
                            author: "George R.R. Martin"
                        )
                        .padding(.horizontal)
                        
                        // Trending Books Section
                        BooksSection(
                            title: "Trending Books",
                            books: trendingBooks
                        )
                    }
                }
                .padding(.top)
                .onAppear {
                    booksViewModel.fetchBooks()
                }
                .navigationTitle("HOME")
                .toolbar {
                    HStack(spacing: 8) {
                        Image(systemName: "bell")
                            .font(.title3)
                            .foregroundStyle(.blue)
                            .onTapGesture {
                                showUserNotification = true
                            }.sheet(isPresented: $showUserNotification) {
                                NavigationStack {
                                    LibrarianNotificationsView()
                                }
                            }
                        
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .onTapGesture {
                                showUserProfile = true
                            }.sheet(isPresented: $showUserProfile) {
                                NavigationStack {
                                //                                ProfilePage()
                                UserProfileView()
                                }
                            }
                    }
                }
                
            }
        }
    }
    
//    var body: some View {
//          NavigationStack {
//              ScrollView {
//                  VStack(alignment: .leading, spacing: 12) {
//                      // 🔹 Events Carousel (Fetching from Firestore)
//                      if isLoading {
//                          ProgressView().frame(maxWidth: .infinity)
//                      } else if events.isEmpty {
//                          Text("No Events Available")
//                              .foregroundColor(.gray)
//                              .frame(maxWidth: .infinity)
//                      } else {
//                          ScrollView(.horizontal, showsIndicators: false) {
//                              HStack(spacing: 12) {
//                                  ForEach(events) { event in
//                                      EventCard(event: event) // 🔥 Custom Card for each event
//                                  }
//                              }
//                              .padding(.horizontal)
//                          }
//                          .padding(.top, 10)
//                      }
//
//                      // 🔹 Books You May Like Section
//                      if booksViewModel.isLoading {
//                          ProgressView().frame(maxWidth: .infinity)
//                      } else {
//                          BooksSection(title: "Books You May Like", books: recommendedBooks)
//
//                          QuoteCard(
//                              text: "A reader lives a thousand lives before he dies.",
//                              author: "George R.R. Martin"
//                          ).padding(.horizontal)
//
//                          BooksSection(title: "Trending Books", books: trendingBooks)
//                      }
//                  }
//                  .padding(.top)
//                  .onAppear {
//                      booksViewModel.fetchBooks()
//                      fetchEvents() // 🔥 Fetch events on screen load
//                  }
//                  .navigationTitle("HOME")
//                  .toolbar {
//                      HStack(spacing: 8) {
//                          Image(systemName: "bell")
//                              .font(.title3)
//                              .foregroundStyle(.black)
//                              .onTapGesture { showUserNotification = true }
//                              .sheet(isPresented: $showUserNotification) { NavigationStack { } }
//
//                          Image(systemName: "person.circle.fill")
//                              .font(.title2)
//                              .foregroundStyle(.black)
//                              .onTapGesture { showUserProfile = true }
//                              .sheet(isPresented: $showUserProfile) { NavigationStack { ProfileView() } }
//                      }
//                  }
//              }
//          }
//      }
    
//
//    func fetchEvents() {
//       let now = Date()
//       let db = Firestore.firestore()
//       isLoading = true
//
//       db.collection("events")
//           .whereField("status", isEqualTo: "Live")
//           .getDocuments { snapshot, error in
//               guard let documents = snapshot?.documents else {
//                   print("Error fetching events: \(error?.localizedDescription ?? "Unknown error")")
//                   return
//               }
//               isLoading = false
//
//             //  var events: [EventModel] = []
//               var spacesUsed = 0
//
//               for doc in documents {
//                   let data = doc.data()
//                   let id = doc.documentID
//                   let title = data["title"] as? String ?? "No Title"
//                   let description = data["description"] as? String ?? "No Description"
//                   let coverImage = data["coverImage"] as? String ?? ""
//                   let startTime = (data["startDateTime"] as? Timestamp)?.dateValue() ?? Date()
//                   let endTime = (data["endDateTime"] as? Timestamp)?.dateValue() ?? Date()
//                   let eventType = data["eventType"] as? String ?? "Other"
//                   let location = data["location"] as? String ?? "Unknown"
//                   let notifyMembers = data["notifyMembers"] as? Bool ?? false
//                   let status = data["status"] as? String ?? ""
//
//                   // Fetch only ongoing (Live) or upcoming events
//                   if endTime > now {
//                       let eventItem = EventModel(
//                           id: id,
//                           title: title,
//                           description: description,
//                           coverImage: coverImage,
//                           startTime: startTime,
//                           endTime: endTime,
//                           eventType: eventType,
//                           location: location,
//                           notifyMembers: notifyMembers,
//                           status: status
//                       )
//
//                       events.append(eventItem)
//                       print(events.count)
//                       spacesUsed += 1
//                   }
//               }
//
////               DispatchQueue.main.async {
////                   liveEvents = events
////                   activeEventsCount = "\(events.count)"
////                   spacesInUse = "\(spacesUsed)"
////               }
//           }
//    }
  

    
    // Computed property for recommended books
    private var recommendedBooks: [Book] {
        // You can implement more sophisticated recommendation logic
        return booksViewModel.books.shuffled().prefix(5).map { $0 }
    }
    
    // Computed property for trending books
    private var trendingBooks: [Book] {
        // Sort by total checkouts or implement more complex trending logic
        return booksViewModel.books
            .sorted { $0.totalCheckouts > $1.totalCheckouts }
            .prefix(5)
            .map { $0 }
    }
}


//struct EventCard: View {
//    let event: EventModel
//
//    var body: some View {
//        ZStack(alignment: .bottomLeading) {
//            // Load Image from Firebase URL or use Placeholder
//            AsyncImage(url: URL(string: event.coverImage ?? "")) { image in
//                image.resizable()
//            } placeholder: {
//                Image(systemName: "calendar")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 100, height: 100)
//                    .foregroundColor(.black0)
//            }
//            .scaledToFill()
//            .frame(width: 300, height: 150)
//            .clipShape(RoundedRectangle(cornerRadius: 12))
//
//            // Gradient Overlay
//            LinearGradient(gradient: Gradient(colors: [.black.opacity(0.8), .clear]),
//                           startPoint: .bottom,
//                           endPoint: .center)
//                .frame(height: 50)
//                .clipShape(RoundedRectangle(cornerRadius: 12))
//
//            // Event Title
//            Text(event.title)
//                .font(.headline)
//                .foregroundColor(.white)
//                .padding()
//        }
//        .frame(width: 300, height: 150)
//    }
//}

// Books Section View
struct BooksSection: View {
    let title: String
    let books: [Book]
    @StateObject private var wishlistManager = WishlistManager()
    
    var body: some View {
        VStack(alignment: .leading) {
            SectionHeader(title: title)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(books) { book in
                        NavigationLink(destination: UserBookDetailView(isbn13: book.isbn13 ?? "-1")) {
                            UserBookCard(book: book,wishlistManager: wishlistManager)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}



// Books View Model
class BooksViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchBooks() {
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        db.collection("books").getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Error fetching books: \(error.localizedDescription)"
                return
            }
            
            guard let documents = snapshot?.documents else {
                self.errorMessage = "No books found"
                return
            }
            
            self.books = documents.compactMap { document -> Book? in
                let data = document.data()
                
                return Book(
                    id: (data["bookId"] as? String)!,
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
                    libraryId: data["libraryId"] as? String
                )
            }
        }
    }
}


struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 25)
            
            Text("\(label):")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
        }
    }
}
struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .padding(.horizontal)
    }
}

struct UserBookCard: View {
    let book: Book
    @State private var isBookInWishlist = false
    @ObservedObject var wishlistManager: WishlistManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: book.coverImageUrl ?? "")) { image in
                    image.resizable()
                } placeholder: {
                    Image(systemName: "book.closed")
                        .resizable()
                        .foregroundColor(.gray)
                }
                .scaledToFit()
                .frame(width: 140, height: 110)
                .cornerRadius(10)
                
                // Like Button
                Button(action: {
                    if isBookInWishlist {
                        wishlistManager.removeFromWishlist(bookId: book.id)
                    } else {
                        wishlistManager.addToWishlist(bookId: book.id)
                    }
                    isBookInWishlist.toggle() // UI State Update
                }) {
                    Image(systemName: isBookInWishlist ? "heart.fill" : "heart")
                        .foregroundColor(isBookInWishlist ? .red : .gray)
                        .padding(8)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .offset(x: 18, y: -12)
            }
            .frame(maxWidth: .infinity, alignment: .topTrailing)
            
            Text(book.title)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            if let author = book.authors.first {
                Text(author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(book.description ?? "No description available")
                .font(.footnote)
                .foregroundColor(.gray)
                .lineLimit(2)
            
            Spacer()
        }
        .frame(width: 160, height: 230)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 5)
        .onAppear {
            wishlistManager.checkIfBookIsInWishlist(bookId: book.id) { isInWishlist in
                self.isBookInWishlist = isInWishlist
            }
        }
    }
}


struct QuoteCard: View {
    let text: String
    let author: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("“")
                .font(.largeTitle)
                .foregroundColor(.blue)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Text("- \(author)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}







// Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        UserHomeView()
    }
}
