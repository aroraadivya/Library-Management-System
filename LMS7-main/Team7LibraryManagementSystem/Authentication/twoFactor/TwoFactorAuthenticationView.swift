import SwiftUI

struct TwoFactorAuthenticationView: View {
    var role : String
    let email: String
    @State private var errorMessage: String?
    @State private var isAuthenticating = false
    @State private var navigateToNextScreen = false
    @State private var verificationCode: [String] = Array(repeating: "", count: 6)
    @State private var timeRemaining: Int = 179 // 2:59 in seconds
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @FocusState private var focusedIndex: Int? // Focus state for text fields

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "checkmark.shield.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40)
                            .foregroundColor(.blue)
                    )

                VStack(spacing: 8) {
                    Text("Two-Factor Authentication")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Please verify your identity")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                HStack {
                    Text("\(email)")
                        .foregroundColor(.black)

                    Button("") {
                        // Handle email change
                    }
                    .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("Enter verification code")
                        .font(.subheadline)

                    HStack(spacing: 12) {
                        ForEach(0..<6, id: \.self) { index in
                            TextField("", text: $verificationCode[index])
                                .frame(width: 45, height: 45)
                                .multilineTextAlignment(.center)
                                .keyboardType(.numberPad)
                                .focused($focusedIndex, equals: index) // Manage focus per field
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .onChange(of: verificationCode[index]) { newValue in
                                    if newValue.count > 1 {
                                        verificationCode[index] = String(newValue.last!)
                                    }
                                    if !newValue.isEmpty && index < 5 {
                                        focusedIndex = index + 1 // Move focus to next field
                                    } else if newValue.isEmpty && index > 0 {
                                        focusedIndex = index - 1 // Move focus to previous field
                                    }
                                }
                        }
                    }
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.top, 8)
                }

                HStack {
                    Text("Code expires in: \(timeString(from: timeRemaining))")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Spacer()

                    Button("Resend Code") {
                        FirebaseManager.shared.generateAndSendOTP(email: email) { success, message in
                            DispatchQueue.main.async {
                                if success {
                                    print("OTP Sent Successfully: \(message)")
                                } else {
                                    print("Failed to Send OTP: \(message)")
                                }
                            }
                        }
                        timeRemaining = 179 // Reset the timer
                        errorMessage = nil // Clear any error messages when resent
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.top, 8)

                Button(action: {
                    let code = verificationCode.joined()
                    guard !code.isEmpty else { return } // Prevent empty input
                    isAuthenticating = true // Disable button while verifying

                    print("ENTERED CODE::::\(code)")
                    FirebaseManager.shared.verifyOTP(email: email, enteredOTP: code) { success, message in
                        DispatchQueue.main.async {
                            isAuthenticating = false
                            if success {
                                print("OTP VERIFIED")
                                navigateToNextScreen = true
                               //UserDefaults.standard.set(userId, forKey: "userId")
//                                FirebaseAuthManager.shared.fetchUserId(email: email,role:role) { userId in
//                                    if let userId = userId {
//                                        UserDefaults.standard.set(userId, forKey: "userId")
//                                        print("User id in user default when signin \(userId)")
//                                    }}
                            } else {
                                print("OTP NOT VERIFIED")
                                verificationCode = Array(repeating: "", count: 6)
                                focusedIndex = 0 // Reset focus to the first field
                                errorMessage = "Invalid OTP or it has expired. Please try again." // Show error message
                            }
                        }
                    }
                }) {
                    Text(isAuthenticating ? "Verifying..." : "Continue")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isAuthenticating ? Color.gray : Color.blue.opacity(0.8))
                        .cornerRadius(12)
                }
                .disabled(isAuthenticating || verificationCode.contains("")) // Prevent multiple taps
                .padding(.top, 24)

                Spacer()
            }
            .padding()
            .onReceive(timer) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else if timeRemaining == 0 {
                    errorMessage = "OTP expired. Please request a new code."
                }
            }
            .fullScreenCover(isPresented: $navigateToNextScreen) {
               
                if(role == "Admin"){
                    MainTabView()
                        .navigationBarBackButtonHidden(true)
                }else if (role == "Librarian"){
                    LibrarianTabView()
                        .navigationBarBackButtonHidden(true)
                }
                else if(role == "user"){
                    UserHomeView()
                        .navigationBarBackButtonHidden(true)
                }
                else if(role == "signUpUser"){
                    GenreSelectionView()
                        .navigationBarBackButtonHidden(true)
                }
                // Prevent going back
            }
            .onAppear {
                focusedIndex = 0 // Start with focus on first field
            }
        }
    }

    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

struct TwoFactorAuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        TwoFactorAuthenticationView(role: "admin", email: "example@mail.com")
    }
}
