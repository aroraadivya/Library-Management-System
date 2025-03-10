//
//  HomeView.swift
//  LinrarianSide
//
//  Created by Taksh Joshi on 20/02/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
struct PreBookItem: Identifiable {
    let id: String
    let userEmail: String
    let isbn13: String
    let status: String
}

struct libHomeView: View {
    @State private var books: [Book] = []
    @State private var activeUsers = 0
    @State private var showProfile = false
    @State private var showNotification = false
    @State private var preBookItems: [PreBookItem] = []
    @State private var assignedLibrary: Library? = nil
    @State private var libraryImage: UIImage? = nil

    
    var body: some View {

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        // Total Books
                        StatCard2(
                            icon: "books.vertical.fill",
                            iconColor: .blue,
                            title: "\(books.count)",
                            subtitle: "Total Books"
                        )

                        // Active Users
                        StatCard2(
                            icon: "person.2.fill",
                            iconColor: .blue,
                            title: "\(activeUsers)",
                            subtitle: "Active Users"
                        )

                        // Total Fine
                        StatCard2(
                            icon: "dollarsign.circle.fill",
                            iconColor: .blue,
                            title: "$123",
                            subtitle: "Total Fine"
                        )

                        // Issue Book
                        StatCard2(
                            icon: "book.fill",
                            iconColor: .blue,
                            title: "\(activeUsers)",
                            subtitle: "Issued Books"
                        )
                    }
                    .padding(.horizontal)

                    // Library Section
                    if let library = assignedLibrary {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("My Library")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            // Updated Library Card with image support
                            LibraryDetailCard(library: library)
                                .padding(.horizontal)
                        }
                    } else {
                        VStack {
                            ProgressView()
                            Text("Loading Library Details...")
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 30)
                    }

//                  12   Recent Activities
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Pre-Book Requests")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            ForEach(preBookItems) { preBook in
                                PreBookRequestRow(preBook: preBook)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
//                    VStack(alignment: .leading, spacing: 16) {
//                        Text("Pre-Book Requests")
//                            .font(.title2)
//                            .fontWeight(.bold)
//                            .padding(.horizontal)
//
//                        VStack {
//                            if preBookItems.isEmpty {
//                                // Show message when there are no requests
//                                Text("No requests")
//                                    .foregroundColor(.gray)
//                                    .frame(maxWidth: .infinity, minHeight: 100) // Fixed height for uniformity
//                                    .background(Color(.systemGray6))
//                                    .cornerRadius(10)
//                                    .padding(.horizontal)
//                            } else {
//                                // List of pre-book requests
//                                VStack(spacing: 12) {
//                                    ForEach(preBookItems) { preBook in
//                                        PreBookRequestRow(preBook: preBook)
//                                            .padding()
//                                            .background(Color(.systemGray6))
//                                            .cornerRadius(10)
//                                    }
//                                }
//                                .padding(.horizontal)
//                            }
//                        }
//                        .padding(.horizontal)
//                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Librarian Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 4) { // Adjust spacing as needed
                        Image(systemName: "bell")
                            .font(.title3)
                            .foregroundStyle(.blue)
                            .onTapGesture {
                                showNotification = true
                            }
                            .sheet(isPresented: $showNotification) {
                                NavigationStack {
                                    LibNotificationsView()
                                }
                            }

                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .onTapGesture {
                                showProfile = true
                            }
                            .sheet(isPresented: $showProfile) {
                                NavigationStack {
                                    Setting()
                                }
                            }
                    }
                }
            }
            .onAppear {
                fetchLibraryData()
                fetchPreBookRequests()
                fetchAssignedLibrary() // Add this line
            }
        }

    }
    
    private func fetchAssignedLibrary() {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user logged in")
            return
        }
        
        let db = Firestore.firestore()
        
        // Fetch the current librarian's document
        db.collection("librarians").document(currentUser.uid).getDocument { (document, error) in
            if let error = error {
                print("Error fetching librarian: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists,
                  let libraryId = document.data()?["libraryId"] as? String else {
                print("No assigned library found")
                return
            }
            
            // Now fetch the library details using libraryId
            db.collection("libraries").document(libraryId).getDocument { (libraryDocument, error) in
                if let error = error {
                    print("Error fetching library: \(error.localizedDescription)")
                    return
                }
                
                guard let libraryDocument = libraryDocument, libraryDocument.exists else {
                    print("Library document not found")
                    return
                }
                
                let data = libraryDocument.data()!
                
                let address = Address(
                    line1: (data["address"] as? [String: Any])?["line1"] as? String ?? "",
                    line2: (data["address"] as? [String: Any])?["line2"] as? String ?? "",
                    city: (data["address"] as? [String: Any])?["city"] as? String ?? "",
                    state: (data["address"] as? [String: Any])?["state"] as? String ?? "",
                    zipCode: (data["address"] as? [String: Any])?["zipCode"] as? String ?? "",
                    country: (data["address"] as? [String: Any])?["country"] as? String ?? ""
                )
                
                let contact = Contact(
                    phone: (data["contact"] as? [String: Any])?["phone"] as? String ?? "",
                    email: (data["contact"] as? [String: Any])?["email"] as? String ?? "",
                    website: (data["contact"] as? [String: Any])?["website"] as? String ?? ""
                )
                
                let weekdayHoursData = (data["operationalHours"] as? [String: Any])?["weekday"] as? [String: String] ?? [:]
                let weekendHoursData = (data["operationalHours"] as? [String: Any])?["weekend"] as? [String: String] ?? [:]
                
                let operationalHours = OperationalHours(
                    weekday: OpeningHours(
                        opening: weekdayHoursData["opening"] ?? "",
                        closing: weekdayHoursData["closing"] ?? ""
                    ),
                    weekend: OpeningHours(
                        opening: weekendHoursData["opening"] ?? "",
                        closing: weekendHoursData["closing"] ?? ""
                    )
                )
                
                let settings = LibrarySettings(
                    maxBooksPerMember: (data["settings"] as? [String: Any])?["maxBooksPerMember"] as? String ?? "",
                    lateFee: (data["settings"] as? [String: Any])?["lateFee"] as? String ?? "",
                    lendingPeriod: (data["settings"] as? [String: Any])?["lendingPeriod"] as? String ?? ""
                )
                
                let staff = Staff(
                    headLibrarian: (data["staff"] as? [String: Any])?["headLibrarian"] as? String ?? "",
                    totalStaff: (data["staff"] as? [String: Any])?["totalStaff"] as? String ?? ""
                )
                
                let featuresData = data["features"] as? [String: Bool] ?? [:]
                let features = Features(
                    wifi: featuresData["wifi"] ?? false,
                    computerLab: featuresData["computerLab"] ?? false,
                    meetingRooms: featuresData["meetingRooms"] ?? false,
                    parking: featuresData["parking"] ?? false
                )
                
                let library = Library(
                    id: libraryDocument.documentID,
                    name: data["name"] as? String ?? "",
                    code: data["code"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    address: address,
                    contact: contact,
                    operationalHours: operationalHours,
                    settings: settings,
                    staff: staff,
                    features: features,
                    createdAt: data["createdAt"] as? Timestamp ?? Timestamp(),
                    coverImageUrl: data["coverImageUrl"] as? String ?? ""
                )
                
                DispatchQueue.main.async {
                    self.assignedLibrary = library
                }
            }
        }
    }
    private func fetchPreBookRequests() {
        let db = Firestore.firestore()
        
        db.collection("PreBook").whereField("status", isEqualTo: "Pending").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching pre-book requests: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            self.preBookItems = documents.map { document in
                PreBookItem(
                    id: document.documentID,
                    userEmail: document.data()["userEmail"] as? String ?? "",
                    isbn13: document.data()["isbn13"] as? String ?? "",
                    status: document.data()["status"] as? String ?? ""
                )
            }
        }
    }
    private func fetchLibraryData() {
        let db = Firestore.firestore()
        
        // Fetch books count
        db.collection("books").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching books: \(error.localizedDescription)")
                return
            }
            guard let documents = snapshot?.documents else { return }
            self.books = documents.compactMap { document -> Book? in
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
                    libraryId: data["libraryId"] as? String
                )
            }
        }
        
        // Fetch active users count
        db.collection("users").whereField("isActive", isEqualTo: true).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching users: \(error.localizedDescription)")
                return
            }
            
            if let documents = snapshot?.documents {
                self.activeUsers = documents.count
            }
        }
    }
    func confirmPreBooking(preBookId: String) {
        let db = Firestore.firestore()
        let preBookRef = db.collection("PreBook").document(preBookId)
        
        preBookRef.updateData([
            "status": "Confirmed"
        ]) { error in
            if let error = error {
                print("Error confirming pre-booking: \(error.localizedDescription)")
            } else {
                print("Pre-booking confirmed successfully!")
                // Refresh pre-book requests after confirmation
                fetchPreBookRequests()
            }
        }
    }
}

struct StatCard2: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
struct PreBookRequestRow: View {
    let preBook: PreBookItem
    @State private var isConfirmed = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(preBook.userEmail)
                    .font(.headline)
                
                Text("ISBN: \(preBook.isbn13)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                // Confirm pre-booking
                confirmPreBooking(preBookId: preBook.id)
                isConfirmed = true
            }) {
                Image(systemName: isConfirmed ? "checkmark.circle.fill" : "checkmark.circle")
                    .foregroundColor(isConfirmed ? .green : .blue)
                    .imageScale(.large)
            }
            .disabled(isConfirmed)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func confirmPreBooking(preBookId: String) {
        let db = Firestore.firestore()
        let preBookRef = db.collection("PreBook").document(preBookId)
        
        preBookRef.updateData([
            "status": "Confirmed"
        ]) { error in
            if let error = error {
                print("Error confirming pre-booking: \(error.localizedDescription)")
            } else {
                print("Pre-booking confirmed successfully!")
            }
        }
    }
}
struct homeLibraryCard: View {
    let name: String
    let location: String
    let image: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 150)
                .clipped()
                .cornerRadius(12)
                .background(Color(.systemGray6))
            
            Text(name)
                .font(.title3)
                .fontWeight(.bold)
            
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.gray)
                Text(location)
                    .foregroundColor(.gray)
            }
            .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
}

struct ActivityRow: View {
    let activity: LibraryActivity
    
    var body: some View {
        HStack {
            // Activity Icon
            Image(systemName: activity.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            // Activity Details
            VStack(alignment: .leading) {
                Text(activity.title)
                    .fontWeight(.medium)
                Text(activity.userName)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Time and Status
            VStack(alignment: .trailing) {
                Text(activity.timeAgo)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Image(systemName: activity.status == .completed ? "checkmark.circle.fill" : "clock.fill")
                    .foregroundColor(activity.status == .completed ? .green : .orange)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct LibraryActivity: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let userName: String
    let timeAgo: String
    let status: ActivityStatus
    
    enum ActivityStatus {
        case completed, pending
    }
}

//struct IssueBookCard: View {
//    var body: some View {
//        NavigationLink(destination: AddIssueBookView()) {
//            VStack(alignment: .leading, spacing: 8) {
//                Image(systemName: "plus")
//                    .foregroundColor(.blue)
//
//                Text("Issue Book")
//                    .font(.subheadline)
//                    .fontWeight(.medium)
//                    .foregroundColor(.primary)
//            }
//            .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
//            .padding()
//            .background(Color(.systemGray6))
//            .cornerRadius(12)
//        }
//    }
//}
struct LibraryDetailCard: View {
    let library: Library
    @State private var decodedImage: UIImage? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image handling with priority: decoded base64 > URL > placeholder
            ZStack {
                if let decodedImage = decodedImage {
                    // Display decoded base64 image
                    Image(uiImage: decodedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 150)
                        .clipped()
                } else if let coverImageUrl = library.coverImageUrl, !coverImageUrl.isEmpty, !coverImageUrl.hasPrefix("data:image") {
                    // Display image from URL
                    AsyncImage(url: URL(string: coverImageUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .empty, .failure:
                            // Placeholder when image can't be loaded
                            Image(systemName: "building.2")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color(.systemGray6))
                        @unknown default:
                            ProgressView()
                        }
                    }
                    .frame(height: 150)
                } else {
                    // Fallback placeholder image
                    Image(systemName: "building.2")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGray6))
                        .frame(height: 150)
                }
            }
            .cornerRadius(12)
            
            NavigationLink(destination: EachLibraryView(library: library)) {
                VStack(alignment: .leading) {
                    Text(library.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.gray)
                        Text("\(library.address.city), \(library.address.state)")
                            .foregroundColor(.gray)
                    }
                    .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }
        }
        .padding(.top, 8)
        .onAppear {
            // Try to decode base64 image when the view appears
            decodeBase64Image()
        }
    }
    
    // Decode base64 image if present in library.coverImageUrl
    private func decodeBase64Image() {
        if let coverImageUrl = library.coverImageUrl,
           coverImageUrl.starts(with: "data:image") || coverImageUrl.hasPrefix("data:image") {
            // Extract base64 part after comma
            let components = coverImageUrl.components(separatedBy: ",")
            if components.count > 1,
               let imageData = Data(base64Encoded: components[1]) {
                decodedImage = UIImage(data: imageData)
            }
        }
    }
}
#Preview {
    libHomeView()
}
struct ProfileView2: View {
    var body: some View {
        VStack {
            Text("Profile Page")
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .navigationTitle("Profile")
    }
}
