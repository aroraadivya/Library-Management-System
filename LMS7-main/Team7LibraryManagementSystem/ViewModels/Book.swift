//
//  books.swift
//  Team7LibraryManagementSystem
//
//  Created by Taksh Joshi on 18/02/25.
//

import Foundation

// Models for Google Books API
struct GoogleBooksResponse: Codable {
    let kind: String?
    let totalItems: Int?
    let items: [Volume]?
}

struct Volume: Codable {
    let id: String
    let volumeInfo: VolumeInfo
}

struct VolumeInfo: Codable {
    let title: String
    let authors: [String]?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let pageCount: Int?
    let categories: [String]?
    let imageLinks: ImageLinks?
    let language: String?
    let industryIdentifiers: [IndustryIdentifier]?
    
    private enum CodingKeys: String, CodingKey {
        case title, authors, publisher, publishedDate, description
        case pageCount, categories, imageLinks, language
        case industryIdentifiers
    }
}

struct ImageLinks: Codable {
    let thumbnail: String?
    let smallThumbnail: String?
}

struct IndustryIdentifier: Codable {
    let type: String
    let identifier: String
}

// Model for Library Book

struct Book: Identifiable, Codable {
   // @DocumentID var documentID: String? // Store Firestore's auto-generated document ID if needed
    let id: String // This will be mapped from "bookId" in Firestore
    let title: String
    let authors: [String]
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let pageCount: Int?
    let categories: [String]?
    let coverImageUrl: String?
    let isbn13: String?
    let language: String?
    
    // Library-specific data
    let quantity: Int
    let availableQuantity: Int
    let location: String
    let status: String
    let totalCheckouts: Int
    let currentlyBorrowed: Int
    let isAvailable: Bool
    let libraryId: String? // Add this property


    // Map Firestore fields correctly
    enum CodingKeys: String, CodingKey {
            case id = "bookId"
            case title, authors, publisher, publishedDate, description
            case pageCount, categories, coverImageUrl, isbn13, language
            case quantity, availableQuantity, location, status, totalCheckouts, currentlyBorrowed, isAvailable
            case libraryId
        }

    func getImageUrl() -> URL? {
        guard let coverImageUrl = coverImageUrl,
              let encodedURL = coverImageUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURL) else {
            return nil
        }
        return url
    }
}

// For issued books tracking
struct IssuedBook: Identifiable {
    let id: String
    let title: String
    let authors: [String]
    let coverImageUrl: String?
    let dueDate: Date
    let status: String
    let borrowerId: String
    
    var daysLeft: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }
    
    var isOverdue: Bool {
        daysLeft < 0
    }
    
    var formattedDueDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: dueDate)
    }
    
    // Convert from Book to IssuedBook
    static func fromBook(_ book: Book, dueDate: Date, borrowerId: String) -> IssuedBook {
        IssuedBook(
            id: book.id,
            title: book.title,
            authors: book.authors,
            coverImageUrl: book.coverImageUrl,
            dueDate: dueDate,
            status: "borrowed",
            borrowerId: borrowerId
        )
    }
}
