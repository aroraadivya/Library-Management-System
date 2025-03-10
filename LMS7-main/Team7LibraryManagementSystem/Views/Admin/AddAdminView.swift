//
//  AddAdminView.swift
//  LibraryManagement
//
//  Created by Taksh Joshi on 16/02/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AddAdminView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedRole = "Super Admin"
    @State private var selectedDepartment = "Select Library"
    @State private var startDate = Date()
    @State private var additionalNotes = ""
    
    @State private var userManagement = true
    @State private var contentManagement = true
    @State private var systemSettings = true
    @State private var financialAccess = true
    @State private var analyticsView = true
    
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var isLoading = false
    @State private var errorMessage = ""

    let departments = ["Select Library", "Central Library", "City Library", "Community Library"]
    let roles = ["Admin", "Super Admin"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Profile Picture
                    VStack {
                        Button(action: {
                            // Handle Image Picker (Placeholder)
                        }) {
                            VStack {
                                Image(systemName: "camera.fill")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.gray)
                                    .padding()
                                    .background(Circle().fill(Color(.systemGray6)))
                                
                                Text("Add Photo")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.top, 10)
                    
                    // Basic Information
                    SectionView(title: "Basic Information")
                    TextFieldView(icon: "person.fill", placeholder: "Full Name", text: $fullName)
                    TextFieldView(icon: "envelope.fill", placeholder: "Email Address", text: $email)
                    TextFieldView(icon: "phone.fill", placeholder: "Phone Number", text: $phone)

                    // Role & Permissions
                    SectionView(title: "Role & Permissions")
                    DropdownView(title: selectedRole, options: roles) { selectedRole = $0 }
                    
                    ToggleView(title: "User Management", description: "Manage user accounts and permissions", isOn: $userManagement)
                    ToggleView(title: "Content Management", description: "Manage and publish content", isOn: $contentManagement)
                    ToggleView(title: "System Settings", description: "Configure system preferences", isOn: $systemSettings)
                    ToggleView(title: "Financial Access", description: "Handle financial transactions", isOn: $financialAccess)
                    ToggleView(title: "Analytics View", description: "Access analytics and reports", isOn: $analyticsView)

                    // Security Settings
                    SectionView(title: "Security Settings")
                    SecureFieldView(placeholder: "Password", text: $password)
                    SecureFieldView(placeholder: "Confirm Password", text: $confirmPassword)

                    // Additional Settings
                    SectionView(title: "Additional Settings")
                    DropdownView(title: selectedDepartment, options: departments) { selectedDepartment = $0 }
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    
                    TextField("Additional Notes", text: $additionalNotes)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    
                    // Create Button
                    

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
            }
            .navigationTitle("Add New Administrator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: registerAdmin) {
                        if isLoading {
                            ProgressView()
                                .tint(.blue)
                        } else {
                            Text("Save")
                                .bold()
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(isLoading)
                }
            }
        }
    }

    // MARK: - Firebase Registration
    private func registerAdmin() {
        guard !fullName.isEmpty, !email.isEmpty, !password.isEmpty, password == confirmPassword else {
            errorMessage = "Please check your inputs."
            return
        }

        isLoading = true
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                isLoading = false
                return
            }

            guard let userID = result?.user.uid else {
                errorMessage = "Failed to get user ID."
                isLoading = false
                return
            }

            let db = Firestore.firestore()
            let adminData: [String: Any] = [
                "userId": userID, // Add the userId field
                "fullName": fullName,
                "email": email,
                "phone": phone,
                "role": selectedRole,
                "library": selectedDepartment,
                "permissions": [
                    "User Management": userManagement,
                    "Content Management": contentManagement,
                    "System Settings": systemSettings,
                    "Financial Access": financialAccess,
                    "Analytics View": analyticsView
                ],
                "startDate": startDate,
                "additionalNotes": additionalNotes,
                "status": "active",
                "createdAt": Timestamp()
            ]

            db.collection("admins").document(userID).setData(adminData) { error in
                if let error = error {
                    errorMessage = "Error saving admin: \(error.localizedDescription)"
                    isLoading = false
                } else {
                    sendEmail(to: email, name: fullName, password: password)
                }
            }
        }
    }

    // MARK: - Email Notification
    private func sendEmail(to email: String, name: String, password: String) {
        let db = Firestore.firestore()
        let emailData: [String: Any] = [
            "to": email,
            "message": [
                "subject": "Your Admin Account for Library Management System",
                "text": """
                Hi \(name),

                Your admin account has been created successfully!

                📌 Library: \(selectedDepartment)  
                🛠 Role: \(selectedRole)  
                🔑 Email: \(email)  
                🔒 Password: \(password)

                Click below to access the system:  
                [Open App](yourapp://mainpage)

                Regards,  
                Library Management Team
                """
            ]
        ]

        db.collection("mail").addDocument(data: emailData) { error in
            if error == nil { presentationMode.wrappedValue.dismiss() }
            isLoading = false
        }
    }
}
