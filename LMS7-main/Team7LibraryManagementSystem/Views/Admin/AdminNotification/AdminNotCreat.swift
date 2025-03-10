////
////  Recipient.swift
////  Team7LibraryManagementSystem
////
////  Created by Hardik Bhardwaj on 25/02/25.
////


import SwiftUI
import Firebase
import FirebaseFirestore

// MARK: - Recipient Model
struct adminRecipient: Identifiable {
    let id: String
    let name: String
    let library : String
}

// MARK: - NotificationView (Admin Side)
struct adminNotificationView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var selectedRecipients: [Recipient] = []  // Selected librarians
    @State private var subject: String = ""
    @State private var message: String = ""
    @State private var isShowingRecipientSheet = false  // Controls recipient selection popup

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                
                // MARK: - Recipients Section
                Text("To:")
                    .font(.headline)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(selectedRecipients) { recipient in
                            SelectedRecipientView(recipient: recipient) {
                                selectedRecipients.removeAll { $0.id == recipient.id }
                            }
                        }

                        Button(action: { isShowingRecipientSheet = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Recipients")
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }

                Text("\(selectedRecipients.count) librarians selected")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                // MARK: - Subject Field
                TextField("Enter notification subject", text: $subject)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                // MARK: - Message Field
                TextEditor(text: $message)
                    .frame(height: 100)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                Spacer()
            }

            .padding(.horizontal, 16)
            .padding(.top,20)

            .navigationTitle("New Notification")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)

            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")  // Chevron-only back button
                        .foregroundColor(.blue)
                }
            }
                                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        storeNotification()
                    }
                    .disabled(subject.isEmpty || message.isEmpty || selectedRecipients.isEmpty)
                }
            }
            .sheet(isPresented: $isShowingRecipientSheet) {
                SelectRecipientsView(selectedRecipients: $selectedRecipients)
            }
        }
    }


    // MARK: - Store Notification in Firestore
    func storeNotification() {
        let db = Firestore.firestore()
        
        let recipientIDs = selectedRecipients.map { $0.id }
        let notificationData: [String: Any] = [
            "subject": subject,
            "message": message,
            "recipients": recipientIDs,
            "timestamp": Timestamp(date: Date())
        ]
        
        db.collection("notifications").addDocument(data: notificationData) { error in
            if let error = error {
                print("❌ Error storing notification: \(error.localizedDescription)")
            } else {
                print("✅ Notification saved in Firestore")
                // Clear fields after sending
                subject = ""
                message = ""
                selectedRecipients = []
            }
        }
    }
}

struct BackButton: View {
    var body: some View {
        HStack {
            Image(systemName: "chevron.left") // Only the chevron icon
                .font(.headline)
                .foregroundColor(.blue)
        }
        .contentShape(Rectangle()) // Ensures the button is tappable
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
// MARK: - Recipient Selection View (Fetch from Firestore)
struct adminSelectRecipientsView: View {
    @Binding var selectedRecipients: [Recipient]
    @State private var allLibrarians: [Recipient] = []

    var body: some View {
        NavigationView {
            List(allLibrarians) { librarian in
                HStack {
                    Text(librarian.name)
                    Spacer()
                    if selectedRecipients.contains(where: { $0.id == librarian.id }) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedRecipients.contains(where: { $0.id == librarian.id }) {
                        selectedRecipients.removeAll { $0.id == librarian.id }
                    } else {
                        selectedRecipients.append(librarian)
                    }
                }
            }
            .navigationTitle("Select Librarians")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Cancel") { selectedRecipients = []; }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("") { }
                }
            }
            .onAppear {
                fetchLibrarians()
            }
        }
    }

    // MARK: - Fetch Librarians from Firestore
    func fetchLibrarians() {
        let db = Firestore.firestore()
        db.collection("librarians").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching librarians: \(error.localizedDescription)")
                return
            }

            if let documents = snapshot?.documents {
                allLibrarians = documents.compactMap { doc in
                    let data = doc.data()
//                    return Recipient(id: doc.documentID, name: data["fullName"] as? String ?? "")
                    return Recipient(id: doc.documentID,  name: data["fullName"] as? String ?? "Unknown")
//                                     library: data["assignedLibrary"] as? String ?? "No Library")
               }
            }
        }
    }
}

// MARK: - Selected Recipient View
struct adminSelectedRecipientView: View {
    let recipient: Recipient
    var removeAction: () -> Void

    var body: some View {
        HStack {
            Text(recipient.name)
                .padding(8)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(10)

            Button(action: removeAction) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Preview
struct adminNotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationView()
    }
}
