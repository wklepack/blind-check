//
//  CameraScanView.swift
//  BlindCheck
//
//  Created by Oleksii Ratiiev on 03.12.2025.
//

import SwiftUI
import AVFoundation
import Vision

struct CameraScanView: View {
    let marker: MarkerData
    @ObservedObject var viewModel: BlindCheckViewModel
    @Binding var isPresented: Bool
    
    @State private var scannedText: String = ""
    @State private var isScanning = false
    @State private var isTextMatched = false
    @State private var showingManualValidation = false
    @State private var matchPercentage: Double = 0.0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Header info
                VStack(spacing: 8) {
                    Text("Scanning: \(marker.name)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)
                
                // Live camera preview with text scanning
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black)
                        .frame(height: 250)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isTextMatched ? Color.green : Color.blue, lineWidth: 2)
                        )
                    
                    // Live camera preview
                    LiveCameraView(
                        onTextDetected: { detectedText in
                            let cleanedText = cleanDetectedText(detectedText)
                            if cleanedText != scannedText && !cleanedText.isEmpty {
                                scannedText = cleanedText
                                checkTextMatch(cleanedText)
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .frame(height: 230)
                    
                    // Success indicator overlay
                    if isTextMatched {
                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                            Text("MATCH!")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                // Detected text display - Always visible with better space
                VStack(spacing: 8) {
                    HStack {
                        Text("Detected Text:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        if !scannedText.isEmpty {
                            Text("\(Int(matchPercentage))% match")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(matchPercentage >= 70 ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                                .foregroundColor(matchPercentage >= 70 ? .green : .orange)
                                .cornerRadius(4)
                        }
                    }
                    
                    ScrollView {
                        if scannedText.isEmpty {
                            Text("Point camera at text...")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        } else {
                            Text(scannedText)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                    }
                    .frame(height: 120)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Action buttons
                VStack(spacing: 12) {
                    if !scannedText.isEmpty {
                        HStack(spacing: 12) {
                            if isTextMatched || matchPercentage >= 70 {
                                Button("✓ Mark Valid") {
                                    viewModel.manualValidation(
                                        for: marker,
                                        isValid: true,
                                        notes: "Auto-matched text: \(scannedText)",
                                        scannedText: scannedText
                                    )
                                    isPresented = false
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .font(.headline)
                            }
                            
                            Button("✗ Mark Invalid") {
                                showingManualValidation = true
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .font(.headline)
                        }
                    } else {
                        Text("Move camera closer to text for better detection")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Text Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showingManualValidation) {
                ManualValidationView(
                    marker: marker,
                    scannedText: scannedText,
                    onComplete: { isValid, notes in
                        viewModel.manualValidation(
                            for: marker,
                            isValid: isValid,
                            notes: notes,
                            scannedText: scannedText
                        )
                        isPresented = false
                    }
                )
            }
        }
    }
    
    // MARK: - Text Cleaning
    private func cleanDetectedText(_ text: String) -> String {
        // Remove common OCR artifacts and clean up text
        let cleaned = text
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "{", with: "")
            .replacingOccurrences(of: "}", with: "")
            .replacingOccurrences(of: "|", with: "I")
            .replacingOccurrences(of: "0", with: "O") // Common mistake: 0 vs O
            .replacingOccurrences(of: "5", with: "S") // Common mistake: 5 vs S
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Text Matching
    private func checkTextMatch(_ scannedText: String) {
        let markerName = marker.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let scannedLower = scannedText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Multiple matching strategies
        let containsMatch = scannedLower.contains(markerName) || markerName.contains(scannedLower)
        let wordSimilarity = calculateWordSimilarity(markerName, scannedLower)
        let editDistance = calculateEditDistanceSimilarity(markerName, scannedLower)
        
        // Use the best similarity score
        matchPercentage = max(wordSimilarity, editDistance) * 100
        
        // More flexible matching criteria
        isTextMatched = containsMatch || matchPercentage >= 60
        
        print("🔍 Marker: '\(markerName)'")
        print("📱 Scanned: '\(scannedLower)'")
        print("✅ Contains: \(containsMatch), Word: \(Int(wordSimilarity * 100))%, Edit: \(Int(editDistance * 100))%")
        print("🎯 Final: \(isTextMatched), Score: \(Int(matchPercentage))%")
        print("---")
    }
    
    private func calculateWordSimilarity(_ str1: String, _ str2: String) -> Double {
        let words1 = Set(str1.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty })
        let words2 = Set(str2.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty })
        
        guard !words1.isEmpty && !words2.isEmpty else { return 0 }
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        return Double(intersection.count) / Double(union.count)
    }
    
    private func calculateEditDistanceSimilarity(_ str1: String, _ str2: String) -> Double {
        let maxLength = max(str1.count, str2.count)
        guard maxLength > 0 else { return 1.0 }
        
        let distance = levenshteinDistance(str1, str2)
        return 1.0 - (Double(distance) / Double(maxLength))
    }
    
    private func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
        let s1 = Array(str1)
        let s2 = Array(str2)
        
        var matrix = Array(repeating: Array(repeating: 0, count: s2.count + 1), count: s1.count + 1)
        
        for i in 0...s1.count {
            matrix[i][0] = i
        }
        
        for j in 0...s2.count {
            matrix[0][j] = j
        }
        
        for i in 1...s1.count {
            for j in 1...s2.count {
                let cost = s1[i-1] == s2[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,      // deletion
                    matrix[i][j-1] + 1,      // insertion
                    matrix[i-1][j-1] + cost  // substitution
                )
            }
        }
        
        return matrix[s1.count][s2.count]
    }
}



// MARK: - Live Camera View with Real-time Text Detection
struct LiveCameraView: UIViewRepresentable {
    let onTextDetected: (String) -> Void
    
    func makeUIView(context: Context) -> CameraPreviewView {
        let previewView = CameraPreviewView()
        previewView.onTextDetected = onTextDetected
        return previewView
    }
    
    func updateUIView(_ uiView: CameraPreviewView, context: Context) {}
}

class CameraPreviewView: UIView {
    var onTextDetected: ((String) -> Void)?
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var videoDataOutput: AVCaptureVideoDataOutput!
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let textDetectionQueue = DispatchQueue(label: "text.detection.queue")
    private var lastTextDetectionTime: Date = Date()
    private let textDetectionInterval: TimeInterval = 1.0 // Detect text every 1 second
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCamera()
    }
    
    private func setupCamera() {
        sessionQueue.async { [weak self] in
            self?.setupCaptureSession()
        }
    }
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Unable to access back camera")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.setSampleBufferDelegate(self, queue: textDetectionQueue)
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            
            if captureSession.canAddOutput(videoDataOutput) {
                captureSession.addOutput(videoDataOutput)
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.setupPreviewLayer()
                self?.captureSession.startRunning()
            }
            
        } catch {
            print("Error setting up camera: \(error)")
        }
    }
    
    private func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = bounds
        layer.addSublayer(previewLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
    
    deinit {
        captureSession?.stopRunning()
    }
}

extension CameraPreviewView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Throttle text detection to avoid too frequent processing
        let now = Date()
        guard now.timeIntervalSince(lastTextDetectionTime) >= textDetectionInterval else {
            return
        }
        lastTextDetectionTime = now
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation],
                  error == nil else {
                return
            }
            
            // Get multiple candidates and filter for quality
            let recognizedStrings = observations.compactMap { observation in
                // Get top 3 candidates and pick the best one
                let candidates = observation.topCandidates(3)
                return candidates.first { candidate in
                    // Filter out very short strings and strings with too many special characters
                    candidate.string.count >= 2 && 
                    candidate.confidence > 0.5 &&
                    candidate.string.rangeOfCharacter(from: .alphanumerics) != nil
                }?.string
            }
            
            // Sort by length (longer strings are usually more reliable)
            let sortedStrings = recognizedStrings.sorted { $0.count > $1.count }
            let fullText = sortedStrings.joined(separator: " ")
            
            if !fullText.isEmpty {
                DispatchQueue.main.async {
                    self?.onTextDetected?(fullText)
                }
            }
        }
        
        // Improved settings for better text recognition
        request.recognitionLevel = .accurate // Use accurate for better quality
        request.usesLanguageCorrection = true
        request.minimumTextHeight = 0.03 // Ignore very small text
        request.customWords = [] // Could add common cemetery name patterns
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
}

// MARK: - Manual Validation View
struct ManualValidationView: View {
    let marker: MarkerData
    let scannedText: String
    let onComplete: (Bool, String) -> Void
    
    @State private var notes: String = ""
    @State private var selectedReason = "Text doesn't match"
    @Environment(\.dismiss) var dismiss
    
    let invalidReasons = [
        "Text doesn't match",
        "Text is unclear/unreadable",
        "Wrong marker location",
        "Marker is damaged",
        "Other reason"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Marker Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Expected: \(marker.name)")
                            .font(.headline)
                        
                        if !scannedText.isEmpty {
                            Text("Detected: \(scannedText)")
                                .font(.body)
                                .foregroundColor(.secondary)
                        } else {
                            Text("No text detected")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Validation") {
                    Picker("Reason for marking invalid", selection: $selectedReason) {
                        ForEach(invalidReasons, id: \.self) { reason in
                            Text(reason).tag(reason)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Additional Notes") {
                    TextField("Enter any additional comments...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button("Mark as Valid") {
                        onComplete(true, "Manual validation: Valid")
                    }
                    .foregroundColor(.green)
                    
                    Button("Mark as Invalid") {
                        let finalNotes = selectedReason + (notes.isEmpty ? "" : " - \(notes)")
                        onComplete(false, finalNotes)
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Manual Validation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
