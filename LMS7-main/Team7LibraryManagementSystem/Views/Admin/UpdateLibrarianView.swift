import SwiftUI
import FirebaseFirestore

struct UpdateLibrarianView: View {
    @Environment(\.dismiss) var dismiss
    let librarian: Librarian
    
    @State private var fullName: String
    @State private var email: String
    @State private var phone: String
    @State private var isSuspended: Bool
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAlert = false
    
    init(librarian: Librarian) {
        self.librarian = librarian
        _fullName = State(initialValue: librarian.fullName)
        _email = State(initialValue: librarian.email)
        _phone = State(initialValue: librarian.phone)
        _isSuspended = State(initialValue: librarian.isSuspended)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                SectionView(title: "Librarian Details")
                
                TextFieldView(
                    icon: "person",
                    placeholder: "Full Name",
                    text: $fullName
                )
                
                TextFieldView(
                    icon: "envelope",
                    placeholder: "Email",
                    text: $email
                )
                
                TextFieldView(
                    icon: "phone",
                    placeholder: "Phone Number",
                    text: $phone
                )
                
                ToggleView(
                    title: "Account Status",
                    description: "Toggle to suspend or activate librarian account",
                    isOn: $isSuspended
                )
                
                Spacer()
                
                Button(action: updateLibrarian) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Update Librarian")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    (fullName.isEmpty || email.isEmpty || phone.isEmpty)
                    ? Color.gray
                    : Color.blue
                )
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(fullName.isEmpty || email.isEmpty || phone.isEmpty)
            }
            .navigationTitle("Update Librarian")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "Unknown error"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private func updateLibrarian() {
        isLoading = true
        let db = Firestore.firestore()
        let updatedData: [String: Any] = [
            "fullName": fullName,
            "email": email,
            "phone": phone,
            "isSuspended": isSuspended
        ]

        db.collection("librarians").document(librarian.id).updateData(updatedData) { error in
            isLoading = false
            if let error = error {
                errorMessage = "Error updating librarian: \(error.localizedDescription)"
                showAlert = true
            } else {
                dismiss()
            }
        }
    }
}
