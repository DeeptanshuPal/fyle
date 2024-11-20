//
//  FileManagerService.swift
//  fyle
//
//  Created by Sana Sreeraj on 17/11/24.
//

import Foundation

class FileManagerService {
    static let shared = FileManagerService()

    private init() {}

    // Save the file to the local documents directory
    func saveFile(data: Data, fileName: String) -> URL? {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Ensure uniqueness by appending UUID or timestamp
        let uniqueFileName = "\(UUID().uuidString)_\(fileName)"
        let fileURL = documentsURL.appendingPathComponent(uniqueFileName)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving file: \(error)")
            return nil
        }
    }


    // Load the file from the provided URL
    func loadFile(from url: URL) -> Data? {
        do {
            return try Data(contentsOf: url)  // Return the data read from the URL
        } catch {
            print("Error loading file: \(error)")  // Print error if loading fails
            return nil
        }
    }

    // Delete the file at the provided URL
    func deleteFile(at url: URL) {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: url)  // Try to remove the file
        } catch {
            print("Error deleting file: \(error)")  // Print error if deleting fails
        }
    }

    // Check if a file exists at the specified URL
    func fileExists(at url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }
}
