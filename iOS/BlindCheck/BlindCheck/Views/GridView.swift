//
//  GridView.swift
//  BlindCheck
//
//  Created by Oleksii Ratiiev on 03.12.2025.
//

import SwiftUI

struct GridView: View {
    @ObservedObject var viewModel: BlindCheckViewModel
    @State private var selectedMarkerForScanning: MarkerData?
    @State private var showingCamera = false
    
    var body: some View {
        VStack(spacing: 0) {
            if let grid = viewModel.currentGrid {
                // Instructions banner
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Tap any surrounding marker to scan and verify")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                
                // 3x3 Grid
                VStack(spacing: 2) {
                    ForEach(-1...1, id: \.self) { row in
                        HStack(spacing: 2) {
                            ForEach(-1...1, id: \.self) { col in
                                let position = GridPosition(
                                    row: grid.centerPosition.row + row,
                                    column: grid.centerPosition.column + col
                                )
                                let isCenter = row == 0 && col == 0
                                
                                if let marker = grid.markers[position] {
                                    MarkerCell(
                                        marker: marker,
                                        isCenter: isCenter,
                                        validationStatus: validationStatus(for: marker)
                                    )
                                    .onTapGesture {
                                        // Only allow scanning non-center markers
                                        if !isCenter {
                                            print("🔥 TAP DETECTED on marker: \(marker.name)")
                                            selectedMarkerForScanning = marker
                                            showingCamera = true
                                            print("🔥 showingCamera set to: \(showingCamera)")
                                            print("🔥 selectedMarkerForScanning: \(selectedMarkerForScanning?.name ?? "nil")")
                                        } else {
                                            print("❌ Tap on center marker ignored")
                                        }
                                    }
                                } else {
                                    EmptyMarkerCell()
                                }
                            }
                        }
                    }
                }
                .padding()
                
                // Center marker details
                if let centerMarker = viewModel.selectedMarker {
                    MarkerDetailView(
                        marker: centerMarker,
                        validationResult: viewModel.validationResults[centerMarker.id],
                        onValidate: { isValid, notes in
                            viewModel.manualValidation(for: centerMarker, isValid: isValid, notes: notes)
                        }
                    )
                }
            } else {
                Text("No grid selected")
                    .foregroundColor(.gray)
                    .font(.headline)
            }
        }
        .sheet(isPresented: $showingCamera) {
            if let marker = selectedMarkerForScanning {
                CameraScanView(
                    marker: marker,
                    viewModel: viewModel,
                    isPresented: $showingCamera
                )
            } else {
                Text("No marker selected")
                    .font(.title)
                    .foregroundColor(.red)
            }
        }
    }
    
    private func validationStatus(for marker: MarkerData) -> ValidationStatus {
        if let result = viewModel.validationResults[marker.id] {
            return result.status
        }
        return marker.isValidated ? .valid : .notScanned
    }
}

struct MarkerCell: View {
    let marker: MarkerData
    let isCenter: Bool
    let validationStatus: ValidationStatus
    
    var body: some View {
        VStack(spacing: 4) {
            Text(marker.name)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
            
            Text("(\(marker.gridPosition.row),\(marker.gridPosition.column))")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            // Validation indicator
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            
            // Tap indicator for non-center cells
            if !isCenter {
                Image(systemName: "camera.fill")
                    .font(.caption2)
                    .foregroundColor(.blue.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(8)
        .background(cellBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(cellBorder, lineWidth: isCenter ? 3 : 1)
        )
    }
    
    private var cellBackground: Color {
        if isCenter {
            return Color.blue.opacity(0.2)
        } else {
            return Color.gray.opacity(0.1)
        }
    }
    
    private var cellBorder: Color {
        if isCenter {
            return Color.blue
        } else if validationStatus == .notScanned {
            return Color.orange.opacity(0.5)
        } else {
            return Color.clear
        }
    }
    
    private var statusColor: Color {
        switch validationStatus {
        case .valid:
            return .green
        case .partialMatch:
            return .orange
        case .invalid:
            return .red
        case .notScanned:
            return .gray
        }
    }
}

struct EmptyMarkerCell: View {
    var body: some View {
        VStack {
            Text("Empty")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct MarkerDetailView: View {
    let marker: MarkerData
    let validationResult: ValidationResult?
    let onValidate: (Bool, String?) -> Void
    
    @State private var showingValidationSheet = false
    @State private var validationNotes = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Marker Details")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    DetailRow(label: "Name", value: marker.name)
                    DetailRow(label: "Position", value: "Row \(marker.gridPosition.row), Column \(marker.gridPosition.column)")
                    
                    if let scannedText = marker.scannedText {
                        DetailRow(label: "Scanned", value: scannedText)
                    }
                    
                    if let result = validationResult {
                        DetailRow(label: "Status", value: statusText(result.status))
                        DetailRow(label: "Confidence", value: "\(Int(result.confidence * 100))%")
                        
                        if !result.discrepancies.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Discrepancies:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                ForEach(result.discrepancies, id: \.self) { discrepancy in
                                    Text("• \(discrepancy)")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    
                    if let notes = marker.validationNotes {
                        DetailRow(label: "Notes", value: notes)
                    }
                }
                
                Spacer()
            }
            
            // Validation buttons
            HStack(spacing: 12) {
                Button(action: {
                    onValidate(true, nil)
                }) {
                    Label("Mark Valid", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    showingValidationSheet = true
                }) {
                    Label("Mark Invalid", systemImage: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
        .padding()
        .sheet(isPresented: $showingValidationSheet) {
            ValidationNotesSheet(notes: $validationNotes, onSubmit: {
                onValidate(false, validationNotes)
                showingValidationSheet = false
                validationNotes = ""
            })
        }
    }
    
    private func statusText(_ status: ValidationStatus) -> String {
        switch status {
        case .valid: return "✓ Valid"
        case .partialMatch: return "⚠ Partial Match"
        case .invalid: return "✗ Invalid"
        case .notScanned: return "○ Not Scanned"
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text("\(label):")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct ValidationNotesSheet: View {
    @Binding var notes: String
    let onSubmit: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add validation notes")
                    .font(.headline)
                
                TextEditor(text: $notes)
                    .frame(height: 150)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                Button(action: onSubmit) {
                    Text("Submit")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Validation Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
