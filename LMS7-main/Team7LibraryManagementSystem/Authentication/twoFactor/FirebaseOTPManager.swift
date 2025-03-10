//
//  FirebaseManager.swift
//  Team7LMS
//
//  Created by Hardik Bhardwaj on 14/02/25.
//


import Foundation
import FirebaseFirestore
import SwiftSMTP

class FirebaseManager {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()

    /// Generates a 6-digit OTP, stores it in Firestore, and sends it via email using SMTP
    func generateAndSendOTP(email: String, completion: @escaping (Bool, String) -> Void) {
        let otp = String(format: "%06d", Int.random(in: 100000...999999))
        let expirationTime = Date().addingTimeInterval(300) // 5 minutes

        let otpData: [String: Any] = [
            "otp": otp,
            "expirationTime": Timestamp(date: expirationTime)
        ]

        // Store OTP in Firestore
        db.collection("otp_codes").document(email).setData(otpData) { error in
            if let error = error {
                completion(false, "Failed to store OTP: \(error.localizedDescription)")
            } else {
                // Send OTP Email using SMTP
                self.sendEmail(to: email, otp: otp) { success, response in
                    completion(success, response)
                }
            }
        }
    }

    /// Sends an email via SMTP
    private func sendEmail(to email: String, otp: String, completion: @escaping (Bool, String) -> Void) {
        let smtp = SMTP(
            hostname: "smtp.gmail.com",  // Change this for Outlook, Yahoo, etc.
            email: "rakshitpanjeta23@gmail.com",  // Replace with your sender email
            password: "figyutdbxwtkzjun", // Use App Password (not Gmail password)
            port: 465, // Use 587 for TLS
            tlsMode: .requireTLS
        )

        let from = Mail.User(name: "Team 7", email: "rakshitpanjeta23@gmail.com")
        let to = Mail.User(name: "User", email: email)

        let mail = Mail(
            from: from,
            to: [to],
            subject: "Your OTP Code",
            text: "Your OTP is: \(otp). It is valid for 5 minutes."
        )

        smtp.send(mail) { error in
            if let error = error {
                completion(false, "Error sending email: \(error.localizedDescription)")
            } else {
                completion(true, "OTP sent successfully to \(email)")
            }
        }
    }

    /// Verifies OTP from Firestore
    func verifyOTP(email: String, enteredOTP: String, completion: @escaping (Bool, String) -> Void) {
        let docRef = db.collection("otp_codes").document(email)

        docRef.getDocument { (document, error) in
            if let error = error {
                completion(false, "Error fetching OTP: \(error.localizedDescription)")
                return
            }

            guard let document = document, document.exists,
                  let data = document.data(),
                  let storedOTP = data["otp"] as? String,
                  let expirationTimestamp = data["expirationTime"] as? Timestamp else {
                completion(false, "Invalid or expired OTP")
                return
            }

            if enteredOTP == storedOTP && expirationTimestamp.dateValue() > Date() {
                docRef.delete { _ in completion(true, "OTP Verified!") }
            } else {
                completion(false, "Incorrect or expired OTP")
            }
        }
    }
}