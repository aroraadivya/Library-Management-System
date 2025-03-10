import SwiftUI
import FirebaseFirestore
import UIKit

struct BookDetailView: View {
    let book: Book
    @Environment(\.dismiss) var dismiss
    @State private var showMoreDescription = false
    @State private var availableBooks: Int
    @State private var currentlyBorrowed: Int
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAlert = false
    
    // Image handling states
    @State private var showingImagePicker = false
    @State private var showingImageSourceOptions = false
    @State private var selectedImage: UIImage?
    @State private var decodedImage: UIImage?
    @State private var imageChanged = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .camera
    
    init(book: Book) {
        self.book = book
        _availableBooks = State(initialValue: book.availableQuantity)
        _currentlyBorrowed = State(initialValue: book.currentlyBorrowed)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Book Cover with option to change
                ZStack {
                    if let image = decodedImage ?? selectedImage {
                        // Show selected or decoded image
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: UIScreen.main.bounds.width - 32, height: 300)
                    } else {
                        // Show image from URL or placeholder
                        BookImageView(
                            url: book.getImageUrl(),
                            width: UIScreen.main.bounds.width - 32,
                            height: 300
                        )
                    }
                    
                    // Change image button overlay
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                // Direct camera access - preferring this over action sheet
                                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                    imageSourceType = .camera
                                    showingImagePicker = true
                                } else {
                                    // Fallback to action sheet if camera isn't directly accessible
                                    showingImageSourceOptions = true
                                }
                            }) {
                                VStack(spacing: 2) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 20))
                                    Text("Take Photo")
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
                    }
                }
                .onTapGesture {
                    // Show source options when tapping the image
                    showingImageSourceOptions = true
                }
                
                // Book Title and Author
                Text(book.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("By " + (book.authors.joined(separator: ", ")))
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                // Book Details
                Group {
                    if let publisher = book.publisher {
                        Text("Publisher: \(publisher)")
                    }
                    if let publishedDate = book.publishedDate {
                        Text("Published: \(publishedDate)")
                    }
                    if let isbn = book.isbn13 {
                        Text("ISBN: \(isbn)")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                // Available Books
                Text("Available Books: \(availableBooks)")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .padding(.vertical, 10)
                
                // Borrow and Return Buttons
                HStack(spacing: 20) {
                    Button(action: returnBook) {
                        Text("Return Book")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(currentlyBorrowed > 0 ? Color.green : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(currentlyBorrowed == 0 || isLoading)
                }
                .padding(.vertical, 10)
                
                // Save Image Button (if changed)
                if imageChanged {
                    Button(action: saveImage) {
                        Text("Save Book Image")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.vertical, 10)
                }
                
                // Description Section
                if let description = book.description {
                    descriptionSection(description)
                }
                
                // Delete Book Button
                Button(action: deleteBook) {
                    Text("Delete Book")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding(.vertical, 10)
            }
            .padding()
        }
        .navigationTitle("Book Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerBooks(
                image: $selectedImage,
                sourceType: imageSourceType,
                didSelectImage: {
                    imageChanged = true
                }
            )
        }
        .actionSheet(isPresented: $showingImageSourceOptions) {
            ActionSheet(
                title: Text("Add Book Image"),
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
                title: Text(errorMessage?.contains("Error") ?? false ? "Error" : "Success"),
                message: Text(errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            // Try to decode existing base64 image if available
            decodeBase64Image()
        }
    }
    
    // Decode base64 image if present in book.coverImageUrl
    private func decodeBase64Image() {
        if let coverImageUrl = book.coverImageUrl,
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
            errorMessage = "Failed to convert image to base64"
            showAlert = true
            return
        }
        
        isLoading = true
        let db = Firestore.firestore()
        
        db.collection("books").document(book.id).updateData([
            "coverImageUrl": base64String,
            "lastUpdated": Timestamp()
        ]) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Failed to save image: \(error.localizedDescription)"
                showAlert = true
            } else {
                imageChanged = false
                // Success message
                errorMessage = "Image saved successfully"
                showAlert = true
            }
        }
    }
    
    @ViewBuilder
    private func descriptionSection(_ description: String) -> some View {
        Button(action: {
            withAnimation {
                showMoreDescription.toggle()
            }
        }) {
            HStack {
                Text(showMoreDescription ? "Hide Description" : "Show More")
                    .font(.headline)
                    .foregroundColor(.blue)
                Spacer()
                Image(systemName: showMoreDescription ? "chevron.up" : "chevron.down")
                    .foregroundColor(.blue)
            }
            .padding()
        }
        
        if showMoreDescription {
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
    }
    
    private func borrowBook() {
        guard availableBooks > 0 else { return }
        
        isLoading = true
        let db = Firestore.firestore()
        
        let bookRef = db.collection("books").document(book.id)
        
        bookRef.updateData([
            "availableQuantity": FieldValue.increment(Int64(-1)),
            "currentlyBorrowed": FieldValue.increment(Int64(1)),
            "lastUpdated": Timestamp()
        ]) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Failed to borrow book: \(error.localizedDescription)"
                showAlert = true
            } else {
                availableBooks -= 1
                currentlyBorrowed += 1
            }
        }
    }
    
    private func returnBook() {
        guard currentlyBorrowed > 0 else { return }
        
        isLoading = true
        let db = Firestore.firestore()
        
        let bookRef = db.collection("books").document(book.id)
        
        bookRef.updateData([
            "availableQuantity": FieldValue.increment(Int64(1)),
            "currentlyBorrowed": FieldValue.increment(Int64(-1)),
            "lastUpdated": Timestamp()
        ]) { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Failed to return book: \(error.localizedDescription)"
                showAlert = true
            } else {
                availableBooks += 1
                currentlyBorrowed -= 1
            }
        }
    }
    
    private func deleteBook() {
        isLoading = true
        let db = Firestore.firestore()
        
        db.collection("books").document(book.id).delete { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Failed to delete book: \(error.localizedDescription)"
                showAlert = true
            } else {
                dismiss()
            }
        }
    }
}

// Image Picker component for Books
struct ImagePickerBooks: UIViewControllerRepresentable {
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
        let parent: ImagePickerBooks
        
        init(_ parent: ImagePickerBooks) {
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
