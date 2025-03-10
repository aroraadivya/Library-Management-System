import SwiftUI
import FirebaseFirestore
import UIKit

struct EachLibraryView: View {
    let library: Library
    @State private var librarians: [Librarian] = []
    @State private var isAddingLibrarian = false  // Controls modal presentation
    
    // Image handling states
    @State private var showingImagePicker = false
    @State private var showingImageSourceOptions = false
    @State private var selectedImage: UIImage?
    @State private var decodedImage: UIImage?
    @State private var imageChanged = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .camera
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Image with Library Name
                ZStack(alignment: .bottomLeading) {
                    // Display image based on priority: selected > decoded > placeholder
                    if let image = selectedImage ?? decodedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                    } else if let coverImageUrl = library.coverImageUrl, !coverImageUrl.isEmpty {
                        AsyncImage(url: URL(string: coverImageUrl)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 200)
                            case .empty, .failure:
                                Image(systemName: "photo.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 200)
                                    .clipped()
                                    .foregroundColor(.gray)
                            @unknown default:
                                ProgressView()
                            }
                        }
                    } else {
                        Image(systemName: "photo.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                            .foregroundColor(.gray)
                    }
                    
                    // Overlay for library name
                    HStack {
                        Text(library.name)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.black)
                        Spacer()
                        
                        HStack {
                            Image(systemName: "building.columns")
                                .foregroundColor(.blue)
                            Text(library.code)
                                .foregroundColor(.black)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    
                    // Camera button overlay for changing image
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                showingImageSourceOptions = true
                            }) {
                                VStack(spacing: 2) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 20))
                                    Text("Change Photo")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding(12)
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(radius: 3)
                            }
                            .padding(16)
                        }
                        .padding(.bottom, 50) // Push above the name overlay
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.2))
                .onTapGesture {
                    showingImageSourceOptions = true
                }
                
                // Save Image Button (if changed)
                if imageChanged {
                    Button(action: saveImage) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Save Library Image")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isLoading ? Color.gray : Color.blue)
                    .cornerRadius(10)
                    .disabled(isLoading)
                    .padding(.horizontal)
                }
                
                // About Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("About")
                        .font(.headline)
                    
                    Text(library.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    EachInfoRow(icon: "mappin.circle", title: "Location", value: "\(library.address.line1), \(library.address.city)")
                    EachInfoRow(icon: "phone.circle", title: "Contact", value: library.contact.phone)
                    EachInfoRow(icon: "envelope", title: "Email", value: library.contact.email)
                    EachInfoRow(icon: "globe", title: "Website", value: library.contact.website)
                }
                .padding(.horizontal)
                
                // Statistics Grid
                VStack(alignment: .leading, spacing: 10) {
                    Text("Operating Information")
                        .font(.headline)
                        .padding(.leading)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatisticCard(icon: "clock", title: "Weekday Hours", value: "\(library.operationalHours.weekday.opening) - \(library.operationalHours.weekday.closing)", change: nil)
                        StatisticCard(icon: "clock", title: "Weekend Hours", value: "\(library.operationalHours.weekend.opening) - \(library.operationalHours.weekend.closing)", change: nil)
                        StatisticCard(icon: "person.2.fill", title: "Total Staff", value: library.staff.totalStaff, change: nil)
                        StatisticCard(icon: "person.fill.badge.plus", title: "Head Librarian", value: library.staff.headLibrarian, change: nil)
                    }
                }
                .padding(.horizontal)
                
                // Library Staff Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Library Staff")
                        .font(.headline)
                    
                    if librarians.isEmpty {
                        HStack {
                            Spacer()
                            Text("No librarians assigned to this library.")
                                .foregroundColor(.gray)
                                .italic()
                                .padding()
                            Spacer()
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    } else {
                        ForEach(librarians) { librarian in
                            StaffRow(
                                name: librarian.fullName,
                                email: librarian.email,
                                status: librarian.isSuspended ? "Suspended" : "Active",
                                statusColor: librarian.isSuspended ? .red : .green
                            )
                        }
                    }
                }
                .padding(.horizontal)
                
                // Library Features
                VStack(alignment: .leading, spacing: 12) {
                    Text("Features")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        FeatureCard(icon: "wifi", title: "WiFi", available: library.features.wifi)
                        FeatureCard(icon: "desktopcomputer", title: "Computer Lab", available: library.features.computerLab)
                        FeatureCard(icon: "person.3.fill", title: "Meeting Rooms", available: library.features.meetingRooms)
                        FeatureCard(icon: "car.fill", title: "Parking", available: library.features.parking)
                    }
                }
                .padding(.horizontal)
                
                // Library Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Library Policies")
                        .font(.headline)
                    
                    PerformanceRow(
                        icon: "book.closed",
                        title: "Max Books Per Member",
                        value: library.settings.maxBooksPerMember,
                        subtitle: "Borrowing limit"
                    )
                    
                    PerformanceRow(
                        icon: "dollarsign.circle",
                        title: "Late Fee",
                        value: library.settings.lateFee,
                        subtitle: "Per overdue day"
                    )
                    
                    PerformanceRow(
                        icon: "calendar",
                        title: "Lending Period",
                        value: library.settings.lendingPeriod,
                        subtitle: "Standard borrowing time"
                    )
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Library Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchLibrarians()
            decodeBase64Image()
        }
        .sheet(isPresented: $isAddingLibrarian) {
            AddLibrarianView()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerLibrary(
                image: $selectedImage,
                sourceType: imageSourceType,
                didSelectImage: {
                    imageChanged = true
                }
            )
        }
        .actionSheet(isPresented: $showingImageSourceOptions) {
            ActionSheet(
                title: Text("Change Library Image"),
                message: Text("How would you like to add a photo?"),
                buttons: [
                    .default(Text("Take Photo with Camera")) {
                        imageSourceType = .camera
                        showingImagePicker = true
                    },
                    .default(Text("Choose from Photo Library")) {
                        imageSourceType = .photoLibrary
                        showingImagePicker = true
                    },
                    .cancel()
                ]
            )
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertMessage.contains("Error") ? "Error" : "Success"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // Fetch librarians assigned to this library
    private func fetchLibrarians() {
        let db = Firestore.firestore()
        db.collection("librarians")
            .whereField("assignedLibrary", isEqualTo: library.name)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching librarians: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                
                self.librarians = documents.compactMap { doc in
                    try? doc.data(as: Librarian.self)
                }
            }
    }
    
    // Decode base64 image if present in library.coverImageUrl
    private func decodeBase64Image() {
        if let coverImageUrl = library.coverImageUrl,
           coverImageUrl.starts(with: "data:image") || coverImageUrl.hasPrefix("data:image") {
            // Extract base64 part after comma
            let components = coverImageUrl.components(separatedBy: ",")
            if components.count > 1,
               let imageData = Data(base64Encoded: components[1]) {
                decodedImage = UIImage(data: imageData)
            }
        }
    }
    
    // Convert UIImage to base64 string
    private func convertImageToBase64(_ image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            return nil
        }
        return "data:image/jpeg;base64," + imageData.base64EncodedString()
    }
    
    // Save the new image to Firestore
    private func saveImage() {
        guard let selectedImage = selectedImage else { return }
        guard let base64String = convertImageToBase64(selectedImage) else {
            alertMessage = "Failed to convert image to base64"
            showAlert = true
            return
        }
        
        isLoading = true
        let db = Firestore.firestore()
        
        db.collection("libraries").document(library.id!).updateData([
            "coverImageUrl": base64String,
            "lastUpdated": Timestamp()
        ]) { error in
            isLoading = false
            
            if let error = error {
                alertMessage = "Error saving image: \(error.localizedDescription)"
                showAlert = true
            } else {
                imageChanged = false
                alertMessage = "Library image saved successfully"
                showAlert = true
            }
        }
    }
}

// Image Picker component for Libraries
struct ImagePickerLibrary: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType = .camera
    var didSelectImage: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        
        // Use the specified source type if available
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            picker.sourceType = sourceType
        } else if sourceType == .camera {
            // If camera is requested but not available, default to photo library
            print("Camera is not available, defaulting to photo library")
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                picker.sourceType = .photoLibrary
            }
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerLibrary
        
        init(_ parent: ImagePickerLibrary) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
                parent.didSelectImage()
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
                parent.didSelectImage()
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// Rest of the components remain unchanged
struct FeatureCard: View {
    let icon: String
    let title: String
    let available: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(available ? .blue : .gray)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(available ? .green : .red)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct StaffRow: View {
    let name: String
    let email: String
    let status: String
    let statusColor: Color
    
    var body: some View {
        HStack {
            Image(systemName: "person.crop.circle.fill")
                .font(.title2)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)
                Text(email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(status)
                .font(.footnote)
                .foregroundColor(statusColor)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct EachInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.body)
            }
            
            Spacer()
        }
    }
}

struct StatisticCard: View {
    let icon: String
    let title: String
    let value: String
    let change: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Text(value)
                .font(.title3)
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PerformanceRow: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(value)
                .font(.body)
                .bold()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
