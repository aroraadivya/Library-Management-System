import SwiftUI
import FirebaseFirestore

struct LibrariansView: View {
    @State private var librarians: [Librarian] = []
    @State private var searchText = ""
    @State private var showAddLibrariansForm = false
    
    var filteredLibrarians: [Librarian] {
        if searchText.isEmpty {
            return librarians
        } else {
            return librarians.filter {
                $0.fullName.localizedCaseInsensitiveContains(searchText) ||
                $0.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.gray)
                        TextField("Search", text: $searchText)
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2)) {
                        LibrarianStatCard(title: "Total Librarians", value: "\(librarians.count)", icon: "person.3")
                        LibrarianStatCard(title: "Active Librarians", value: "\(librarians.filter { !$0.isSuspended }.count)", icon: "person.fill.checkmark")
                        LibrarianStatCard(title: "On Leave", value: "\(librarians.filter { $0.isSuspended }.count)", icon: "person.fill.xmark")
                        LibrarianStatCard(title: "Suspended", value: "\(librarians.filter { $0.isSuspended }.count)", icon: "nosign")
                    }
                    .padding(.horizontal)
                    .cornerRadius(10)
                    
                    VStack {
                        ForEach(filteredLibrarians.indices, id: \..self) { index in
                            LibrarianRow(librarian: $librarians[index])
                            Divider()
                        }
                    }
                    .padding()
                    .background(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Librarians")
            .toolbar {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .onTapGesture {
                        showAddLibrariansForm = true
                    }
            }
            .sheet(isPresented: $showAddLibrariansForm) {
                NavigationStack {
                    AddLibrarianView()
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .onAppear {
            fetchLibrarians()
        }
    }
    
    private func fetchLibrarians() {
        let db = Firestore.firestore()
        db.collection("librarians").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching librarians: \(error.localizedDescription)")
                return
            }
            
            if let documents = snapshot?.documents {
                self.librarians = documents.map { doc in
                    let data = doc.data()
                    return Librarian(
                        id: doc.documentID,
                        userId: data["userId"] as? String ?? "",
                        fullName: data["fullName"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        phone: data["phone"] as? String ?? "",
                        isEmployee: data["isEmployee"] as? Bool ?? true,
                        role: data["role"] as? String ?? "Librarian",
                        createdAt: data["createdAt"] as? Timestamp ?? Timestamp(),
                        isSuspended: data["isSuspended"] as? Bool ?? false
                    )
                }
            }
        }
    }
}

struct LibrarianRow: View {
    @Binding var librarian: Librarian
    
    var body: some View {
        HStack {
            Image(systemName: "person.crop.circle")
                .resizable()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(librarian.fullName)
                    .font(.headline)
                Text(librarian.email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            
            Menu {
                Button("Active", action: { librarian.isSuspended = false })
                Button("Suspended", action: { librarian.isSuspended = true })
            }
            label: {
                HStack {
                    Text(librarian.isSuspended ? "Suspended" : "Active")
                        .foregroundColor(librarian.isSuspended ? .orange : .green)
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
            }
        }
        .padding(.vertical, 0)
    }
}

struct LibrarianStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .center) {
                Image(systemName: icon)
                    .resizable()
                    .frame(width: 34, height: 30)
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.blue)
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.white))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray.opacity(0.2), lineWidth: 1.4)
        )
    }
}

struct LibrariansView_Previews: PreviewProvider {
    static var previews: some View {
        LibrariansView()
    }
}
