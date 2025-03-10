
import SwiftUI
import FirebaseFirestore

struct UserEventsView: View {
    @State private var liveEvents: [EventModel] = []
    @State private var selectedCategory: String = "All"
    @State private var showingEventCreationView = false
    
    // Stats
    @State private var activeEventsCount: String = ""
    @State private var totalAttendeesCount: String = ""
    @State private var spacesInUse: String = ""
    
    private let db = Firestore.firestore()
    
    var categories = ["All", "Workshops", "Book Clubs", "Lecture", "Social"]

    var filteredEvents: [EventModel] {
        if selectedCategory == "All" {
            return liveEvents
        } else {
            return liveEvents.filter { $0.eventType == selectedCategory }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                // Stats Header
                HStack(alignment: .center, spacing: 15) {
                    StatCard(title: activeEventsCount, subtitle: "Active Events", color: .blue)
                    StatCard(title: spacesInUse, subtitle: "Spaces in Use", color: .red)
                }
                .padding()
                .frame(maxWidth: .infinity)
//                .frame(height: 150)
                .background(Color(.systemBackground))

                // Live Events List
                if filteredEvents.isEmpty {
                    VStack {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                        Text("No live events")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                   
                        VStack(spacing: 15) {
                            ForEach(filteredEvents) { eventItem in
                                EventRow(eventItem: eventItem)
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(10)
                                    .shadow(radius: 2)
                            }
                        }
                        .padding()
                        .padding(.top,-7)
                    }
                }
            }
            .navigationTitle("Events")
            .onAppear {
                fetchEvents()
            }
            .sheet(isPresented: $showingEventCreationView) {
                EventCreationView()
            }
        }
    }


    struct StatCard: View {
        let title: String
        let subtitle: String
        let color: Color
        
        var body: some View {
            VStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
             
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
  
    
    
    
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


}

#Preview{
    UserEventsView()
}
