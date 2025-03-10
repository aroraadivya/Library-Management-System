import SwiftUI
import FirebaseFirestore
import CodeScanner

struct AddIssueBookView: View {
    @State private var email: String = ""
    @State private var isbn13: String = ""
    @State private var dueDate: Date = Date()
    @State private var isShowingScanner = false
    @State private var isCalendarVisible = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var selectedUser: User?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // User Email Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email").font(.subheadline).foregroundColor(.gray)
                        TextField("Enter email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                    }

                    // User Details if found
                    if let user = selectedUser {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name: \(user.firstName) \(user.lastName)").bold()
                            Text("Email: \(user.email)")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }

                    // Book Details with Scanner
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ISBN-13").font(.subheadline).foregroundColor(.gray)
                        HStack {
                            TextField("Enter ISBN-13", text: $isbn13)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button(action: {
                                isShowingScanner = true
                            }) {
                                Image(systemName: "barcode.viewfinder")
                                    .font(.title)
                                    .foregroundColor(.blue)
                            }
                        }
                    }

                    // Due Date Picker
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Select Due Date").font(.subheadline).foregroundColor(.gray)
                            Spacer()
                            Text(dueDate, style: .date) // Display selected date
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .onTapGesture {
                                    withAnimation {
                                        isCalendarVisible.toggle()
                                    }
                                }
                        }
                        .padding(.vertical, 8)

                        if isCalendarVisible {
                            DatePicker("", selection: $dueDate, in: Date()..., displayedComponents: [.date])
                                .labelsHidden()
                                .datePickerStyle(GraphicalDatePickerStyle())
                        }
                    }

                    // Issue Book Button
                    Button(action: issueBook) {
                        Text("Issue Book")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("Issue Book")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Library System"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $isShowingScanner) {
                CodeScannerView(codeTypes: [.ean13, .ean8], simulatedData: "9781234567890") { result in
                    switch result {
                    case .success(let code):
                        isbn13 = code.string
                        isShowingScanner = false
                    case .failure(let error):
                        alertMessage = "Scan failed: \(error.localizedDescription)"
                        showAlert = true
                        isShowingScanner = false
                    }
                }
            }
        }
    }

    // Function to check if the user is registered
    func isRegisteredUser(email: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let lowercaseEmail = email.lowercased()

        db.collection("users").whereField("email", isEqualTo: lowercaseEmail).getDocuments { snapshot, error in
            if let error = error {
                print("Error checking user: \(error.localizedDescription)")
                completion(false)
                return
            }

            let isRegistered = !(snapshot?.documents.isEmpty ?? true)
            completion(isRegistered)
        }
    }

    // Function to issue a book
    func issueBook() {
        guard !isbn13.isEmpty, !email.isEmpty else {
            alertMessage = "ISBN-13 and Email are required!"
            showAlert = true
            return
        }

        let lowercaseEmail = email.lowercased()
        let currentDate = Date()

        guard dueDate > currentDate else {
            alertMessage = "Due date must be after the issue date!"
            showAlert = true
            return
        }

        let db = Firestore.firestore()

        db.collection("books").whereField("isbn13", isEqualTo: isbn13).getDocuments { snapshot, error in
            if let error = error {
                alertMessage = "Error fetching book details: \(error.localizedDescription)"
                showAlert = true
                return
            }

            guard let document = snapshot?.documents.first, let bookData = document.data() as? [String: Any] else {
                alertMessage = "Book not found!"
                showAlert = true
                return
            }

            let totalCheckouts = bookData["totalCheckouts"] as? Int ?? 0
            let quantity = bookData["quantity"] as? Int ?? 0

            if totalCheckouts >= quantity {
                alertMessage = "Book is out of stock!"
                showAlert = true
                return
            }

            let issuedBook: [String: Any] = [
                "email": lowercaseEmail,
                "isbn13": isbn13,
                "issue_date": Timestamp(date: currentDate),
                "due_date": Timestamp(date: dueDate),
                "fine": 0,
                "status": "Borrowed"
            ]

            isRegisteredUser(email: email) { isRegistered in
                DispatchQueue.main.async {
                    if isRegistered {
                        db.collection("issued_books").addDocument(data: issuedBook) { error in
                            if let error = error {
                                alertMessage = "Error: \(error.localizedDescription)"
                                showAlert = true
                            } else {
                                db.collection("books").document(document.documentID).updateData([
                                    "totalCheckouts": totalCheckouts + 1
                                ]) { error in
                                    if let error = error {
                                        alertMessage = "Error updating total checkouts: \(error.localizedDescription)"
                                    } else {
                                        alertMessage = "Book Issued Successfully!"
                                    }
                                    showAlert = true
                                }
                            }
                        }
                    } else {
                        alertMessage = "User not found."
                        showAlert = true
                    }
                }
            }
        }
    }
}

#Preview {
    AddIssueBookView()
}
