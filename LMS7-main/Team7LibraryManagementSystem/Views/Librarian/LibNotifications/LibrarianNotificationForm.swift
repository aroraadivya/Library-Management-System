import SwiftUI
import Firebase

struct NotificationManagerView: View {
    @State private var users: [User] = []
    @State private var selectedUser: User?
    @State private var isSelectingAllUsers = false
    @State private var selectedNotificationType = "Due Date Reminder"
    @State private var message = ""

    let notificationTypes = ["Due Date Reminder", "Fine Notice", "Major Library Issue"]

    var body: some View {
        NavigationView {
            VStack {
                Text("New Notification")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                // Recipient Type Dropdown
                Menu {
                    // Option to select all users
                    Button(action: {
                        isSelectingAllUsers = true
                        selectedUser = nil
                    }) {
                        Text("📢 All Users")
                            .fontWeight(.bold)
                    }
                    
                    Divider() // Separator between options

                    // Individual user selection
                    ForEach(users, id: \.id) { user in
                        Button(action: {
                            selectedUser = user
                            isSelectingAllUsers = false
                        }) {
                            Text("\(user.firstName) \(user.lastName) - \(user.email)")
                        }
                    }
                } label: {
                    HStack {
                        if isSelectingAllUsers {
                            Text("📢 All Users")
                        } else {
                            Text(selectedUser != nil ? "\(selectedUser!.firstName) \(selectedUser!.lastName) - \(selectedUser!.email)" : "Select User")
                        }
                        Spacer()
                        Image(systemName: "chevron.down")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }

                // Notification Type Picker
                Picker("Notification Type", selection: $selectedNotificationType) {
                    ForEach(notificationTypes, id: \.self) { type in
                        Text(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                // Message Input
                TextEditor(text: $message)
                    .frame(height: 100)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 0.5))

                // Send Notification Button
                Button(action: sendNotification) {
                    Text("Send Notification")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                .disabled(message.isEmpty)

                Spacer()
            }
            .navigationTitle("Notifications Manager")
            .onAppear(perform: fetchUsers)
        }
    }

    // Fetch Users from Firebase
    func fetchUsers() {
        let db = Firestore.firestore()
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching users: \(error.localizedDescription)")
                return
            }
            if let documents = snapshot?.documents {
                self.users = documents.compactMap { doc in
                    let data = doc.data()
                    return User(
                        id: doc.documentID,
                        firstName: data["firstName"] as? String ?? "Unknown",
                        lastName: data["lastName"] as? String ?? "",
                        email: data["email"] as? String ?? "No Email"
                    )
                }
            }
        }
    }

    // Send Notification Function
    func sendNotification() {
        let db = Firestore.firestore()

        if isSelectingAllUsers {
            // Send notification to all users
            for user in users {
                let notificationData: [String: Any] = [
                    "recipientId": user.id,
                    "recipientName": "\(user.firstName) \(user.lastName)",
                    "notificationType": selectedNotificationType,
                    "message": message,
                    "timestamp": Timestamp()
                ]

                db.collection("notifications").addDocument(data: notificationData) { error in
                    if let error = error {
                        print("Error sending notification: \(error.localizedDescription)")
                    } else {
                        print("Notification sent to \(user.firstName) successfully")
                    }
                }
            }
        } else if let selectedUser = selectedUser {
            // Send notification to selected user
            let notificationData: [String: Any] = [
                "recipientId": selectedUser.id,
                "recipientName": "\(selectedUser.firstName) \(selectedUser.lastName)",
                "notificationType": selectedNotificationType,
                "message": message,
                "timestamp": Timestamp()
            ]

            db.collection("notifications").addDocument(data: notificationData) { error in
                if let error = error {
                    print("Error sending notification: \(error.localizedDescription)")
                } else {
                    print("Notification sent to \(selectedUser.firstName) successfully")
                }
            }
        }
    }
}

// User Model
struct User: Identifiable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
}

#Preview {
    NotificationManagerView()
}
