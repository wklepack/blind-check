//
//  MarkerData.swift
//  BlindCheck
//
//  Created by Oleksii Ratiiev on 03.12.2025.
//

import Foundation
import CoreLocation

/// Represents a cemetery marker/grave location
struct MarkerData: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let gridPosition: GridPosition
    var isValidated: Bool
    var validationDate: Date?
    var validationNotes: String?
    var scannedText: String?
    
    init(id: UUID = UUID(), 
         name: String, 
         gridPosition: GridPosition, 
         isValidated: Bool = false,
         validationDate: Date? = nil,
         validationNotes: String? = nil,
         scannedText: String? = nil) {
        self.id = id
        self.name = name
        self.gridPosition = gridPosition
        self.isValidated = isValidated
        self.validationDate = validationDate
        self.validationNotes = validationNotes
        self.scannedText = scannedText
    }
}

/// Grid position in the cemetery (row, column)
struct GridPosition: Codable, Equatable, Hashable {
    let row: Int
    let column: Int
    
    /// Relative position description
    func relationTo(_ other: GridPosition) -> String {
        let rowDiff = row - other.row
        let colDiff = column - other.column
        
        var position = ""
        if rowDiff < 0 {
            position += "Top"
        } else if rowDiff > 0 {
            position += "Bottom"
        }
        
        if colDiff < 0 {
            position += position.isEmpty ? "Left" : " Left"
        } else if colDiff > 0 {
            position += position.isEmpty ? "Right" : " Right"
        }
        
        return position.isEmpty ? "Center" : position
    }
}

/// Represents a 3x3 grid of markers centered around a target marker
struct MarkerGrid {
    let centerPosition: GridPosition
    var markers: [GridPosition: MarkerData]
    
    /// Get marker at relative position (-1 to 1 for row/col)
    func marker(at relativeRow: Int, relativeCol: Int) -> MarkerData? {
        let position = GridPosition(
            row: centerPosition.row + relativeRow,
            column: centerPosition.column + relativeCol
        )
        return markers[position]
    }
    
    /// Get all 9 positions in the 3x3 grid
    func allPositions() -> [GridPosition] {
        var positions: [GridPosition] = []
        for row in -1...1 {
            for col in -1...1 {
                positions.append(GridPosition(
                    row: centerPosition.row + row,
                    column: centerPosition.column + col
                ))
            }
        }
        return positions
    }
}

/// Validation result for a marker
struct ValidationResult {
    let marker: MarkerData
    let isValid: Bool
    let confidence: Double
    let discrepancies: [String]
    let timestamp: Date
    
    var status: ValidationStatus {
        if isValid && confidence > 0.8 {
            return .valid
        } else if isValid && confidence > 0.5 {
            return .partialMatch
        } else {
            return .invalid
        }
    }
}

enum ValidationStatus {
    case valid
    case partialMatch
    case invalid
    case notScanned
}
