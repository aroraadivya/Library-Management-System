//
//  LanguagePreferencesView.swift
//  LMS user
//
//  Created by Divya Arora on 13/02/25.
//
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct LanguagePreferencesView: View {
    @State private var selectedLanguages: Set<String> = [] // No default selection
    @State private var searchText: String = ""
    @State private var navigateToNextScreen = false // Control navigation

    let popularLanguages = ["English", "Spanish", "French", "German"]
    
    // Full list of world languages
    let allLanguages = [
        "Afrikaans", "Albanian", "Amharic", "Arabic", "Armenian", "Azerbaijani", "Basque", "Belarusian", "Bengali", "Bosnian",
        "Bulgarian", "Burmese", "Catalan", "Cebuano", "Chinese", "Corsican", "Croatian", "Czech", "Danish", "Dutch",
        "Esperanto", "Estonian", "Filipino", "Finnish", "French", "Galician", "Georgian", "German", "Greek", "Gujarati",
        "Haitian Creole", "Hausa", "Hawaiian", "Hebrew", "Hindi", "Hmong", "Hungarian", "Icelandic", "Igbo", "Indonesian",
        "Irish", "Italian", "Japanese", "Javanese", "Kannada", "Kazakh", "Khmer", "Korean", "Kurdish", "Kyrgyz",
        "Lao", "Latin", "Latvian", "Lithuanian", "Luxembourgish", "Macedonian", "Malagasy", "Malay", "Malayalam", "Maltese",
        "Maori", "Marathi", "Mongolian", "Nepali", "Norwegian", "Pashto", "Persian", "Polish", "Portuguese", "Punjabi",
        "Romanian", "Russian", "Samoan", "Serbian", "Sinhala", "Slovak", "Slovenian", "Somali", "Spanish", "Sundanese",
        "Swahili", "Swedish", "Tagalog", "Tajik", "Tamil", "Telugu", "Thai", "Turkish", "Ukrainian", "Urdu", "Uzbek",
        "Vietnamese", "Welsh", "Xhosa", "Yiddish", "Yoruba", "Zulu"
    ]

    var filteredLanguages: [String] {
        if searchText.isEmpty {
            return allLanguages
        } else {
            return allLanguages.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Search Bar with Search Icon as Placeholder
                HStack {
                    Image(systemName: "magnifyingglass") // Search icon
                        .foregroundColor(.gray)
                    
                    TextField("Search languages", text: $searchText)
                        .foregroundColor(.primary) // Keeps text color normal
                }
                .padding(10)
                .background(Color(.systemGray6)) // Light gray background
                .cornerRadius(10)
                .padding(.horizontal)

                // Popular Languages
                Text("Popular Languages")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                    ForEach(popularLanguages, id: \.self) { language in
                        Button(action: {
                            toggleSelection(language)
                        }) {
                            HStack {
                                Text(language)
                                Spacer()
                                if selectedLanguages.contains(language) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
                
                // All Languages
                Text("All Languages")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                List {
                    ForEach(filteredLanguages, id: \.self) { language in
                        Button(action: {
                            toggleSelection(language)
                        }) {
                            HStack {
                                Text(language)
                                Spacer()
                                if selectedLanguages.contains(language) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                // Save Preferences Button (Only Enables When a Language is Selected)
                Button(action: {
                    saveSelectedLanguages()
                }) {
                    Text("Save Preferences")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedLanguages.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding()
                }
                .disabled(selectedLanguages.isEmpty) // Disable button if no languages selected
                
                // Hidden NavigationLink that activates when navigateToNextScreen is true
                .fullScreenCover(isPresented: $navigateToNextScreen) {
                    UserHomeView()
                }

            }
            .navigationTitle("Language Preferences")
            .navigationBarBackButtonHidden(false)
        }
    }
    
    
   

    private func saveSelectedLanguages() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        userRef.updateData(["language": Array(selectedLanguages)]) { error in
            if let error = error {
                print("Error updating languages: \(error.localizedDescription)")
            } else {
                print("Genres updated successfully")
                navigateToNextScreen = true
            }
        }
    }

    
    private func toggleSelection(_ language: String) {
        if selectedLanguages.contains(language) {
            selectedLanguages.remove(language)
        } else {
            selectedLanguages.insert(language)
        }
    }
}
