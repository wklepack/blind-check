//
//  BlindCheckViewModel.swift
//  BlindCheck
//
//  Created by Oleksii Ratiiev on 03.12.2025.
//

import Foundation
import SwiftUI
import Combine
import Vision

@MainActor
class BlindCheckViewModel: ObservableObject {
    @Published var currentGrid: MarkerGrid?
    @Published var selectedMarker: MarkerData?
    @Published var allMarkers: [UUID: MarkerData] = [:]
    @Published var validationResults: [UUID: ValidationResult] = [:]
    @Published var isScanning = false
    @Published var scanningProgress: Double = 0.0
    @Published var errorMessage: String?
    
    // Text recognition
    private var textRecognitionRequest: VNRecognizeTextRequest?
    
    init() {
        setupTextRecognition()
        loadData()
    }
    
    // MARK: - Persistence
    
    private func loadData() {
        // Try to load saved data first
        if let savedMarkers = DataManager.shared.loadMarkers() {
            allMarkers = savedMarkers
            // Set initial grid to center position (2, 2)
            selectMarkerAt(GridPosition(row: 2, column: 2))
        } else {
            // Load sample data if no saved data
            loadSampleData()
        }
    }
    
    private func saveData() {
        DataManager.shared.saveMarkers(allMarkers)
    }
    
    // MARK: - Setup
    
    private func setupTextRecognition() {
        textRecognitionRequest = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                Task { @MainActor in
                    self.errorMessage = "Text recognition error: \(error.localizedDescription)"
                }
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return
            }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            Task { @MainActor in
                self.processRecognizedText(recognizedStrings)
            }
        }
        
        textRecognitionRequest?.recognitionLevel = .accurate
        textRecognitionRequest?.usesLanguageCorrection = true
    }
    
    // MARK: - Data Management
    
    func loadSampleData() {
        allMarkers = DataManager.shared.generateSampleData(rows: 5, columns: 5)
        
        // Set initial grid to center position (2, 2)
        selectMarkerAt(GridPosition(row: 2, column: 2))
        
        // Save the new data
        saveData()
    }
    
    func selectMarkerAt(_ position: GridPosition) {
        let grid = buildGrid(centerPosition: position)
        currentGrid = grid
        selectedMarker = grid.markers[position]
    }
    
    private func buildGrid(centerPosition: GridPosition) -> MarkerGrid {
        var gridMarkers: [GridPosition: MarkerData] = [:]
        
        for marker in allMarkers.values {
            let rowDiff = abs(marker.gridPosition.row - centerPosition.row)
            let colDiff = abs(marker.gridPosition.column - centerPosition.column)
            
            if rowDiff <= 1 && colDiff <= 1 {
                gridMarkers[marker.gridPosition] = marker
            }
        }
        
        return MarkerGrid(centerPosition: centerPosition, markers: gridMarkers)
    }
    
    // MARK: - Text Recognition
    
    func processRecognizedText(_ texts: [String]) {
        guard let currentGrid = currentGrid,
              let centerMarker = selectedMarker else {
            return
        }
        
        // Try to match recognized text with markers in the grid
        let allTexts = texts.joined(separator: " ").lowercased()
        
        var updatedMarkers = currentGrid.markers
        var foundMatches: [GridPosition: String] = [:]
        
        for (position, marker) in currentGrid.markers {
            let markerName = marker.name.lowercased()
            
            // Check if marker name appears in recognized text
            if allTexts.contains(markerName) {
                foundMatches[position] = marker.name
                
                // Update marker with scanned text
                var updatedMarker = marker
                updatedMarker.scannedText = marker.name
                updatedMarkers[position] = updatedMarker
                allMarkers[marker.id] = updatedMarker
            }
        }
        
        // Update current grid
        self.currentGrid = MarkerGrid(centerPosition: currentGrid.centerPosition, markers: updatedMarkers)
        
        // Auto-validate if enough matches found
        if foundMatches.count >= 3 {
            validateCurrentGrid()
        }
    }
    
    // MARK: - Validation
    
    func startScanning() {
        isScanning = true
        scanningProgress = 0.0
        errorMessage = nil
        
        // Simulate scanning progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            Task { @MainActor in
                self.scanningProgress += 0.05
                
                if self.scanningProgress >= 1.0 {
                    timer.invalidate()
                    self.validateCurrentGrid()
                    self.isScanning = false
                }
            }
        }
    }
    
    func validateCurrentGrid() {
        guard let grid = currentGrid else { return }
        
        for (position, marker) in grid.markers {
            validateMarker(marker)
        }
    }
    
    func validateMarker(_ marker: MarkerData) {
        // Calculate confidence based on whether text was scanned
        let confidence = marker.scannedText != nil ? 0.9 : 0.0
        let isValid = marker.scannedText?.lowercased() == marker.name.lowercased()
        
        var discrepancies: [String] = []
        if !isValid && marker.scannedText != nil {
            discrepancies.append("Name mismatch: Expected '\(marker.name)', found '\(marker.scannedText ?? "unknown")'")
        }
        
        let result = ValidationResult(
            marker: marker,
            isValid: isValid,
            confidence: confidence,
            discrepancies: discrepancies,
            timestamp: Date()
        )
        
        validationResults[marker.id] = result
        
        // Update marker validation status
        var updatedMarker = marker
        updatedMarker.isValidated = isValid
        updatedMarker.validationDate = Date()
        allMarkers[marker.id] = updatedMarker
        
        // Update current grid
        if var grid = currentGrid {
            grid.markers[marker.gridPosition] = updatedMarker
            currentGrid = grid
        }
        
        // Save changes
        saveData()
    }
    
    func manualValidation(for marker: MarkerData, isValid: Bool, notes: String?, scannedText: String? = nil) {
        var updatedMarker = marker
        updatedMarker.isValidated = isValid
        updatedMarker.validationDate = Date()
        updatedMarker.validationNotes = notes
        
        // Update scanned text if provided, otherwise default to name if valid
        if let text = scannedText {
            updatedMarker.scannedText = text
        } else if marker.scannedText == nil && isValid {
            updatedMarker.scannedText = marker.name
        }
        
        allMarkers[marker.id] = updatedMarker
        
        let result = ValidationResult(
            marker: updatedMarker,
            isValid: isValid,
            confidence: 1.0,
            discrepancies: isValid ? [] : ["Manual validation marked as invalid"],
            timestamp: Date()
        )
        
        validationResults[marker.id] = result
        
        // Rebuild and update current grid to refresh UI
        if let centerPosition = currentGrid?.centerPosition {
            let refreshedGrid = buildGrid(centerPosition: centerPosition)
            currentGrid = refreshedGrid
            selectedMarker = refreshedGrid.markers[centerPosition]
        }
        
        // Save changes
        saveData()
    }
    
    // MARK: - Export
    
    func exportValidationReport() -> String {
        var report = "Cemetery Blind Check Validation Report\n"
        report += "Generated: \(Date().formatted())\n"
        report += "=" .repeating(50) + "\n\n"
        
        let validatedMarkers = allMarkers.values.filter { $0.isValidated }
        report += "Validated Markers: \(validatedMarkers.count) / \(allMarkers.count)\n\n"
        
        for marker in validatedMarkers.sorted(by: { $0.gridPosition.row < $1.gridPosition.row || 
                                                      ($0.gridPosition.row == $1.gridPosition.row && 
                                                       $0.gridPosition.column < $1.gridPosition.column) }) {
            report += "Position: Row \(marker.gridPosition.row), Column \(marker.gridPosition.column)\n"
            report += "Name: \(marker.name)\n"
            
            if let result = validationResults[marker.id] {
                report += "Status: \(result.status)\n"
                report += "Confidence: \(Int(result.confidence * 100))%\n"
                
                if !result.discrepancies.isEmpty {
                    report += "Discrepancies:\n"
                    for discrepancy in result.discrepancies {
                        report += "  - \(discrepancy)\n"
                    }
                }
            }
            
            if let notes = marker.validationNotes {
                report += "Notes: \(notes)\n"
            }
            
            report += "\n"
        }
        
        return report
    }
}

extension String {
    func repeating(_ count: Int) -> String {
        return String(repeating: self, count: count)
    }
}
