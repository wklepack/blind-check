//
//  GridView.swift
//  BlindCheck
//
//  Created by Oleksii Ratiiev on 03.12.2025.
//

import SwiftUI

struct GridView: View {
    @ObservedObject var viewModel: BlindCheckViewModel
    @State private var markerToScan: MarkerData?
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
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
                        
                        // 3x3 Grid - takes at least half the screen
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
                                            markerToScan = marker
                                            print("🔥 markerToScan set to: \(markerToScan?.name ?? "nil")")
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
                .frame(minHeight: geometry.size.height * 0.5)
                
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
            }
        }
        .sheet(item: $markerToScan) { marker in
            CameraScanView(
                marker: marker,
                viewModel: self.viewModel,
                isPresented: Binding(
                    get: { self.markerToScan != nil },
                    set: { if !$0 { self.markerToScan = nil } }
                )
            )
            .onAppear {
                print("🔥 SHEET PRESENTED for marker: \(marker.name)")
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
    
    // Checkbox states
    @State private var memorialPlacement: String = ""
    @State private var agreesWithAdjacentInterments: String = ""
    @State private var agreesWithLotPins: String = ""
    @State private var agreesWithPermanentRecords: String = ""
    @State private var agreesWithIntermentOrder: String = ""
    @State private var agreesWithDisintermentOrder: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Interment Space Details")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    DetailRow(label: "Name", value: marker.name)
                    
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
            
            // Checkpoint questions
            VStack(alignment: .leading, spacing: 16) {
                Divider()
                
                CheckboxGroup(
                    question: "1. Are memorials placed at the head or the foot?",
                    options: ["Head", "Foot", "N/A (above ground)"],
                    selection: $memorialPlacement
                )
                
                CheckboxGroup(
                    question: "2. Agrees with Adjacent Interments (from memorials):",
                    options: ["Yes", "No", "N/A (none nearby)"],
                    selection: $agreesWithAdjacentInterments
                )
                
                CheckboxGroup(
                    question: "3. Agrees with 2 numbered lot pins:",
                    options: ["Yes", "No", "N/A (above ground)"],
                    selection: $agreesWithLotPins
                )
                
                CheckboxGroup(
                    question: "4. Agrees with Permanent Records:",
                    options: ["Yes", "No"],
                    selection: $agreesWithPermanentRecords
                )
                
                CheckboxGroup(
                    question: "5. Agrees with Interment Order & Authorization:",
                    options: ["Yes", "No", "N/A (Preneed)"],
                    selection: $agreesWithIntermentOrder
                )
                
                CheckboxGroup(
                    question: "6. Agrees with Disinterment Order & Authorization:",
                    options: ["Yes", "No", "N/A (No disinterment)"],
                    selection: $agreesWithDisintermentOrder
                )
            }
            .padding(.top)
            
            Spacer()
            
            // Bottom action buttons
            HStack(spacing: 12) {
                Button(action: {
                    onValidate(true, nil)
                }) {
                    Text("Verify")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    showingValidationSheet = true
                }) {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray5))
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

// MARK: - CheckboxGroup Component
struct CheckboxGroup: View {
    let question: String
    let options: [String]
    @Binding var selection: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack(spacing: 16) {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        selection = selection == option ? "" : option
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: selection == option ? "checkmark.square.fill" : "square")
                                .foregroundColor(selection == option ? .blue : .gray)
                                .font(.system(size: 16))
                            
                            Text(option)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}
