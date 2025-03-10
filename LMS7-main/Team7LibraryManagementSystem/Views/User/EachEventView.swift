import SwiftUI
import FirebaseFirestore

struct EachEventView: View {
    let event: EventModel
    @State private var decodedImage: UIImage? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Image and Title
                ZStack(alignment: .bottomLeading) {
                    // Event Cover Image from base64
                    if let image = decodedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                    } else {
                        // Placeholder when no image is available
                        Image(systemName: "photo.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text(event.title)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.white)
                            Text(formattedEventType)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                
                // Event Details Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("About Event")
                        .font(.headline)
                    
                    Text(event.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                // Date and Time Information
                EventInfoRow(
                    icon: "clock",
                    title: "Date & Time",
                    value: formattedDateTime
                )
                
                // Event Type
                EventInfoRow(
                    icon: "tag",
                    title: "Event Type",
                    value: event.eventType
                )
                
                // Status Information
                EventInfoRow(
                    icon: "circle.fill",
                    title: "Status",
                    value: event.status,
                    valueColor: event.status == "Live" ? .green : .gray
                )
                
                // Location Information
                if !event.location.isEmpty {
                    EventInfoRow(
                        icon: "mappin.and.ellipse",
                        title: "Location",
                        value: event.location
                    )
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: registerForEvent) {
                        Text("Register for Event")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: shareEvent) {
                        Text("Share Event")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            decodeBase64Image()
        }
    }
    
    // Function to decode base64 image
    private func decodeBase64Image() {
        if let base64String = event.coverImage,
           !base64String.isEmpty,
           let imageData = Data(base64Encoded: base64String) {
            decodedImage = UIImage(data: imageData)
        }
    }
    
    // Formatted Event Type
    private var formattedEventType: String {
        return event.eventType.capitalized
    }
    
    // Formatted Date and Time
    private var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        
        return "\(formatter.string(from: event.startTime)) • \(timeFormatter.string(from: event.startTime)) - \(timeFormatter.string(from: event.endTime))"
    }
    
    // Register for Event Action
    private func registerForEvent() {
        // TODO: Implement event registration logic
        print("Registering for event: \(event.title)")
    }
    
    // Share Event Action
    private func shareEvent() {
        // TODO: Implement event sharing functionality
        print("Sharing event: \(event.title)")
    }
}

// Reusable Event Info Row
struct EventInfoRow: View {
    let icon: String
    let title: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.body)
                    .foregroundColor(valueColor)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}
