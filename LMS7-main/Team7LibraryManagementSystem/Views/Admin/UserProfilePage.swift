import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // User information states
    @State private var isEditing = false
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var username = ""
    @State private var email = ""
    @State private var profileImage: UIImage? = nil
    @State private var showImagePicker = false
    
    // Genre and Language
    @State private var selectedGenres: [String] = []
    @State private var selectedLanguages: [String] = []
    @State private var showGenreSheet = false
    @State private var showLanguageSheet = false
    
    // Loading and error states
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    // Predefined lists
    private let allGenres = [
        "Fiction", "Science Fiction", "Mystery",
        "Fantasy", "Romance", "Thriller",
        "Historical Fiction", "Horror", "Non-Fiction"
    ]
    
    private let allLanguages = [
        "English", "Spanish", "French", "German",
        "Chinese", "Hindi", "Arabic", "Russian",
        "Portuguese", "Japanese"
    ]
    
    var body: some View {
        NavigationView {
            if isLoading {
                ProgressView("Loading Profile...")
            } else {
                Form {
                    // Profile Picture Section
                    Section {
                        HStack {
                            Spacer()
                            Button(action: {
                                if isEditing {
                                    showImagePicker = true
                                }
                            }) {
                                if let image = profileImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            Text(name.prefix(2).uppercased())
                                                .font(.title)
                                        )
                                }
                            }
                            Spacer()
                        }
                    }
                    
                    // Personal Information Section
                    Section(header: Text("Personal Information")) {
                        ProfileRow(title: "Name", value: $name, isEditing: isEditing)
                        ProfileRow(title: "Username", value: $username, isEditing: isEditing)
                        ProfileRow(title: "Phone Number", value: $phoneNumber, isEditing: isEditing, keyboardType: .phonePad)
                        
                        // Email Row (typically not editable)
                        HStack {
                            Text("Email")
                                .foregroundColor(.gray)
                            Spacer()
                            Text(email)
                                .foregroundColor(.black)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Reading Preferences Section
                    
                    
                    
                    
                    // Error Message
                    if let errorMessage = errorMessage {
                        Section {
                            Text(errorMessage)
                                .foregroundColor(.red)
                        }
                    }
                }
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing:
                    Button(isEditing ? "Done" : "Edit") {
                        isEditing.toggle()
                        if !isEditing {
                            saveProfile()
                        }
                    }
                )
                .sheet(isPresented: $showImagePicker) {
                    ImagePicker(image: $profileImage)
                }
                .sheet(isPresented: $showGenreSheet) {
                    MultiSelectSheet(
                        title: "Preferred Genres",
                        items: allGenres,
                        selectedItems: $selectedGenres
                    )
                }
                .sheet(isPresented: $showLanguageSheet) {
                    MultiSelectSheet(
                        title: "Preferred Languages",
                        items: allLanguages,
                        selectedItems: $selectedLanguages
                    )
                }
            }
        }
        .onAppear {
            fetchUserProfile()
        }
    }
    
    private func fetchUserProfile() {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "No user is currently signed in"
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        
        // Function to check admins collection first
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
                    
                    // Update profile fields
                    name = data["fullName"] as? String ?? ""
                    phoneNumber = data["phone"] as? String ?? ""
                    email = data["email"] as? String ?? currentUser.email ?? ""
                    username = data["username"] as? String ?? ""
                    
                    // Genres and Languages might not exist for admins
                    selectedGenres = []
                    selectedLanguages = []
                    
                    isLoading = false
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
                        errorMessage = "Error fetching profile"
                        return
                    }
                    
                    guard let documents = snapshot?.documents, !documents.isEmpty else {
                        print("🚨 No document found in librarians collection")
                        errorMessage = "User document not found"
                        return
                    }
                    
                    let document = documents[0]
                    let data = document.data()
                    
                    // Update profile fields
                    name = data["fullName"] as? String ?? ""
                    phoneNumber = data["phone"] as? String ?? ""
                    email = data["email"] as? String ?? currentUser.email ?? ""
                    username = data["username"] as? String ?? ""
                    
                    // Update reading preferences
                    selectedGenres = data["genre"] as? [String] ?? []
                    selectedLanguages = data["language"] as? [String] ?? []
                }
        }
        
        // Start by checking admins collection
        checkAdminsCollection()
    }

    private func saveProfile() {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "No user is currently signed in"
            return
        }
        
        let db = Firestore.firestore()
        
        // Determine which collection to update
        let collectionName = selectedGenres.isEmpty && selectedLanguages.isEmpty ? "admins" : "librarians"
        
        let userData: [String: Any] = collectionName == "admins"
            ? [
                "fullName": name,
                "phone": phoneNumber
            ]
            : [
                "fullName": name,
                "phone": phoneNumber,
                "genre": selectedGenres,
                "language": selectedLanguages
            ]
        
        db.collection(collectionName).document(currentUser.uid).updateData(userData) { error in
            if let error = error {
                errorMessage = "Error saving profile: \(error.localizedDescription)"
            } else {
                print("Profile updated successfully")
            }
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            // Navigate to login screen or reset app state
            print("User signed out")
        } catch {
            errorMessage = "Error signing out: \(error.localizedDescription)"
        }
    }
}


// Multi-Select Sheet for Genres and Languages
struct MultiSelectSheet: View {
    let title: String
    let items: [String]
    @Binding var selectedItems: [String]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(items, id: \.self) { item in
                    MultiSelectRow(
                        title: item,
                        isSelected: selectedItems.contains(item)
                    ) {
                        if selectedItems.contains(item) {
                            selectedItems.removeAll { $0 == item }
                        } else {
                            selectedItems.append(item)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Done") { dismiss() }
            )
        }
    }
}

// Multi-Select Row Component
struct MultiSelectRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}

// Improved Profile Row with more options
struct ProfileRow: View {
    var title: String
    @Binding var value: String
    var isEditing: Bool
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            if isEditing {
                if isSecure {
                    SecureField("Enter \(title)", text: $value)
                        .multilineTextAlignment(.trailing)
                } else {
                    TextField("Enter \(title)", text: $value)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(keyboardType)
                }
            } else {
                Text(value)
                    .foregroundColor(.black)
            }
        }
        .padding(.vertical, 5)
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
