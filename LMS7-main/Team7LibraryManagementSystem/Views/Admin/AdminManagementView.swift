//
//  AdminManagementView.swift
//  LibraryManagement
//
//  Created by Taksh Joshi on 16/02/25.
//


import SwiftUI
import FirebaseFirestore

struct Admin: Identifiable {
    let id: String // This is the Firestore document ID
    var userId: String // This is the Firebase Authentication UID
    var name: String
    var email: String
    var status: AdminStatus
    var permissions: [String]
}

enum AdminStatus {
    case active, suspended
}
struct AdminManagementView: View {
    @State private var searchText: String = ""
    @State private var admins: [Admin] = []
    @State private var isLoading = true

    var filteredAdmins: [Admin] {
        searchText.isEmpty ? admins : admins.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.14)))
                .padding(.horizontal)

                if isLoading {
                    ProgressView()
                        .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(filteredAdmins) { admin in
                                AdminCardView(admin: admin)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Admin Management")
            .toolbar {
                NavigationLink(destination: AddAdminView()) {
                    Image(systemName: "plus")
                        .font(.title2)
                }
            }
            .onAppear {
                fetchAdmins()
            }
        }
    }

    private func fetchAdmins() {
        let db = Firestore.firestore()
        db.collection("admins").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching admins: \(error.localizedDescription)")
                self.isLoading = false
                return
            }
            
            guard let documents = snapshot?.documents else {
                self.isLoading = false
                return
            }

            DispatchQueue.main.async {
                self.admins = documents.compactMap { doc in
                    let data = doc.data()
                    return Admin(
                        id: doc.documentID,
                        userId: data["userId"] as? String ?? "",
                        name: data["fullName"] as? String ?? "Unknown",
                        email: data["email"] as? String ?? "No Email",
                        status: (data["status"] as? String == "active") ? .active : .suspended,
                        permissions: data["permissions"] as? [String] ?? []  // Fetch permissions array
                    )
                }
                self.isLoading = false
            }
        }
    }
}

struct AdminCardView: View {
    var admin: Admin

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading) {
                    Text(admin.name)
                        .font(.headline)
                    Text(admin.email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                NavigationLink(destination: AdminPermissionView(admin: admin)) {
                    Image(systemName: "person.badge.key.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
            }

            HStack {
                Text(admin.status == .active ? "Active" : "Suspended")
                    .foregroundColor(admin.status == .active ? .green : .red)
                    .bold()
                Spacer()
            }
            .padding(.horizontal, 44)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
    }
}

struct AdminManagementView_Previews: PreviewProvider {
    static var previews: some View {
        AdminManagementView()
    }
}
