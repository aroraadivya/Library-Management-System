////
////  IssueBookView.swift
////  Team7LibraryManagementSystem
////
////  Created by Rakshit  on 24/02/25.
////
//
//import Foundation
//import SwiftUI
//import FirebaseFirestore
//
//struct IssuedBooksView: View {
//    @Environment(\.dismiss) var dismiss
//    @State private var showAddIssueBook = false
//
//    
//    var body: some View {
//        NavigationView {
//            VStack(spacing: 0) {
//                ScrollView {
//                    VStack(spacing: 24) {
//                        // User Profile Section
//                        UserProfileSection(profile: userProfile)
//                        
//                        // Books List
//                        IssuedBooksList(books: issuedBooks)
//                    }
//                    .padding()
//                }
//            }
//            .navigationBarTitleDisplayMode(.inline)
//            .navigationTitle("My Books")
////            .toolbar {
////
////                ToolbarItem(placement: .navigationBarTrailing) {
////                    Button(action: { showAddIssueBook = true }) {
////                        Image(systemName: "plus")
////                            .foregroundColor(.blue)
////                    }
////                }
////            }
//        }
//        .sheet(isPresented: $showAddIssueBook) {
//            AddIssueBookView()
//        }
//    }
//}
//
//
//
//
////  
////  private func fetchIssuedBooks() {
////      let db = Firestore.firestore()
////      guard let userEmail = Auth.auth().currentUser?.email else {
////          print("No logged-in user found")
////          return
////      }
////      
////      db.collection("users").document(userEmail).collection("issuebook").getDocuments { snapshot, error in
////          if let error = error {
////              print("Error fetching issued books: ", error)
////              return
////          }
////          guard let documents = snapshot?.documents else { return }
////          
////          issuedBooks = documents.compactMap { doc in
////              let data = doc.data()
////              return IssuedBook(
////                  id: doc.documentID,
////                  title: data["title"] as? String ?? "Unknown Title",
////                  author: data["author"] as? String ?? "Unknown Author",
////                  coverImage: data["coverImage"] as? String ?? "default_cover",
////                  dueDate: data["dueDate"] as? String ?? "Unknown Date",
////                  daysLeft: data["daysLeft"] as? Int ?? 0,
////                  isOverdue: data["isOverdue"] as? Bool ?? false
////              )
////          }
////      }
////  }
//
//
//struct UserProfileSection: View {
//    let profile: UserProfile
//    
//    var body: some View {
//        VStack(spacing: 16) {
//            // Profile Info
//            HStack(spacing: 12) {
////                Image(profile.profileImage)
////                    .resizable()
////                    .frame(width: 48, height: 48)
////                    .clipShape(Circle())
//                
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(profile.name)
//                        .font(.headline)
//                    
//                    Text(profile.libraryId)
//                        .font(.caption)
//                        .foregroundColor(.gray)
//                }
//                
//                Spacer()
//            }
//            
//            // Stats
//            HStack(spacing: 24) {
//                StatItem(value: "\(profile.totalBooks)", label: "Total Books")
//                StatItem(value: "\(profile.dueSoonBooks)", label: "Due Soon", icon: "exclamationmark.triangle.fill", iconColor: .yellow)
//            }
//        }
//        .padding()
//        .background(Color.gray.opacity(0.1))
//        .cornerRadius(12)
//    }
//}
//
//struct StatItem: View {
//    let value: String
//    let label: String
//    var icon: String? = nil
//    var iconColor: Color = .blue
//    
//    var body: some View {
//        HStack(spacing: 8) {
//            Text(value)
//                .font(.title2)
//                .fontWeight(.bold)
//            
//            if let icon = icon {
//                Image(systemName: icon)
//                    .foregroundColor(iconColor)
//            }
//        }
//        VStack {
//            Text(label)
//                .font(.caption)
//                .foregroundColor(.gray)
//        }
//    }
//}
//
//struct IssuedBooksList: View {
//    let books: [IssuedBook]
//    
//    var body: some View {
//        VStack(spacing: 16) {
//            ForEach(books) { book in
//                IssuedBookRow(book: book)
//            }
//        }
//    }
//}
//
//struct IssuedBookRow: View {
//    let book: IssuedBook
//    @State private var showApplyFine = false
//    
//    var body: some View {
//        Button(action: { showApplyFine = true }) {
//            HStack(spacing: 16) {
//                // Book Cover
////                Image(book.coverImage)
////                    .resizable()
////                    .frame(width: 60, height: 80)
////                    .cornerRadius(8)
//                
//                // Book Details
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(book.title)
//                        .font(.system(size: 16, weight: .medium))
//                    
//                    Text(book.author)
//                        .font(.caption)
//                        .foregroundColor(.gray)
//                    
//                    HStack {
//                        Image(systemName: "calendar")
//                            .foregroundColor(.gray)
//                        Text("Due: \(book.dueDate)")
//                            .font(.caption)
//                            .foregroundColor(.gray)
//                    }
//                    
//                    Text(book.isOverdue ? "Overdue" : "\(book.daysLeft) days left")
//                        .font(.caption)
//                        .foregroundColor(book.isOverdue ? .red : .gray)
//                }
//                
//                Spacer()
//                
//                // Return Button
//                Button(action: {}) {
//                    Text("Return")
//                        .font(.caption)
//                        .foregroundColor(.blue)
//                }
//            }
//            .padding()
//            .background(Color.white)
//            .cornerRadius(12)
//            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
//        }
////        .sheet(isPresented: $showApplyFine) {
////            ApplyFineView(book: book)
////        }
//    }
//}
//
