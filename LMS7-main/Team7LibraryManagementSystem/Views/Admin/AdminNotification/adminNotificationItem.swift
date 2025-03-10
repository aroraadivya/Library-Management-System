
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

// MARK: - Notification Model
struct NotificationItem: Identifiable {
    let id: String
    let senderName: String
    let message: String
    let category: String
    let timestamp: Date
    let isRead: Bool
}

// MARK: - Notifications View
struct NotificationsView: View {
    @State private var notifications: [NotificationItem] = []
    @State private var searchText: String = ""
    @State private var isLoading: Bool = true
    @State private var userID: String?

    var filteredNotifications: [NotificationItem] {
        if searchText.isEmpty {
            return notifications
        } else {
            return notifications.filter { $0.message.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Search Bar
                TextField("Search notifications", text: $searchText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)

                if isLoading {
                    ProgressView("Loading notifications...")
                        .padding()
                } else {
                    List(filteredNotifications) { notification in
                        NotificationRow(notification: notification)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Notifications")
            .navigationBarItems(trailing:
                NavigationLink(destination: NotificationView()) {
                    Image(systemName: "plus")
                }
            )
            .onAppear {
                fetchUserID()
            }
        }
    }

    // MARK: - Fetch Current User ID
    func fetchUserID() {
        if let currentUser = Auth.auth().currentUser {
            self.userID = currentUser.uid
            fetchNotifications(for: currentUser.uid)
        } else {
            print("⚠️ User not logged in!")
        }
    }

    // MARK: - Fetch Notifications from Firestore
    func fetchNotifications(for userID: String) {
        let db = Firestore.firestore()

        print("📌 Fetching notifications for userID: \(userID)")

        db.collection("notifications")
            .whereField("recipients", arrayContains: userID)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Error fetching notifications: \(error.localizedDescription)")
                    isLoading = false
                    return
                }

                if let documents = snapshot?.documents {
                    notifications = documents.compactMap { doc in
                        let data = doc.data()
                        return NotificationItem(
                            id: doc.documentID,
                            senderName: data["recipient"] as? String ?? "Unknown",
                            message: data["message"] as? String ?? "",
                            category: data["subject"] as? String ?? "General",
                            timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                            isRead: data["isRead"] as? Bool ?? false
                        )
                    }
                    isLoading = false
                    print("✅ Fetched \(notifications.count) notifications")
                }
            }
    }
}

// MARK: - Notification Form View
struct NotificationForm: View {
    var body: some View {
        VStack {
            Text("Create New Notification")
                .font(.title)
                .padding()
        }
        .navigationTitle("New Notification")
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: NotificationItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .clipShape(Circle())

            VStack(alignment: .leading) {
                HStack {
                    Text(notification.senderName)
                        .font(.headline)

                    Spacer()

                    Text(timeAgo(from: notification.timestamp))
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    if !notification.isRead {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                    }
                }

                Text(notification.message)
                    .font(.body)
                    .foregroundColor(.primary)

                Text(notification.category)
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
    }

    func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview
struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
}
