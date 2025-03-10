////
////  inFirebaseAuthView.swift
////  Team7test
////
////  Created by Hardik Bhardwaj on 13/02/25.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FirebaseAuthView: View {
    let userRole: String
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var isAuthenticating = false
    @State private var navigateTo2FA = false
    @State private var showForgotPassword = false
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var showNetworkAlert = false
    @State private var isPasswordVisible = false

    
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "book.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text("Sign In as \(userRole.capitalized)")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Authentication Required")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            TextField("Email", text: $email)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
            
            ZStack(alignment: .trailing) {
                if isPasswordVisible {
                    // Show regular TextField when password is visible
                    TextField("Password", text: $password)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                } else {
                    // Show SecureField when password is hidden
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                
                // Eye button
                Button(action: {
                    isPasswordVisible.toggle()
                }) {
                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 20)
            }
            .padding(.horizontal)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding(.horizontal)
            }
            
            Button(action: loginUser) {
                if isAuthenticating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .disabled(isAuthenticating || !networkMonitor.isConnected)
            .padding(.horizontal)
            
            Button("Forgot Password?") {
                showForgotPassword = true
            }
            .font(.footnote)
            .foregroundColor(.blue)
            
            if userRole == "user" {
                NavigationLink(destination: SignupAuthentication()) {
                    Text("Create Account")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding()
        .fullScreenCover(isPresented: $navigateTo2FA) {
            TwoFactorAuthenticationView(role: userRole, email: email)
        }
        .alert("Reset Password", isPresented: $showForgotPassword) {
            TextField("Enter your email", text: $email)
            Button("Cancel", role: .cancel) { }
            Button("Reset") {
//                resetPassword()
            }
        } message: {
            Text("Enter your email to receive password reset instructions")
        }
        .alert("Network Error", isPresented: $showNetworkAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please check your internet connection and try again.")
        }
        .onChange(of: networkMonitor.isConnected) { isConnected in
            if !isConnected {
                showNetworkAlert = true
            }
        }
    }
    
    private func loginUser() {
        guard networkMonitor.isConnected else {
            showNetworkAlert = true
            return
        }
        
        
        
        isAuthenticating = true
        errorMessage = nil
        let lowercaseEmail = email.lowercased()
        
        FirebaseAuthManager.shared.signIn(email: lowercaseEmail, password: password) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let role):
                    let lowercasedRole = role.lowercased()
                    let selectedRole = userRole.lowercased()
                    
                    
                    FirebaseAuthManager.shared.verifyUserRole(email: lowercaseEmail, role: selectedRole) { isValid, message in
                        if isValid {
                            FirebaseAuthManager.shared.fetchUserId(email: lowercaseEmail,role:selectedRole) { userId in
                                if let userId = userId {
                                    UserDefaults.standard.set(userId, forKey: "userId")
                                    print("User id in user default when signin \(userId)")
                                    
                                    FirebaseManager.shared.generateAndSendOTP(email: lowercaseEmail) { success, otpMessage in
                                        if success {
                                            UserDefaults.standard.set(role, forKey: "userRole")
                                            navigateTo2FA = true
                                        } else {
                                            errorMessage = otpMessage
                                        }
                                        isAuthenticating = false
                                    }
                                } else {
                                    isAuthenticating = false
                                    errorMessage = "Failed to fetch user ID"
                                }
                            }
                        } else {
                            isAuthenticating = false
                            errorMessage = message
                        }
                    }
                    
                case .failure(let error):
                    isAuthenticating = false
                    if (error as NSError).code == -1009 {
                        showNetworkAlert = true
                    } else {
                        errorMessage = "Invalid Credentials"
                    }
                }
            }
        }
    }
    
//    private func fetchUserId(email: String, role: String, completion: @escaping (String?) -> Void) {
//        let db = Firestore.firestore()
//
//        // Determine the collection name based on the role
//        let collectionName: String
//        switch role.lowercased() {
//        case "admin":
//            collectionName = "admins"
//        case "librarian":
//            collectionName = "librarians"
//        case "user":
//            collectionName = "users"
//        default:
//            print("❌ Invalid role: \(role)")
//            completion(nil)
//            return
//        }
//
//        print("Querying Firestore for email: \(email) in collection: \(collectionName)")
//
//        // Query the appropriate collection
//        db.collection(collectionName)
//            .whereField("email", isEqualTo: email)
//            .getDocuments { snapshot, error in
//                if let error = error {
//                    print("❌ Error fetching user ID: \(error.localizedDescription)")
//                    completion(nil)
//                    return
//                }
//
//                guard let document = snapshot?.documents.first else {
//                    print("❌ No document found for email: \(email) in collection: \(collectionName)")
//                    completion(nil)
//                    return
//                }
//
//                // Fetch the userId field
//                let userId = document.data()["userId"] as? String
//                if userId == nil {
//                    print("❌ userId field is missing in the document")
//                } else {
//                    print("✅ Fetched userId: \(userId!) from collection: \(collectionName)")
//                }
//                completion(userId)
//            }
//    }
//
//    private func verifyUserRole(email: String, role: String, completion: @escaping (Bool, String) -> Void) {
//        let collectionName: String
//
//        switch role.lowercased() {
//        case "admin":
//            collectionName = "admins"
//        case "librarian":
//            collectionName = "librarians"
//        case "user":
//            collectionName = "users"
//        default:
//            completion(false, "Invalid role selection")
//            return
//        }
//
//        let db = Firestore.firestore()
//        db.collection(collectionName).whereField("email", isEqualTo: email).getDocuments { snapshot, error in
//            if let error = error {
//                completion(false, "Error checking role: \(error.localizedDescription)")
//            } else if let snapshot = snapshot, !snapshot.documents.isEmpty {
//                completion(true, "")
//            } else {
//                completion(false, "Access denied: Email does not belong to the selected role")
//            }
//        }
//    }
    
    @MainActor
    //    private func resetPassword() {
    //        FirebaseAuthManager.shared.resetPassword(email: email) { result in
    //            DispatchQueue.main.async {
    //                switch result {
    //                case .success:
    //                    self.errorMessage = "Password reset email sent"
    //                case .failure(let error):
    //                    self.errorMessage = error.localizedDescription
    //                }
    //            }
    //        }
    //    }
    //}
    
    struct FirebaseAuthView_Previews: PreviewProvider {
        static var previews: some View {
            FirebaseAuthView(userRole: "admin")
        }
    }
}
