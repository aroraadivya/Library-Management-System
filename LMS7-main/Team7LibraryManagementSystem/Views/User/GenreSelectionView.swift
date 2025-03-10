

//
//  GenreSelectionView.swift
//  LMS user
//
//  Created by Divya Arora on 13/02/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct GenreSelectionView: View {
    @State private var selectedGenres: Set<String> = []
    @State private var isLoading = false // To show a loading indicator while saving
    @State private var errorMessage: String?
    @State private var navigate2Language = false
    
    let genres = ["Fiction", "Mystery & Thriller", "Romance", "Science Fiction", "Fantasy", "Biography", "History", "Self-Help", "Business", "Science", "Poetry", "Comics & Manga", "Horror", "Travel", "Cooking", "Art & Design"]
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                
                Text("Select your favorite genres to get personalized recommendations")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal)
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(genres, id: \.self) { genre in
                            Button(action: {
                                toggleSelection(genre)
                            }) {
                                ZStack(alignment: .topTrailing) {
                                    VStack(spacing: 10) {
                                        Image(systemName: "book.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 40, height: 40)
                                            .foregroundColor(.blue)
                                        
                                        Text(genre)
                                            .font(.headline)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(.primary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    
                                    if selectedGenres.contains(genre) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .padding(5)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Button(action: saveGenresToFirestore) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding()
                    } else {
                        Text("Continue")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding()
                    }
                }
            }
            .fullScreenCover(isPresented: $navigate2Language) {
                LanguagePreferencesView()
            }
            .navigationTitle("Select Genres")
            .navigationBarBackButtonHidden(false)
        }
    }
    
    private func toggleSelection(_ genre: String) {
        if selectedGenres.contains(genre) {
            selectedGenres.remove(genre)
        } else {
            selectedGenres.insert(genre)
        }
    }
    
    private func saveGenresToFirestore() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in."
            return
        }
        
        isLoading = true
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        userRef.updateData(["genre": Array(selectedGenres)]) { error in
            isLoading = false
            if let error = error {
                errorMessage = "Failed to update genres: \(error.localizedDescription)"
            } else {
                errorMessage = nil
                navigate2Language = true
            }
        }
    }
}
