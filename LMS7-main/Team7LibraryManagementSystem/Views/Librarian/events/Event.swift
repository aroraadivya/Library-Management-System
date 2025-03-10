import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

struct EventCreationView: View {
    @State private var event = EventModel(
        id: UUID().uuidString,
        title: "",
        description: "",
        coverImage: nil,
        startTime: Date(),
        endTime: Date(),
        eventType: "",
        location: "",
        notifyMembers: false,
        status: "Live"
    )

    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingAlert = false
    @State private var alertMessage = ""

    private let eventTypes = ["Meeting", "Workshop", "Conference", "Social"]

    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                        } else {
                            Button(action: { showingImagePicker = true }) {
                                VStack {
                                    Image(systemName: "camera")
                                        .font(.system(size: 30))
                                        .foregroundColor(.gray)
                                    Text("Add Event Cover Image")
                                        .foregroundColor(.gray)
                                }
                                .frame(height: 100)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }

                Section(header: Text("Event Details")) {
                    TextField("Event Title", text: $event.title)
                    TextField("Description", text: $event.description)
                }

                Section(header: Text("Date & Time")) {
                    DatePicker("Start Date & Time", selection: $event.startTime, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("End Date & Time", selection: $event.endTime, displayedComponents: [.date, .hourAndMinute])
                }

                Section(header: Text("Location")) {
                    TextField("Enter event location", text: $event.location)
                }

                Section(header: Text("Event Type")) {
                    Picker("Select Event Type", selection: $event.eventType) {
                        Text("Select Type").tag("")
                        ForEach(eventTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }

                Section {
                    Toggle(isOn: $event.notifyMembers) {
                        HStack {
                            Image(systemName: "bell")
                            Text("Notify Library Members")
                        }
                    }
                }

                Section {
                    Button(action: createEvent) {
                        Text("Create Event")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.blue)
                }
            }
            .navigationTitle("Events")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .alert("Event Creation", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    // Convert UIImage to base64 string
    private func convertImageToBase64(_ image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            return nil
        }
        return imageData.base64EncodedString()
    }

    private func saveEventData() {
        let db = Firestore.firestore()
        
        // Convert image to base64 if available
        var imageBase64: String? = nil
        if let image = selectedImage {
            imageBase64 = convertImageToBase64(image)
        }
        
        let eventData: [String: Any] = [
            "id": event.id,
            "title": event.title,
            "description": event.description,
            "coverImage": imageBase64 as Any, // Store as base64 string
            "startTime": Timestamp(date: event.startTime),
            "endTime": Timestamp(date: event.endTime),
            "eventType": event.eventType,
            "location": event.location,
            "notifyMembers": event.notifyMembers,
            "status": "Live"
        ]

        db.collection("events").document(event.id).setData(eventData) { error in
            if let error = error {
                alertMessage = "Error creating event: \(error.localizedDescription)"
            } else {
                alertMessage = "Event created successfully!"
                resetForm()
            }
            showingAlert = true
        }
    }

    private func createEvent() {
        // Directly save event data with base64 image
        saveEventData()
    }

    private func resetForm() {
        event = EventModel(
            id: UUID().uuidString,
            title: "",
            description: "",
            coverImage: nil,
            startTime: Date(),
            endTime: Date(),
            eventType: "",
            location: "",
            notifyMembers: false,
            status: "Live"
        )
        selectedImage = nil
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct EventCreationView_Previews: PreviewProvider {
    static var previews: some View {
        EventCreationView()
    }
}
