//
//  AdminProfile.swift
//  Team7LibraryManagementSystem
//
//  Created by Taksh Joshi on 24/02/25.
//


import SwiftUI

struct AdminProfile: View {
    @Environment(\.dismiss) var dismiss

    // State variables
    @State private var isEditing = false
    @State private var fullName: String = "John Doe"
    @State private var email: String = "admin@example.com"
    @State private var phone: String = "+1 (555) 123-4567"
    @State private var dob: String = "January 15, 1990"
    @State private var location: String = "New York, USA"

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Profile Image Section
                Section {
                    VStack(spacing: 8) {
                        ZStack {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)

                            Image(systemName: "camera.fill")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .background(Color.white.clipShape(Circle()))
                                .offset(x: 30, y: 30)
                        }

                        Text("Admin User")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .listRowBackground(Color.clear)
                }

                // MARK: - Personal Information (Editable)
                Section(header: Text("Personal Information")) {
                    EditableRow(title: "Full Name", text: $fullName, isEditing: isEditing)
                    EditableRow(title: "Email Address", text: $email, isEditing: isEditing)
                    EditableRow(title: "Phone Number", text: $phone, isEditing: isEditing)
                    EditableRow(title: "Date of Birth", text: $dob, isEditing: isEditing)
                    EditableRow(title: "Location", text: $location, isEditing: isEditing)
                }

                // MARK: - Account Settings (Non-Editable)
                Section(header: Text("Account Settings")) {
                    NavigationLink(destination: Text("Account Type")) {
                        InfoRow(title: "Account Type", value: "Administrator")
                    }
                    NavigationLink(destination: Text("Last Login")) {
                        InfoRow(title: "Last Login", value: "Today, 2:30 PM")
                    }
                    NavigationLink(destination: Text("Two-Factor Authentication")) {
                        InfoRow(title: "Two-Factor Authentication", value: "Enabled")
                    }
                    NavigationLink(destination: Text("Language")) {
                        InfoRow(title: "Language", value: "English (US)")
                    }
                }

                // MARK: - Security (Non-Editable)
                Section(header: Text("Security")) {
                    NavigationLink(destination: Text("Change Password")) {
                        InfoRow(title: "Change Password", value: "Last changed 3 months ago")
                    }
                    NavigationLink(destination: Text("Login History")) {
                        InfoRow(title: "Login History", value: "View your recent login activities")
                    }
                    NavigationLink(destination: Text("Active Sessions")) {
                        InfoRow(title: "Active Sessions", value: "Manage your active sessions")
                    }
                }

                // MARK: - Sign Out Button
                Section {
                    Button(action: {
                        signOut()
                    }) {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.red)
                            .fontWeight(.bold)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .topBarLeading) {
//                    if isEditing {
//                        Button("Cancel") {
//                            isEditing = false
//                        }
//                    }
//                }
//                ToolbarItem(placement: .topBarTrailing) {
//                    Button(isEditing ? "Done" : "Edit") {
//                        if isEditing {
//                            saveProfile()
//                        }
//                        isEditing.toggle()
//                    }
//                    .bold()
//                }
//            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isEditing {
                        Button("Cancel") {
                            isEditing = false
                        }
                    } else {
//                        Button(action: {
//                            dismiss() // This dismisses the view when not in edit mode
//                        })
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing {
                            saveProfile()
                        }
                        isEditing.toggle()
                    }
                    .bold()
                }
            }
            .navigationBarBackButtonHidden(isEditing) // Hide back button when editing

        }
    }

    // Save action function
    func saveProfile() {
        print("Profile saved: \(fullName), \(email), \(phone), \(dob), \(location)")
    }

    // Sign Out function
    func signOut() {
        print("User signed out")
        // Add actual sign-out logic here
    }
}

// MARK: - Editable Row for Text Input
struct EditableRow: View {
    let title: String
    @Binding var text: String
    var isEditing: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Spacer()
            if isEditing {
                TextField(title, text: $text)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.black)
            } else {
                Text(text)
                    .foregroundColor(.black)
            }
        }
    }
}

// MARK: - Non-Editable Info Row
struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(.black)
        }
    }
}

// Preview
#Preview {
    NavigationStack {
        AdminProfile()
    }
}
