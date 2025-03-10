//
//  LibrarianNotificationsView.swift
//  Team7LibraryManagementSystem
//
//  Created by Hardik Bhardwaj on 27/02/25.
//


import SwiftUI
import Firebase

struct LibrarianNotificationsView: View {
    @State private var notifications: [NotificationModel] = []
    @State private var librarianIDs: Set<String> = []
    
    var body: some View {
        NavigationStack {
            List(notifications) { notification in
                VStack(alignment: .leading) {
                    Text(notification.notificationType)
                        .font(.headline)
                    Text(notification.message)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("Sent by: \(notification.createdBy)")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
                .padding()
            }
            .navigationTitle(" Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                fetchLibrarians()
            }
        }
    }
    
    func fetchLibrarians() {
        let db = Firestore.firestore()
        db.collection("librarians").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching librarians: \(error.localizedDescription)")
                return
            }
            
            let ids = snapshot?.documents.compactMap { $0.documentID } ?? []
            self.librarianIDs = Set(ids)
            print("✅ Fetched librarian IDs: \(self.librarianIDs)")
            
            fetchNotifications()
        }
    }
    
    func fetchNotifications() {
        let db = Firestore.firestore()
        db.collection("notifications").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching notifications: \(error.localizedDescription)")
                return
            }
            
            let allNotifications = snapshot?.documents.compactMap { doc -> NotificationModel? in
                let data = doc.data()
                let createdBy = data["createdBy"] as? String ?? ""
                
                // Only include notifications where createdBy exists in librarianIDs
                guard self.librarianIDs.contains(createdBy) else { return nil }
                
                return NotificationModel(
                    id: doc.documentID,
                    createdBy: createdBy,
                    recipientId: data["recipientId"] as? String ?? "",
                    recipientName: data["recipientName"] as? String ?? "",
                    notificationType: data["notificationType"] as? String ?? "",
                    message: data["message"] as? String ?? "",
                    timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                )
            } ?? []
            
            self.notifications = allNotifications
            print("✅ Loaded \(self.notifications.count) librarian notifications.")
        }
    }
}

struct NotificationModel: Identifiable {
    let id: String
    let createdBy: String
    let recipientId: String
    let recipientName: String
    let notificationType: String
    let message: String
    let timestamp: Date
}

#Preview {
    LibrarianNotificationsView()
}
