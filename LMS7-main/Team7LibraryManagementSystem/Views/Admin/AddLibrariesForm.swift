import SwiftUI
import FirebaseFirestore

struct AddLibrariesForm: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Basic Information
    @State private var libraryName = ""
    @State private var libraryCode = ""
    @State private var description = ""
    @State private var selectedImage: UIImage? = nil
    
    // Location Details
    @State private var addressLine1 = ""
    @State private var addressLine2 = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var country = ""
    
    // Contact Information
    @State private var phoneNumber = ""
    @State private var emailAddress = ""
    @State private var website = ""
    
    // Operational Hours
    @State private var openingTimeWeekday = ""
    @State private var closingTimeWeekday = ""
    @State private var openingTimeWeekend = ""
    @State private var closingTimeWeekend = ""
    
    // Library Settings
    @State private var maxBooksPerMember = ""
    @State private var lateFee = ""
    @State private var lendingPeriod = ""
    
    // Staff Information
    @State private var headLibrarian = ""
    @State private var totalStaff = ""
    
    // Additional Features
    @State private var hasWifi = false
    @State private var hasComputerLab = false
    @State private var hasMeetingRooms = false
    @State private var hasParking = false
    
    @State private var errorMessage: String?
    @State private var showAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    LibSectionView(title: "Basic Information", content: {
                        InputField(title: "Library Name", text: $libraryName, isRequired: true)
                        InputField(title: "Library Code", text: $libraryCode, isRequired: true)
                        InputField(title: "Description", text: $description, isMultiline: true)
                        UploadImageButton(selectedImage: $selectedImage)
                    })
                    
                    LibSectionView(title: "Location Details", icon: "mappin.and.ellipse", content: {
                        InputField(title: "Address Line", text: $addressLine1, isRequired: true)
                        
                        HStack {
                            InputField(title: "City", text: $city, isRequired: true)
                            InputField(title: "State", text: $state, isRequired: true)
                        }
                        HStack {
                            InputField(title: "ZIP Code", text: $zipCode, isRequired: true)
                            InputField(title: "Country", text: $country)
                        }
                    })
                    
                    LibSectionView(title: "Contact Information", content: {
                        InputField(title: "Phone Number", text: $phoneNumber, isRequired: true)
                        InputField(title: "Email Address", text: $emailAddress, isRequired: true)
                        InputField(title: "Website", text: $website)
                    })
                    
                    LibSectionView(title: "Operational Hours", icon: "clock", content: {
                        HStack {
                            InputField(title: "Weekday Opening", text: $openingTimeWeekday)
                            InputField(title: "Weekday Closing", text: $closingTimeWeekday)
                        }
                        HStack {
                            InputField(title: "Weekend Opening", text: $openingTimeWeekend)
                            InputField(title: "Weekend Closing", text: $closingTimeWeekend)
                        }
                    })
                    
                    LibSectionView(title: "Library Settings", icon: "info.circle", content: {
                        InputField(title: "Maximum Books Per Member", text: $maxBooksPerMember)
                        InputField(title: "Late Fee (per day)", text: $lateFee)
                        InputField(title: "Lending Period (days)", text: $lendingPeriod)
                    })
                    
                    LibSectionView(title: "Staff Information", icon: "person.2", content: {
                        InputField(title: "Head Librarian Name", text: $headLibrarian)
                        InputField(title: "Total Staff Members", text: $totalStaff)
                    })
                    
                    LibSectionView(title: "Additional Features", content: {
                        ToggleField(title: "WiFi Available", isOn: $hasWifi)
                        ToggleField(title: "Computer Lab", isOn: $hasComputerLab)
                        ToggleField(title: "Meeting Rooms", isOn: $hasMeetingRooms)
                        ToggleField(title: "Parking Available", isOn: $hasParking)
                    })
                }
                .padding()
            }
            .navigationTitle("Add Libraries")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveLibrary()
                }
            )
            .background(Color(.systemGroupedBackground))
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func isFormValid() -> Bool {
        return !libraryName.isEmpty && !libraryCode.isEmpty && !addressLine1.isEmpty &&
               !city.isEmpty && !state.isEmpty && !zipCode.isEmpty && !phoneNumber.isEmpty &&
               !emailAddress.isEmpty
    }
    
    private func saveLibrary() {
        guard isFormValid() else {
            errorMessage = "Please fill all required fields."
            showAlert = true
            return
        }
        
        let db = Firestore.firestore()
        let newLibrary: [String: Any] = [
            "name": libraryName,
            "code": libraryCode,
            "description": description,
            "address": [
                "line1": addressLine1,
                "line2": addressLine2,
                "city": city,
                "state": state,
                "zipCode": zipCode,
                "country": country
            ],
            "contact": [
                "phone": phoneNumber,
                "email": emailAddress,
                "website": website
            ],
            "operationalHours": [
                "weekday": [
                    "opening": openingTimeWeekday,
                    "closing": closingTimeWeekday
                ],
                "weekend": [
                    "opening": openingTimeWeekend,
                    "closing": closingTimeWeekend
                ]
            ],
            "settings": [
                "maxBooksPerMember": maxBooksPerMember,
                "lateFee": lateFee,
                "lendingPeriod": lendingPeriod
            ],
            "staff": [
                "headLibrarian": headLibrarian,
                "totalStaff": totalStaff
            ],
            "features": [
                "wifi": hasWifi,
                "computerLab": hasComputerLab,
                "meetingRooms": hasMeetingRooms,
                "parking": hasParking
            ],
            "createdAt": Timestamp()
        ]
        
        db.collection("libraries").addDocument(data: newLibrary) { error in
            if let error = error {
                errorMessage = "Error saving library: \(error.localizedDescription)"
                showAlert = true
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct ToggleField: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(title, isOn: $isOn)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
}

struct LibSectionView<Content: View>: View {
    let title: String
    var icon: String? = nil
    let content: Content
    
    init(title: String, icon: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.blue)
                }
                Text(title)
                    .font(.headline)
                    .bold()
            }
            content
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct InputField: View {
    let title: String
    @Binding var text: String
    var isRequired: Bool = false
    var isMultiline: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title + (isRequired ? " *" : ""))
                .font(.footnote)
                .foregroundColor(.gray)
            if isMultiline {
                TextEditor(text: $text)
                    .frame(height: 80)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                TextField("Enter \(title.lowercased())", text: $text)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
}

struct UploadImageButton: View {
    @Binding var selectedImage: UIImage?
    
    var body: some View {
        VStack {
            Button(action: { }) {
                HStack {
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                    Text("Upload Image")
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity, minHeight: 50)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, style: StrokeStyle(lineWidth: 1, dash: [5]))
                )
            }
        }
    }
}

struct AddLibrariesForm_Previews: PreviewProvider {
    static var previews: some View {
        AddLibrariesForm()
    }
}
