//
//  LoginDataModel.swift
//  fyle
//
//  Created by admin41 on 16/11/24.
//



// Array of users for validation


import Foundation

// Codable User model
struct AppUser: Codable {
    let fullName: String
    let email: String
    let phoneNumber: String
    let password: String
}

// Global users array
var users: [AppUser] = []
/*var users = [
    User(fullName: "123", email: "123", phoneNumber: "123", password: "123"),
    User(fullName: "Rosemarry", email: "rosemarry", phoneNumber: "9876543210", password: "2003"),
    User(fullName: "Shreeraj", email: "shreeraj", phoneNumber: "9876543211", password: "2003"),
    User(fullName: "Deeptanshu", email: "deeptanshu", phoneNumber: "9876543212", password: "2003"),
    // Add more users as needed
]*/

// Load users from UserDefaults
func loadUsers() {
    let decoder = JSONDecoder()
    if let savedData = UserDefaults.standard.data(forKey: "users"),
       let decodedUsers = try? decoder.decode([AppUser].self, from: savedData) {
        users = decodedUsers
    }
}

// Save users to UserDefaults
func saveUsers() {
    let encoder = JSONEncoder()
    if let encodedData = try? encoder.encode(users) {
        UserDefaults.standard.set(encodedData, forKey: "users")
    }
}

