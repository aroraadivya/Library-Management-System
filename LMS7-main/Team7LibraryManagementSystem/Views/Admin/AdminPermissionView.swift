//
//  AdminPermissionView.swift
//  LibraryManagement
//
//  Created by Taksh Joshi on 16/02/25.
//
import SwiftUI
import FirebaseFirestore

struct AdminPermissionView: View {
    var admin: Admin
    @State private var isActive: Bool
    @State private var permissions: [String: Bool] = [:]
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss

    let db = Firestore.firestore()

    init(admin: Admin) {
        self.admin = admin
        _isActive = State(initialValue: admin.status == .active)
        _permissions = State(initialValue: [
            "View Users": false,
            "Edit Users": false,
            "Delete Users": false,
            "Create Content": false,
            "Edit Content": false,
            "Publish Content": false,
            "View Settings": false,
            "Modify Settings": false
        ])
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Admin Profile Card
                VStack {
                    HStack(spacing: 15) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.blue)
                            .background(Circle().stroke(Color.blue, lineWidth: 2))

                        VStack(alignment: .leading, spacing: 5) {
                            Text(admin.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text(admin.email)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        Spacer()
                    }
                    .padding()
                }
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Status Toggle Card
                VStack(alignment: .leading, spacing: 10) {
                    Text("Account Status")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text(isActive ? "Active" : "Suspended")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Toggle to change admin account status")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $isActive)
                            .labelsHidden()
                            .onChange(of: isActive) { newValue in
                                updateAdminStatus(isActive: newValue)
                            }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                }
                
                // Permission Sections
                PermissionSection(title: "User Management", permissions: [
                    "View Users": "Can view user profiles and information",
                    "Edit Users": "Can modify user details and settings",
                    "Delete Users": "Can remove users from the system"
                ], permissionStates: $permissions)

                PermissionSection(title: "Content Management", permissions: [
                    "Create Content": "Can create new content items",
                    "Edit Content": "Can modify existing content",
                    "Publish Content": "Can publish content live"
                ], permissionStates: $permissions)

                PermissionSection(title: "System Settings", permissions: [
                    "View Settings": "Can view system configurations",
                    "Modify Settings": "Can change system settings"
                ], permissionStates: $permissions)
                
                // Save Button
                Button(action: savePermissions) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Save Changes")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isLoading ? Color.blue.opacity(0.7) : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(isLoading)
                
                // Danger Zone
                VStack(alignment: .leading, spacing: 15) {
                    Text("Danger Zone")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding(.leading)
                    
                    Button(action: {
                        // Suspend admin functionality
                        isActive = false
                        updateAdminStatus(isActive: false)
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.xmark")
                                .foregroundColor(.red)
                            Text("Suspend Admin Account")
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .foregroundColor(.red)
                    
                    Button(action: {
                        // Delete admin functionality
                        print("Delete Admin")
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Delete Admin Account")
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .foregroundColor(.red)
                    
                    Text("These actions cannot be undone. Please be certain.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading)
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Admin Permissions")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            trailing: Button("Done") {
                savePermissions()
                dismiss()
            }
        )
        .onAppear {
            fetchPermissions()
        }
    }

    // Fetch current permissions from Firestore
    private func fetchPermissions() {
        db.collection("admins").document(admin.id).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                DispatchQueue.main.async {
                    let fetchedPermissions = data["permissions"] as? [String] ?? []
                    self.permissions = self.permissions.reduce(into: [:]) { result, pair in
                        result[pair.key] = fetchedPermissions.contains(pair.key)
                    }
                }
            }
        }
    }

    // Save updated permissions to Firestore
    private func savePermissions() {
        isLoading = true
        let selectedPermissions = permissions.filter { $0.value }.map { $0.key }

        db.collection("admins").document(admin.id).updateData([
            "permissions": selectedPermissions
        ]) { error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    print("Error updating permissions: \(error.localizedDescription)")
                }
            }
        }
    }

    // Update admin status (active/suspended) in Firestore
    private func updateAdminStatus(isActive: Bool) {
        let newStatus = isActive ? "active" : "suspended"
        db.collection("admins").document(admin.id).updateData([
            "status": newStatus
        ]) { error in
            if let error = error {
                print("Error updating status: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Permission Section Component
struct PermissionSection: View {
    var title: String
    var permissions: [String: String]
    @Binding var permissionStates: [String: Bool]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 10) {
                ForEach(permissions.keys.sorted(), id: \.self) { key in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(key)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(permissions[key]!)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { self.permissionStates[key] ?? false },
                            set: { self.permissionStates[key] = $0 }
                        ))
                        .labelsHidden()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
            .padding(.vertical)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
}
