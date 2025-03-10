
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct UserProfileView: View {
    @State private var userProfile: UserProfile?
    @State private var isEditing = false
    @State private var selectedGenres: [String] = []
    @State private var selectedLanguages: [String] = []
    
    @State private var showGenrePicker = false
    @State private var showLanguagePicker = false
    
    @State private var profileImage: UIImage? = nil
    @State private var showImagePicker = false
    
    
    private let db = Firestore.firestore()
    private let userId = Auth.auth().currentUser?.uid ?? ""
    
    // Available options
    private let allGenres = ["Fiction", "Mystery & Thriller", "Romance", "Science Fiction", "Fantasy", "Biography", "History", "Self-Help", "Business", "Science", "Poetry", "Comics & Manga", "Horror", "Travel", "Cooking", "Art & Design"]
    
    private let allLanguages = [ "Afrikaans", "Albanian", "Amharic", "Arabic", "Armenian", "Azerbaijani", "Basque", "Belarusian", "Bengali", "Bosnian",
                                 "Bulgarian", "Burmese", "Catalan", "Cebuano", "Chinese", "Corsican", "Croatian", "Czech", "Danish", "Dutch",
                                 "Esperanto", "Estonian", "Filipino", "Finnish", "French", "Galician", "Georgian", "German", "Greek", "Gujarati",
                                 "Haitian Creole", "Hausa", "Hawaiian", "Hebrew", "Hindi", "Hmong", "Hungarian", "Icelandic", "Igbo", "Indonesian",
                                 "Irish", "Italian", "Japanese", "Javanese", "Kannada", "Kazakh", "Khmer", "Korean", "Kurdish", "Kyrgyz",
                                 "Lao", "Latin", "Latvian", "Lithuanian", "Luxembourgish", "Macedonian", "Malagasy", "Malay", "Malayalam", "Maltese",
                                 "Maori", "Marathi", "Mongolian", "Nepali", "Norwegian", "Pashto", "Persian", "Polish", "Portuguese", "Punjabi",
                                 "Romanian", "Russian", "Samoan", "Serbian", "Sinhala", "Slovak", "Slovenian", "Somali", "Spanish", "Sundanese",
                                 "Swahili", "Swedish", "Tagalog", "Tajik", "Tamil", "Telugu", "Thai", "Turkish", "Ukrainian", "Urdu", "Uzbek",
                                 "Vietnamese", "Welsh", "Xhosa", "Yiddish", "Yoruba", "Zulu"]
    
    var body: some View {
        NavigationView {
            Form {
                
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
                            }
                        }
                        .buttonStyle(PlainButtonStyle()) // ✅ Removes any extra button styling
                        .frame(width: 100, height: 100)  // ✅ Ensures the tappable area is the same as the circle
                        .background(Color.clear)          // ✅ Matches the background color
                        .clipShape(Circle())
                        Spacer()
                        
                    }
                }
                if let user = userProfile {
                    // **Personal Information**
                    Section(header: Text("Personal Information")) {
                        ProfileRow(title: "First Name", value: binding(for: \.firstName), isEditing: isEditing)
                        ProfileRow(title: "Last Name", value: binding(for: \.lastName), isEditing: isEditing)
                        ProfileRow(title: "Phone No.", value: binding(for: \.mobileNumber), isEditing: isEditing)
                    }
                    
                    // **Account Details**
                    Section(header: Text("Account Details")) {
                        ProfileRow(title: "Email", value: .constant(user.email), isEditing: false)
                    }
                    
                    // **Preferences**
                    Section(header: Text("Preferences")) {
                        GenreSelectionViewProfile(selectedGenres: $selectedGenres, allGenres: allGenres, isEditing: isEditing, showSheet: $showGenrePicker)
                        LanguageSelectionViewProfile(selectedLanguages: $selectedLanguages, allLanguages: allLanguages, isEditing: isEditing, showSheet: $showLanguagePicker)
                    }
                    
                    // **Sign Out**
                    Section {
                        Button(action: signOut) {
                            Text("Sign Out").foregroundColor(.red)
                        }
                    }
                } else {
                    Text("Loading profile...")
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing:
                                    Button(isEditing ? "Done" : "Edit") {
                if isEditing { saveProfile() }
                isEditing.toggle()
            }
            )
            .onAppear(perform: fetchUserProfile)
        }
    }
    
    /// **Creates a safe binding for userProfile properties**
    private func binding(for keyPath: WritableKeyPath<UserProfile, String>) -> Binding<String> {
        Binding(
            get: { userProfile?[keyPath: keyPath] ?? "" },
            set: { newValue in
                if userProfile != nil {
                    userProfile![keyPath: keyPath] = newValue
                }
            }
        )
    }
    
    // **Fetch User Profile**
    private func fetchUserProfile() {
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error fetching document: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                do {
                    let data = try document.data(as: UserProfile.self)
                    DispatchQueue.main.async {
                        self.userProfile = data
                        self.selectedGenres = data.genre
                        self.selectedLanguages = data.language
                    }
                } catch {
                    print("Error decoding user data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // **Save Updated Profile**
    private func saveProfile() {
        guard var user = userProfile else { return }
        user.genre = selectedGenres
        user.language = selectedLanguages
        
        do {
            try db.collection("users").document(userId).setData(from: user)
            print("✅ Profile updated successfully!")
        } catch {
            print("❌ Error saving profile: \(error.localizedDescription)")
        }
    }
    
    // **Sign Out**
    private func signOut() {
        do {
            try Auth.auth().signOut()
            UIApplication.shared.windows.first?.rootViewController = UIHostingController(rootView: LibraryLoginView())
            UIApplication.shared.windows.first?.makeKeyAndVisible()
            print("✅ User signed out")
        } catch {
            print("❌ Error signing out: \(error.localizedDescription)")
        }
    }
}

//struct GenreSelectionViewProfile: View {
//    @Binding var selectedGenres: [String]
//    let allGenres: [String]
//    var isEditing: Bool
//    @Binding var showSheet: Bool
//
//    var body: some View {
//        HStack {
//            Text("Preferred Genres")
//            Spacer()
//            Button(action: { showSheet = true }) {
//                Text(selectedGenres.isEmpty ? "Select" : selectedGenres.joined(separator: ", "))
//                    .foregroundColor(.blue)
//            }
//        }
//        .sheet(isPresented: $showSheet) {
//            MultiSelectSheetProfile(title: "Select Genres", options: allGenres, selectedItems: $selectedGenres)
//        }
//    }
//}
//
//
//
//
//struct LanguageSelectionViewProfile: View {
//    @Binding var selectedLanguages: [String]
//    let allLanguages: [String]
//    var isEditing: Bool
//    @Binding var showSheet: Bool
//
//    var body: some View {
//        HStack {
//            Text("Preferred Languages")
//            Spacer()
//            Button(action: { showSheet = true }) {
//                Text(selectedLanguages.isEmpty ? "Select" : selectedLanguages.joined(separator: ", "))
//                    .foregroundColor(.blue)
//            }
//        }
//        .sheet(isPresented: $showSheet) {
//            MultiSelectSheetProfile(title: "Select Languages", options: allLanguages, selectedItems: $selectedLanguages)
//        }
//    }
//}


struct GenreSelectionViewProfile: View {
    @Binding var selectedGenres: [String]
    let allGenres: [String]
    var isEditing: Bool
    @Binding var showSheet: Bool
    
    var body: some View {
        HStack {
            Text("Preferred Genres")
            Spacer()
            Button(action: {
                if isEditing { showSheet = true } // ✅ Only open if editing is enabled
            }) {
                Text(selectedGenres.isEmpty ? "Select" : selectedGenres.joined(separator: ", "))
                    .foregroundColor(isEditing ? .blue : .gray) // ✅ Disable look when not editing
            }
            .disabled(!isEditing) // ✅ Prevent interaction when not editing
        }
        .sheet(isPresented: $showSheet) {
            MultiSelectSheetProfile(title: "Select Genres", options: allGenres, selectedItems: $selectedGenres)
        }
    }
}

struct LanguageSelectionViewProfile: View {
    @Binding var selectedLanguages: [String]
    let allLanguages: [String]
    var isEditing: Bool
    @Binding var showSheet: Bool
    
    var body: some View {
        HStack {
            Text("Preferred Languages")
            Spacer()
            Button(action: {
                if isEditing { showSheet = true } // ✅ Only open if editing is enabled
            }) {
                Text(selectedLanguages.isEmpty ? "Select" : selectedLanguages.joined(separator: ", "))
                    .foregroundColor(isEditing ? .blue : .gray) // ✅ Disable look when not editing
            }
            .disabled(!isEditing) // ✅ Prevent interaction when not editing
        }
        .sheet(isPresented: $showSheet) {
            MultiSelectSheetProfile(title: "Select Languages", options: allLanguages, selectedItems: $selectedLanguages)
        }
    }
}



struct MultiSelectSheetProfile: View {
    let title: String
    let options: [String]
    @Binding var selectedItems: [String]
    
    @Environment(\.dismiss) var dismiss // ✅ Use SwiftUI's built-in dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(options, id: \.self) { option in
                    HStack {
                        Text(option)
                        Spacer()
                        if selectedItems.contains(option) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedItems.contains(option) {
                            selectedItems.removeAll { $0 == option }
                        } else {
                            selectedItems.append(option)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarItems(trailing: Button("Done") {
                dismiss() // ✅ Proper SwiftUI way to close the sheet
            })
        }
    }
}
#Preview{
    //    UserProfileView()
}
