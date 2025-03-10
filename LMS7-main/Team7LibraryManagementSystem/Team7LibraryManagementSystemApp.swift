//
//  Team7LibraryManagementSystemApp.swift
//  Team7LibraryManagementSystem
//
//  Created by Rakshit  on 16/02/25.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct Team7LibraryManagementSystemApp: App {
   // @StateObject private var wishlistManager = WishlistManager()
    @StateObject private var wishlistManager = WishlistManager()

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
//            ContentView()
            LibraryLoginView();
        }
    }
}
