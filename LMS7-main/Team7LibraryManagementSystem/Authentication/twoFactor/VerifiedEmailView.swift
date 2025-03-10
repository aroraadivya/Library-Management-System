//
//  VerifiedEmailView.swift
//  Team7LMS
//
//  Created by Hardik Bhardwaj on 14/02/25.
//

import Foundation
//
//  VerifiedEmailView.swift
//  Team7test
//
//  Created by Hardik Bhardwaj on 14/02/25.
//

import Foundation
import SwiftUI

struct VerifiedEmailView: View {
    let email: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Hi")
                .font(.largeTitle)
                .fontWeight(.bold)
                
            Text(email)
                .font(.title2)
                .foregroundColor(.blue)
        }
        .padding()
    }
}

struct VerifiedEmailView_Previews: PreviewProvider {
    static var previews: some View {
        VerifiedEmailView(email: "example@mail.com")
    }
}
