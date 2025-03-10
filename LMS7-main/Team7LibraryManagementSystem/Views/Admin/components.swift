//
//  SwiftUIView.swift
//  LibraryManagement
//
//  Created by Taksh Joshi on 16/02/25.
//

import SwiftUI

struct SectionView: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct TextFieldView: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
            TextField(placeholder, text: $text)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct SecureFieldView: View {
    let placeholder: String
    @Binding var text: String
    @State var isVisible: Bool = false  // Default state variable

    var body: some View {
        HStack {
            if isVisible {
                TextField(placeholder, text: $text)
            } else {
                SecureField(placeholder, text: $text)
            }
            
            Button(action: {
                isVisible.toggle()
            }) {
                Image(systemName: isVisible ? "eye.fill" : "eye.slash.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}
struct DropdownView: View {
    let title: String
    let options: [String]
    let action: (String) -> Void
    
    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) {
                    action(option)
                }
            }
        } label: {
            HStack {
                Text(title)
                    .foregroundColor(title == "Select Library" || title == "Admin" ? .gray : .primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
}

struct ToggleView: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct SectionViewSetting: View {
    var title: String
    
    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.footnote)
                .foregroundColor(.gray)
                .bold()
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct SettingsRow: View {
    var icon: String
    var title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct ToggleRow: View {
    var icon: String
    var title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct ExportRow: View {
    var icon: String
    var title: String
    var description: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text(title)
                        .bold()
                    Text(description)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            Button(action: {}) {
                Text("Export")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}
struct inputField2: View {
    var title: String
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default  // Optional, default keyboard

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote)
                .foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(10)
                .keyboardType(keyboardType)
        }
    }
}
struct LibrariansStatCard: View {
    var icon: String
    var title: String
    var subtitle: String
    var isHighlighted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.system(size: 24))
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHighlighted ? Color.blue.opacity(0.1) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHighlighted ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}


struct StatCard: View {
    var icon: String
    var title: String
    var subtitle: String
    var color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            // Title
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            // Subtitle
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(2)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// Preview
#Preview {
    HStack {
        StatCard(
            icon: "book.fill",
            title: "2,456",
            subtitle: "Total Books",
            color: .blue
        )
        StatCard(
            icon: "person.fill",
            title: "150",
            subtitle: "Active Users",
            color: .green
        )
    }
    .padding()
}
struct InputField2: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}
