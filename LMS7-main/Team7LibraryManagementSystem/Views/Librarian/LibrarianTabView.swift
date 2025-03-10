//
//  LinrarianTabView.swift
//  LinrarianSide
//
//  Created by Taksh Joshi on 20/02/25.
//

import SwiftUI

struct LibrarianTabView: View {
    var body: some View {
            TabView {
                libHomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                
                BooksView()
                    .tabItem {
                        Label("Books", systemImage: "book")
                    }
                
                AddIssueBookView()
                    .tabItem {
                        Label("Issue Book", systemImage: "bookmark.fill")
                    }
                
                LiveEventsView()
                    .tabItem {
                        Label("Events", systemImage: "calendar")
                    }
                
                LibraryUsersView()
                    .tabItem {
                        Label("Users", systemImage: "person")
                    }
                
                
            }
        }
}

#Preview {
    LibrarianTabView()
}
