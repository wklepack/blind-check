//
//  DataManager.swift
//  BlindCheck
//
//  Created by Oleksii Ratiiev on 03.12.2025.
//

import Foundation

class DataManager {
    static let shared = DataManager()
    
    private let markersKey = "SavedMarkers"
    private let validationResultsKey = "SavedValidationResults"
    
    private init() {}
    
    // MARK: - Markers
    
    func saveMarkers(_ markers: [UUID: MarkerData]) {
        let markerArray = Array(markers.values)
        if let encoded = try? JSONEncoder().encode(markerArray) {
            UserDefaults.standard.set(encoded, forKey: markersKey)
        }
    }
    
    func loadMarkers() -> [UUID: MarkerData]? {
        guard let data = UserDefaults.standard.data(forKey: markersKey),
              let markerArray = try? JSONDecoder().decode([MarkerData].self, from: data) else {
            return nil
        }
        
        var markers: [UUID: MarkerData] = [:]
        for marker in markerArray {
            markers[marker.id] = marker
        }
        return markers
    }
    
    func deleteMarkers() {
        UserDefaults.standard.removeObject(forKey: markersKey)
    }
    
    // MARK: - Validation Results (Session only - not persisted)
    
    func clearAllData() {
        UserDefaults.standard.removeObject(forKey: markersKey)
        UserDefaults.standard.removeObject(forKey: validationResultsKey)
    }
    
    // MARK: - Export
    
    func exportToJSON(markers: [UUID: MarkerData], validationResults: [UUID: ValidationResult]) -> String? {
        struct ExportData: Codable {
            let markers: [MarkerData]
            let exportDate: Date
            let totalMarkers: Int
            let validatedMarkers: Int
        }
        
        let markerArray = Array(markers.values).sorted { m1, m2 in
            if m1.gridPosition.row == m2.gridPosition.row {
                return m1.gridPosition.column < m2.gridPosition.column
            }
            return m1.gridPosition.row < m2.gridPosition.row
        }
        
        let validatedCount = markerArray.filter { $0.isValidated }.count
        
        let exportData = ExportData(
            markers: markerArray,
            exportDate: Date(),
            totalMarkers: markerArray.count,
            validatedMarkers: validatedCount
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        if let jsonData = try? encoder.encode(exportData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        return nil
    }
    
    func importFromJSON(_ jsonString: String) -> [UUID: MarkerData]? {
        guard let jsonData = jsonString.data(using: .utf8),
              let markerArray = try? JSONDecoder().decode([MarkerData].self, from: jsonData) else {
            return nil
        }
        
        var markers: [UUID: MarkerData] = [:]
        for marker in markerArray {
            markers[marker.id] = marker
        }
        return markers
    }
}

// MARK: - Sample Data Generator

extension DataManager {
    /// Generate realistic cemetery marker data
    func generateSampleData(rows: Int = 5, columns: Int = 5) -> [UUID: MarkerData] {
        let firstNames = [
            "John", "Mary", "Robert", "Patricia", "Michael", "Jennifer", "William", "Linda",
            "David", "Barbara", "Richard", "Susan", "Joseph", "Jessica", "Thomas", "Sarah",
            "Charles", "Karen", "Christopher", "Nancy", "Daniel", "Lisa", "Matthew", "Betty",
            "Anthony", "Margaret", "Mark", "Sandra", "Donald", "Ashley", "Steven", "Kimberly",
            "Paul", "Emily", "Andrew", "Donna", "Joshua", "Michelle", "Kenneth", "Carol",
            "Kevin", "Amanda", "Brian", "Dorothy", "George", "Melissa", "Edward", "Deborah",
            "Ronald", "Stephanie"
        ]
        
        let lastNames = [
            "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
            "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson",
            "Thomas", "Taylor", "Moore", "Jackson", "Martin", "Lee", "Perez", "Thompson",
            "White", "Harris", "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson", "Walker",
            "Young", "Allen", "King", "Wright", "Scott", "Torres", "Nguyen", "Hill", "Flores",
            "Green", "Adams", "Nelson", "Baker", "Hall", "Rivera", "Campbell", "Mitchell",
            "Carter", "Roberts"
        ]
        
        var markers: [UUID: MarkerData] = [:]
        var nameIndex = 0
        
        for row in 0..<rows {
            for col in 0..<columns {
                let firstName = firstNames[nameIndex % firstNames.count]
                let lastName = lastNames[(nameIndex / firstNames.count) % lastNames.count]
                let fullName = "\(firstName) \(lastName)"
                
                let marker = MarkerData(
                    name: fullName,
                    gridPosition: GridPosition(row: row, column: col)
                )
                
                markers[marker.id] = marker
                nameIndex += 1
            }
        }
        
        return markers
    }
    
    /// Generate test data with some pre-validated markers
    func generateTestData() -> [UUID: MarkerData] {
        var markers = generateSampleData(rows: 5, columns: 5)
        
        // Pre-validate some markers for testing
        let validationPositions = [
            GridPosition(row: 2, column: 2),
            GridPosition(row: 1, column: 1),
            GridPosition(row: 3, column: 3)
        ]
        
        for (id, var marker) in markers {
            if validationPositions.contains(marker.gridPosition) {
                marker.isValidated = true
                marker.validationDate = Date().addingTimeInterval(-Double.random(in: 3600...86400))
                marker.scannedText = marker.name
                markers[id] = marker
            }
        }
        
        return markers
    }
}
