
import SwiftUI
import Firebase
import FirebaseFirestore

// User model - renamed to LibraryUser to avoid ambiguity with SwiftUI's User
struct LibraryUser: Identifiable {
    var id: String
    var firstName: String
    var lastName: String
    var email: String
    var isActive: Bool = false
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
}

// Main view
struct LibraryUsersView: View {
    @StateObject private var viewModel = UsersViewModel()
    @State private var searchText = ""
//    var userId: String {
//        UserDefaults.standard.string(forKey: "userId") ?? ""
//    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
            VStack(spacing: 0) {
                // Search bar
                TextField("Search users...", text: $searchText)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top)
                    .onChange(of: searchText) { newValue in
                        viewModel.filterUsers(searchText: newValue)
                    }
                
                // Stats cards
                HStack {
                    StatCardView(number: viewModel.totalUsers, title: "Total Users", color: Color(.systemBlue).opacity(0.2))
                    StatCardView(number: viewModel.activeUsers, title: "Active Users", color: Color(.systemGreen).opacity(0.2))
                    StatCardView(number: viewModel.newUsersToday, title: "New Today", color: Color(.systemPurple).opacity(0.2))
                }
                .padding()
                
                // Recent users section header
                HStack {
                    Text("Recent Users")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    // Your "See All" button if needed
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
                
                // User list - now correctly outside the HStack
                
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.filteredUsers) { user in
                            NavigationLink(destination: UserProfileViewLibrarian(userID: user.id)) {
                                UserRowView(user: user)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
            }
            .padding(.top)
            .navigationTitle("Library Users")
            .onAppear {
                viewModel.fetchUsers()
            }
        }
    }
    
    // User row component - renamed to avoid redeclaration
    struct UserRowView: View {
        let user: LibraryUser
        
        var body: some View {
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading) {
                    Text(user.fullName)
                        .font(.headline)
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 4)
        }
    }
    
    // Stat card component - renamed to avoid redeclaration
    struct StatCardView: View {
        let number: Int
        let title: String
        let color: Color
        
        var body: some View {
            VStack {
                Text("\(number)")
                    .font(.title)
                    .fontWeight(.bold)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .cornerRadius(10)
        }
    }
    
    // All users view
    struct AllUsersView: View {
        let users: [LibraryUser]
        
        
        var body: some View {
            List(users) { user in
                
                UserRowView(user: user)
                
            }
            .navigationTitle("All Users")
        }
    }
    
    // User detail view
    struct UserDetailView: View {
        let user: LibraryUser
        
        var body: some View {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
                
                Text(user.fullName)
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 10) {
                    DetailRowView(title: "Email", value: user.email)
                    DetailRowView(title: "Status", value: user.isActive ? "Active" : "Inactive")
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("User Details")
        }
    }
    
    // Renamed to avoid redeclaration
    struct DetailRowView: View {
        let title: String
        let value: String
        
        var body: some View {
            HStack {
                Text(title)
                    .fontWeight(.semibold)
                    .frame(width: 100, alignment: .leading)
                
                Text(value)
                    .foregroundColor(.gray)
                
                Spacer()
            }
        }
    }
    
    // ViewModel for handling Firebase data
    class UsersViewModel: ObservableObject {
        @Published var users: [LibraryUser] = []
        @Published var filteredUsers: [LibraryUser] = []
        
        var totalUsers: Int {
            return users.count
        }
        
        var activeUsers: Int {
            return users.filter { $0.isActive }.count
        }
        
        var newUsersToday: Int {
            // Calculate users added today
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            // In a real app, you would filter based on creation date
            // This is just a placeholder for demonstration
            return 12
        }
        
        private var db = Firestore.firestore()
        
        func fetchUsers() {
            db.collection("users").addSnapshotListener { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    print("No documents")
                    return
                }
                
                self.users = documents.map { document -> LibraryUser in
                    let data = document.data()
                    
                    let id = document.documentID
                    let firstName = data["firstName"] as? String ?? ""
                    let lastName = data["lastName"] as? String ?? ""
                    let email = data["email"] as? String ?? ""
                    let isActive = data["isActive"] as? Bool ?? false
                    
                    return LibraryUser(id: id, firstName: firstName, lastName: lastName, email: email, isActive: isActive)
                }
                
                self.filteredUsers = self.users
            }
        }
        
        func filterUsers(searchText: String) {
            if searchText.isEmpty {
                filteredUsers = users
            } else {
                filteredUsers = users.filter { user in
                    return user.firstName.lowercased().contains(searchText.lowercased()) ||
                    user.lastName.lowercased().contains(searchText.lowercased()) ||
                    user.email.lowercased().contains(searchText.lowercased())
                }
            }
        }
    }
    
    
    
}
