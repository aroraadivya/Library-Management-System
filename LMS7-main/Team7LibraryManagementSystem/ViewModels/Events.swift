//
//  Events.swift
//  Team7LibraryManagementSystem
//
//  Created by Rakshit  on 26/02/25.
//


import Foundation
import FirebaseFirestore



struct EventModel: Identifiable {
    let id: String // Keep 'id' constant as it should not change
    var title: String
    var description: String
    var coverImage: String? // Optional
    var startTime: Date
    var endTime: Date
    var eventType: String
    var location: String
    var notifyMembers: Bool
    var status: String
}
