import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct Setting: View {
    @Environment(\.dismiss) var dismiss
    @State private var isOverdueNotificationsOn = true
    @State private var isBookRequestAlertsOn = true
    @State private var isSystemNotificationsOn = true
    @State private var isDarkMode = false
    
    // User information states
    @State private var userName = "Loading..."
    @State private var userEmail = "Loading..."
    @State private var userRole = "User"
    @State private var isLoading = true
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Card
                        VStack {
                            NavigationLink(destination: ProfileView()) {
                                HStack(spacing: 15) {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 70, height: 70)
                                        .foregroundColor(.blue)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(userName)
                                            .font(.title3)
                                            .fontWeight(.bold)
                                        
                                        Text(userRole)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        Text(userEmail)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)
                        .redacted(reason: isLoading ? .placeholder : [])
                        
                        // Library Policies Section
                        SettingsSection(title: "Library Policies") {
                            SettingsNavigationLink(icon: "book", iconColor: .blue, title: "Manage Library Rules", destination: AnyView(Text("Manage Library Rules")))
                            
                            SettingsNavigationLink(icon: "book.closed", iconColor: .blue, title: "Book Limits Per User", destination: AnyView(Text("Book Limits")))
                            
                            SettingsNavigationLink(icon: "dollarsign.circle", iconColor: .blue, title: "Fine Management", destination: AnyView(Text("Fine Management")))
                        }
                        
                        // Notifications Section
                        SettingsSection(title: "Notifications & Alerts") {
                            SettingsToggleRow(icon: "bell", iconColor: .blue, title: "Overdue Notifications", isOn: $isOverdueNotificationsOn)
                            
                            SettingsToggleRow(icon: "envelope", iconColor: .blue, title: "Book Request Alerts", isOn: $isBookRequestAlertsOn)
                            
                            SettingsToggleRow(icon: "gearshape", iconColor: .blue, title: "System Notifications", isOn: $isSystemNotificationsOn)
                        }
                        
                        // Data Export Section
                        SettingsSection(title: "Data Export") {
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "doc")
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Export Library Data (CSV)")
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        
                                        Text("Complete database export")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.down.circle")
                                        .foregroundColor(.blue)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "chart.bar")
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Generate PDF Report")
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        
                                        Text("Monthly statistics and analytics")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.down.circle")
                                        .foregroundColor(.blue)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Sign Out Button
                        Button(action: { showSignOutAlert = true }) {
                            HStack {
                                Spacer()
                                Text("Sign Out")
                                    .foregroundColor(.red)
                                    .fontWeight(.bold)
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        // App Info
                        VStack(spacing: 5) {
                            Text("Library Management System")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            
                            Text("Version 1.0.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 20)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .alert(isPresented: $showSignOutAlert) {
                Alert(
                    title: Text("Sign Out"),
                    message: Text("Are you sure you want to sign out?"),
                    primaryButton: .destructive(Text("Sign Out")) {
                        signOut()
                    },
                    secondaryButton: .cancel()
                )
            }
            .onAppear {
                fetchUserProfile()
            }
        }
    }
    
    private func fetchUserProfile() {
        guard let currentUser = Auth.auth().currentUser else {
            print("🚨 ERROR: No user is currently signed in")
            userName = "No User"
            userEmail = "No Email"
            userRole = "No Role"
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        
        // Function to check admin collection first
        func checkAdminsCollection() {
            db.collection("admins")
                .whereField("userId", isEqualTo: currentUser.uid)
                .getDocuments { (snapshot, error) in
                    if let error = error {
                        print("🚨 Admins Collection Error: \(error.localizedDescription)")
                        checkLibrariansCollection()
                        return
                    }
                    
                    guard let documents = snapshot?.documents, !documents.isEmpty else {
                        checkLibrariansCollection()
                        return
                    }
                    
                    let document = documents[0]
                    let data = document.data()
                    print("📦 Fetched Admin Data: \(data)")
                    
                    userName = data["fullName"] as? String ?? "Unknown User"
                    userEmail = data["email"] as? String ?? currentUser.email ?? "No Email"
                    userRole = data["role"] as? String ?? "Admin"
                    
                    isLoading = false
                    
                    print("👤 Parsed Admin Info:")
                    print("Name: \(userName)")
                    print("Email: \(userEmail)")
                    print("Role: \(userRole)")
                }
        }
        
        // Function to check librarians collection
        func checkLibrariansCollection() {
            db.collection("librarians")
                .whereField("userId", isEqualTo: currentUser.uid)
                .getDocuments { (snapshot, error) in
                    isLoading = false
                    
                    if let error = error {
                        print("🚨 Librarians Collection Error: \(error.localizedDescription)")
                        userName = "Unknown User"
                        userEmail = currentUser.email ?? "No Email"
                        userRole = "User"
                        return
                    }
                    
                    guard let documents = snapshot?.documents, !documents.isEmpty else {
                        print("🚨 No document found in librarians collection")
                        userName = currentUser.displayName ?? "Unknown User"
                        userEmail = currentUser.email ?? "No Email"
                        userRole = "User"
                        return
                    }
                    
                    let document = documents[0]
                    let data = document.data()
                    print("📦 Fetched Librarian Data: \(data)")
                    
                    userName = data["fullName"] as? String ?? "Unknown User"
                    userEmail = data["email"] as? String ?? currentUser.email ?? "No Email"
                    userRole = data["role"] as? String ?? "Librarian"
                    
                    print("👤 Parsed Librarian Info:")
                    print("Name: \(userName)")
                    print("Email: \(userEmail)")
                    print("Role: \(userRole)")
                }
        }
        
        // Start by checking admins collection
        checkAdminsCollection()
    }
    private func signOut() {
        do {
            try Auth.auth().signOut()
            // Navigate to login screen
            // Use a root view reset approach
            UIApplication.shared.windows.first?.rootViewController = UIHostingController(rootView: LibraryLoginView())
            UIApplication.shared.windows.first?.makeKeyAndVisible()
            print("User signed out")
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}


// MARK: - Support Components
struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            VStack(spacing: 2) {
                content
            }
            .padding(.horizontal)
        }
    }
}

struct SettingsNavigationLink: View {
    let icon: String
    let iconColor: Color
    let title: String
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 30)
                
                Text(title)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 30)
            
            Text(title)
                .fontWeight(.medium)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

// This is just a placeholder for the AdminProfile view


struct Setting_Previews: PreviewProvider {
    static var previews: some View {
        Setting()
    }
}
