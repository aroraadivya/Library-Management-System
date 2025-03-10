//
//  AdminDashboardView.swift
//  LibraryManagement
//
//  Created by Taksh Joshi on 16/02/25.
//

import SwiftUI
import FirebaseFirestore

struct AdminDashboardView: View {
    @State private var selectedTab = 0
    @State private var showProfile = false
    @State private var adminRole: String = ""
    @State private var showNotification = false
    @State private var libraries: [Library] = []
    @State private var totalBooks: Int = 0
    @State private var activeUsers: Int = 0
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // MARK: - Top Cards
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                        DashboardCard(
                            title: "Available Books",
                            value: "\(totalBooks)",
                            percentage: "",
                            icon: "books.vertical"
                        )
                        DashboardCard(
                            title: "Active Users",
                            value: "\(activeUsers)",
                            percentage: "",
                            icon: "person"
                        )
                        DashboardCard(
                            title: "Librarians",
                            value: "\(totalLibrarians)",
                            percentage: "",
                            icon: "person.2"
                        )
                        DashboardCard(
                            title: "Libraries",
                            value: "\(libraries.count)",
                            percentage: "",
                            icon: "building.columns"
                        )
                    }
                    .padding(.horizontal)
                    .onAppear {
                        fetchTotalBooks()
                        fetchActiveUsers()
                    }
                    
                    
                    if adminRole == "Super Admin" {
                        NavigationLink(destination: AdminManagementView()) {
                            VStack(alignment: .leading) {
                                Text("Total Admins")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top)

                                AdminsCard()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                    }
                    
                    // MARK: - System Statistics
                    Text("System Statistics")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                        StatisticsCard(title: "Fine Collections", value: "$1,234", percentage: "+12.5%")
                        StatisticsCard(title: "New Users", value: "156", percentage: "+8.3%")
                        StatisticsCard(title: "Book Returns", value: "89%", percentage: "-2.1%")
                        StatisticsCard(title: "Active Events", value: "12", percentage: "+4.7%")
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Libraries Section
                    Text("Libraries")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(libraries) { library in
                                LibraryCard(
                                    imageName: "building.columns.fill",
                                    name: library.name,
                                    location: "\(library.address.city), \(library.address.state)",
                                    books: "Staff: \(library.staff.totalStaff)"
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .onAppear {
                        fetchLibraries()
                    }
                    
                    // MARK: - Pending Approvals Section
                    Text("Pending Approvals")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    VStack(spacing: 10) {
                        ApprovalCard(title: "Inter-library Exchange", subtitle: "Request from Central Library", time: "2 hours ago")
                        ApprovalCard(title: "New Event Proposal", subtitle: "Summer Reading Workshop", time: "3 hours ago")
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Recent Activities Section
//                    Text("Recent Activities")
//                        .font(.headline)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        .padding(.horizontal)
//                        .padding(.top)
//                    
//                    VStack(spacing: 8) {
//                        ActivityCard(icon: "person.badge.plus", title: "New Librarian Added", subtitle: "Sarah Johnson was added as librarian", time: "2 hours ago")
//                        ActivityCard(icon: "book.fill", title: "Book Category Updated", subtitle: "Fiction section reorganized", time: "3 hours ago")
//                        ActivityCard(icon: "bell.fill", title: "Notification Sent", subtitle: "Event reminder sent to all librarians", time: "5 hours ago")
//                        ActivityCard(icon: "exclamationmark.circle.fill", title: "Account Suspended", subtitle: "Librarian account temporarily suspended", time: "6 hours ago")
//                    }
//                    .padding(.horizontal)
//                    Spacer(minLength: 80)
                }
            }
            .navigationTitle("Admin Dashboard")
            .background(Color(.systemGroupedBackground))
            .toolbar {
                HStack(spacing: 4) {
                    Image(systemName: "bell")
                        .font(.title3)
                        .foregroundStyle(.black)
                        .onTapGesture {
                            showNotification = true
                        }
                        .sheet(isPresented: $showNotification) {
                            NavigationStack {
                                NotificationsView()
                                // Notification View
                            }
                        }
                    
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.blue)
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
            .background(Color(.systemGroupedBackground))
            .onAppear {
                fetchAdminRole() // Fetch the admin role when the view appears
            }
        }
    }
    private var totalLibrarians: Int {
        libraries.reduce(0) { sum, library in
            // Convert string to integer, defaulting to 0 if conversion fails
            sum + (Int(library.staff.totalStaff) ?? 0)
        }
    }
    private func fetchTotalBooks() {
        let db = Firestore.firestore()
        db.collection("books").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching books: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No books found")
                return
            }
            
            let books = documents.compactMap { document -> Book? in
                try? document.data(as: Book.self)
            }
            
            // Calculate total quantity of all books
            self.totalBooks = books.reduce(0) { sum, book in
                sum + book.quantity
            }
        }
    }
    private func fetchActiveUsers() {
        let db = Firestore.firestore()
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching users: \(error.localizedDescription)")
                return
            }
            
            if let count = snapshot?.documents.count {
                self.activeUsers = count
            }
        }
    }
    private func fetchLibraries() {
        let db = Firestore.firestore()
        db.collection("libraries").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching libraries: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No libraries found")
                return
            }
            
            self.libraries = documents.compactMap { document in
                try? document.data(as: Library.self)
            }
        }
    }
    // MARK: - Fetch Admin Role
    private func fetchAdminRole() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            print("User ID not found")
            return
        }
        print("\(userId)")
        let db = Firestore.firestore()
        db.collection("admins").whereField("userId", isEqualTo: userId).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching admin role: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("Admin document not found for userId: \(userId)")
                return
            }
            
            // Assuming there's only one matching document
            let document = documents.first
            if let data = document?.data(), let role = data["role"] as? String {
                self.adminRole = role
                print("Admin role: \(role)")
            } else {
                print("Role field missing or not a string")
            }
            
        }
    }

}

struct AdminsCard: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "person.circle")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.blue)
                    Text("4")
                        .font(.title3)
                        .bold()
                }
                
                Text("Admins")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(">")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(10)
//        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray.opacity(0.3), lineWidth: 1)
        )
    }
}


// MARK: - Custom Tab Bar Item
struct TabBarItem: View {
    var icon: String
    var title: String
    var isSelected: Bool
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(isSelected ? .blue : .gray)
            Text(title)
                .font(.caption)
                .foregroundColor(isSelected ? .blue : .gray)
        }
    }
}
struct DashboardCard: View {
    var title: String
    var value: String
    var percentage: String
    var icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Image(systemName: icon)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.blue)
//                Spacer()
//                Text(percentage)
//                    .font(.subheadline)
//                    .foregroundColor(percentage.contains("-") ? .red : .green)
            }
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(10)
//        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct StatisticsCard: View {
    var title: String
    var value: String
    var percentage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
//            Text(percentage)
//                .font(.caption)
//                .foregroundColor(percentage.contains("-") ? .red : .green)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(10)
//        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct LibraryCard: View {
    var imageName: String
    var name: String
    var location: String
    var books: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 100)
                .foregroundColor(.blue)
            
            Text(name)
                .bold()
            
            HStack {
                Image(systemName: "mappin.and.ellipse") // Location icon
                    .foregroundColor(.gray)
                Text(location)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Image(systemName: "books.vertical") // Books icon
                    .foregroundColor(.gray)
                Text(books)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 150)
        .padding()
        .background(Color.white)
        .cornerRadius(10)
//        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray.opacity(0.3), lineWidth: 1)
        )
    }
}


struct ApprovalCard: View {
    var title: String
    var subtitle: String
    var time: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title).bold()
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(time)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            Spacer()
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.green)
                
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
//        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray.opacity(0.3), lineWidth: 1)
        )
    }
}
struct ActivityCard: View {
    var icon: String
    var title: String
    var subtitle: String
    var time: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(.blue)
                .padding()
                .background(.blue.opacity(0.1))
                .cornerRadius(50)
            
            VStack(alignment: .leading) {
                Text(title).bold()
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
//        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray.opacity(0.3), lineWidth: 1)
        )
    }
}


struct AdminDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        AdminDashboardView()
    }
}
struct DashboardCard2: View {
    var title: String
    var value: String
    var percentage: String
    var icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Image(systemName: icon)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.blue)
            }
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray.opacity(0.3), lineWidth: 1)
        )
    }
}
