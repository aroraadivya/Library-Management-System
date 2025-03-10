import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0 // Default to Home (Admin Dashboard)

    var body: some View {
        TabView(selection: $selectedTab) {
            AdminDashboardView() // Set this as the new home screen
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)

            NavigationStack {
                LibrariansView()
            }
            .tabItem {
                Image(systemName: "person.2.fill")
                Text("Librarians")
            }
            .tag(1)

            MyLibrariesView()
                .tabItem {
                    Image(systemName: "books.vertical.fill")
                    Text("Libraries")
                }
                .tag(2)

            LiveEventsView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Events")
                }
                .tag(3)
        }
    }
}

#Preview{
    MainTabView()
}
