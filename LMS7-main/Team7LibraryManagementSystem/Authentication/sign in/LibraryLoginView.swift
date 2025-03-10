import SwiftUI

struct LibraryLoginView: View {
//    @EnvironmentObject var authViewModel: AuthViewModel
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // App Icon
                Image(systemName: "book.closed")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // App Title
                Text("Library Management System")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                // Admin Login
                NavigationLink(destination: FirebaseAuthView(userRole: "Admin")) {
                    LoginOptionRow(title: "Admin", subtitle: "Login to your account")
                }
                .padding(.horizontal)
                
                // Librarian Login
                NavigationLink(destination: FirebaseAuthView(userRole: "Librarian")) {
                    LoginOptionRow(title: "Librarian", subtitle: "Login to your account")
                }
                .padding(.horizontal)
                
                // User Signup
                NavigationLink(destination: FirebaseAuthView(userRole: "user")) {
                    LoginOptionRow(
                        title: "User",
                        subtitle: "Login to your account"
                        
                    )
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
        }
    }
}

struct LoginOptionRow: View {
    let title: String
    let subtitle: String
    var iconName: String = "person.circle"
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
