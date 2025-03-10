import SwiftUI
import FirebaseFirestore


struct LiveEventsView: View {
    @State private var liveEvents: [EventModel] = []
    @State private var selectedCategory: String = "All"
    @State private var showingEventCreationView = false
    
    // Stats
    @State private var activeEventsCount: String = ""
    @State private var totalAttendeesCount: String = ""
    @State private var spacesInUse: String = ""
    
    @State private var eventStatus: String = ""
    
    private let db = Firestore.firestore()
    
    var categories = ["All", "Workshops", "Book Clubs", "Lect"]

    var filteredEvents: [EventModel] {
        if selectedCategory == "All" {
            return liveEvents
        } else {
            return liveEvents.filter {
                switch selectedCategory {
                case "Workshops": return $0.eventType == "Workshop"
                case "Book Clubs": return $0.eventType == "Book Club"
                case "Lecture": return $0.eventType == "Lecture"
                default: return true
                }
            }
        }
    }
    
   
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Stats Header
                    HStack(alignment: .center, spacing: 15) {
                        StatCard(icon: "", title: activeEventsCount, subtitle: "Active Events", color: .blue)
                        StatCard(icon: "", title: spacesInUse, subtitle: "Spaces in Use", color: .red)
                    }
                    .padding()
                    .padding(.bottom, 15)
                    .padding(.top, 25)
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(Color(.systemBackground))
                    
                    // Live Events Content
                    if filteredEvents.isEmpty {
                        // Empty State
                        VStack {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                            Text("No live events")
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 50)
                    } else {
                        // Events using ForEach instead of List
                        VStack(spacing: 12) {
                            ForEach(filteredEvents) { eventItem in
                                EventRow(eventItem: eventItem)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.top, 16)
                    }
                }
            }
            .navigationTitle("Live Events")
            .navigationBarItems(trailing:
                Button(action: {
                    showingEventCreationView = true
                }) {
                    Image(systemName: "plus")
                }
            )
            .onAppear(perform: fetchEvents)
            .sheet(isPresented: $showingEventCreationView) {
                EventCreationView()
            }
        }
    }
    // Fetch Events from Firebase Firestore
    private func fetchEvents() {
        let now = Date()

        db.collection("events")
            .whereField("status", isEqualTo: "Live")
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching events: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                var events: [EventModel] = []
                var spacesUsed = 0
                
                for doc in documents {
                    let data = doc.data()
                    let id = doc.documentID
                    let title = data["title"] as? String ?? "No Title"
                    let description = data["description"] as? String ?? "No Description"
                    let coverImage = data["coverImage"] as? String ?? ""
                    let startTime = (data["startDateTime"] as? Timestamp)?.dateValue() ?? Date()
                    let endTime = (data["endDateTime"] as? Timestamp)?.dateValue() ?? Date()
                    let eventType = data["eventType"] as? String ?? "Other"
                    let location = data["location"] as? String ?? "Unknown"
                    let notifyMembers = data["notifyMembers"] as? Bool ?? false
                    let status = data["status"] as? String ?? ""

                    // Fetch only ongoing (Live) or upcoming events
                    if endTime > now {
                        let eventItem = EventModel(
                            id: id,
                            title: title,
                            description: description,
                            coverImage: coverImage,
                            startTime: startTime,
                            endTime: endTime,
                            eventType: eventType,
                            location: location,
                            notifyMembers: notifyMembers,
                            status: status
                        )
                        
                        events.append(eventItem)
                        spacesUsed += 1
                    }
                }
                
                DispatchQueue.main.async {
                    self.liveEvents = events
                    self.activeEventsCount = "\(events.count)"
                    self.spacesInUse = "\(spacesUsed)"
                }
            }
    }

    // End Event Action
    private func endEvent(selectedEvent: EventModel) {
        db.collection("events").document(selectedEvent.id).updateData(["status": "Ended"]) { error in
            if let error = error {
                print("Error ending event: \(error)")
            } else {
                fetchEvents() // Refresh data
            }
        }
    }
}

// Stat Card View
struct StatCard3: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack {
            Text("\(value)")
                .font(.headline)
                .foregroundColor(.blue)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .frame(width: 120)
    }
}

// Category Button
struct CategoryButton: View {
    let category: String
    @Binding var selectedCategory: String

    var body: some View {
        Text(category)
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(selectedCategory == category ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundColor(selectedCategory == category ? Color.blue : Color.black)
            .clipShape(Capsule())
            .onTapGesture {
                selectedCategory = category
            }
    }
}


struct EventRow: View {
    let eventItem: EventModel
    @State private var decodedImage: UIImage? = nil
    
    var body: some View {
        NavigationLink(destination: EachEventView(event: eventItem)) {
            HStack {
                // Image from base64
                if let image = decodedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 70, height: 70)
                        .cornerRadius(8)
                        .clipped()
                } else {
                    // Placeholder when no image is available
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 70, height: 70)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(eventItem.title)
                        .font(.headline)
                    
                    Text("\(formattedDate(eventItem.startTime)) - \(formattedDate(eventItem.endTime))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Live status indicator
                if eventItem.status == "Live" {
                    Text("● Live")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("● \(eventItem.status)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
        }
        .onAppear {
            decodeBase64Image()
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
    
    // Function to decode base64 image
    private func decodeBase64Image() {
        if let base64String = eventItem.coverImage,
           !base64String.isEmpty,
           let imageData = Data(base64Encoded: base64String) {
            decodedImage = UIImage(data: imageData)
        }
    }
}
struct LiveEventsView_Previews: PreviewProvider {
    static var previews: some View {
        LiveEventsView()
    }
}

