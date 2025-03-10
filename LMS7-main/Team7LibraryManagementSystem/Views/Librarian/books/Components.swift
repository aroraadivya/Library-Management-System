//
//  Components.swift
//  Team7LibraryManagementSystem
//
//  Created by Taksh Joshi on 19/02/25.
//

import SwiftUI

struct BookImageView: View {
    let url: URL?
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        AsyncImage(url: url) { phase in
            
            switch phase {
            case .empty:
                ProgressView()
                    .frame(width: width, height: height)
                    .background(Color.gray.opacity(0.1))
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .cornerRadius(8)
            case .failure:
                Image(systemName: "book")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.gray)
                    .frame(width: width, height: height)
                    .background(Color.gray.opacity(0.1))
            @unknown default:
                Image(systemName: "book")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.gray)
                    .frame(width: width, height: height)
                    .background(Color.gray.opacity(0.1))
            }
        }
    }
}
