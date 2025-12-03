# BlindCheck - Cemetery Marker Validation App

## Overview

BlindCheck is an iOS application designed to validate cemetery marker placements through real-time camera scanning and OCR text recognition. The app helps cemetery staff confirm the correct physical location and boundaries of interment rights by scanning markers and comparing them against a database.

## Features

### 1. **3x3 Grid Visualization**
- Displays markers in a 3x3 grid centered around a selected marker
- Shows relative positions (top, bottom, left, right)
- Color-coded validation status indicators
- Grid position coordinates (row, column)

### 2. **Camera Scanning**
- Real-time camera preview with overlay grid
- Photo capture and OCR text recognition using Vision framework
- Automatic text detection from cemetery markers
- Visual feedback during scanning process

### 3. **Validation System**
- **Automatic Validation**: Matches scanned text with database entries
- **Manual Validation**: Mark markers as valid or invalid with notes
- **Validation Status Tracking**:
  - ✓ Valid (Green) - Confirmed correct
  - ⚠ Partial Match (Orange) - Some discrepancies
  - ✗ Invalid (Red) - Does not match expected
  - ○ Not Scanned (Gray) - Awaiting validation

### 4. **Data Management**
- Sample data with 25 markers in 5x5 grid
- Persistent validation records
- Validation timestamps and notes
- Export validation reports

### 5. **Three Main Tabs**

#### Grid Tab
- Interactive 3x3 grid view
- Marker details panel
- Quick validation buttons
- Position navigation

#### Scan Tab
- Live camera feed
- 3x3 overlay grid for alignment
- Capture and recognize text
- Real-time text detection display

#### Status Tab
- Overview statistics (Total, Validated, Pending)
- Complete marker list with validation status
- Sort by grid position
- Tap to navigate to marker in grid view

## Technical Architecture

### Models (`Models/MarkerData.swift`)
- **MarkerData**: Core data structure for cemetery markers
  - Name, grid position, validation status
  - Scanned text, validation date, notes
  
- **GridPosition**: Row/column coordinates
  - Relative position calculations
  
- **MarkerGrid**: 3x3 grid wrapper
  - Center position with surrounding markers
  
- **ValidationResult**: Validation outcome tracking
  - Confidence scores, discrepancies, timestamps

### ViewModels (`ViewModels/BlindCheckViewModel.swift`)
- **BlindCheckViewModel**: Main business logic
  - Grid management and navigation
  - Text recognition processing
  - Validation workflow
  - Data persistence
  - Report generation

### Views

#### `Views/MainView.swift`
- TabView coordinator
- Navigation structure
- Export functionality

#### `Views/GridView.swift`
- 3x3 grid visualization
- Marker cells with status indicators
- Marker detail panel
- Validation controls

#### `Views/CameraView.swift`
- Camera preview and controls
- Grid overlay for alignment
- Photo capture
- OCR text recognition
- **CameraViewModel**: AVFoundation camera management

## Usage Flow

### Initial Setup
1. App launches with sample data (5x5 grid, 25 markers)
2. Grid view shows center position (2,2) with surrounding markers
3. All markers start in "Not Scanned" status

### Scanning Workflow
1. Navigate to **Scan** tab
2. Position camera to view cemetery markers
3. Align markers with 3x3 overlay grid
4. Tap camera button to capture
5. App performs OCR text recognition
6. Recognized text is displayed and matched against database
7. Return to **Grid** tab to see updated validation status

### Validation Workflow
1. In **Grid** tab, view current marker details
2. Review scanned text vs. expected name
3. Options:
   - **Mark Valid**: Quick validation without notes
   - **Mark Invalid**: Add validation notes explaining discrepancies
4. Validation status updates immediately
5. Check **Status** tab for overview

### Export Report
1. Tap menu (⋯) in Grid tab
2. Select "Export Report"
3. View formatted validation report
4. Copy to clipboard or share

## Data Structure

### Sample Data Grid (5x5)
```
(0,0) John Smith      (0,1) Mary Johnson   (0,2) Robert Williams ...
(1,0) Jennifer Davis  (1,1) William Miller (1,2) Linda Wilson    ...
(2,0) Richard Anderson(2,1) Susan Thomas   (2,2) Joseph Jackson  ...
...
```

### Validation Record Format
```
Position: Row X, Column Y
Name: [Expected Name]
Status: Valid/Partial/Invalid
Confidence: XX%
Scanned: [Recognized Text]
Notes: [Optional validation notes]
Validation Date: [Timestamp]
```

## Technical Requirements

### iOS Version
- **Minimum**: iOS 15.0
- **Recommended**: iOS 16.0+

### Frameworks Used
- **SwiftUI**: UI framework
- **AVFoundation**: Camera capture
- **Vision**: OCR text recognition
- **Combine**: Reactive data flow

### Permissions Required
- **Camera Access**: Required for scanning markers
- **Photo Library**: Optional for saving validation photos

## Future Enhancements

### Planned Features
1. **GPS Integration**: Associate markers with geographic coordinates
2. **Photo Attachment**: Save photos with validation records
3. **Offline Mode**: Work without network connectivity
4. **Multi-user Sync**: Cloud synchronization for teams
5. **QR Code Support**: Scan QR codes on modern markers
6. **AR Overlay**: Augmented reality visualization of grid
7. **Batch Scanning**: Scan multiple markers in one session
8. **Advanced OCR**: Better handling of weathered/damaged markers
9. **Custom Grid Sizes**: Support different cemetery layouts
10. **PDF Export**: Generate official validation reports

### Potential Improvements
- Machine learning for marker detection
- Automatic image enhancement for better OCR
- Integration with cemetery management systems
- Historical validation tracking
- Statistical analysis dashboards
- Multi-language support

## Code Organization

```
BlindCheck/
├── Models/
│   └── MarkerData.swift          # Data structures
├── ViewModels/
│   └── BlindCheckViewModel.swift # Business logic
├── Views/
│   ├── MainView.swift            # Tab coordinator
│   ├── GridView.swift            # Grid visualization
│   └── CameraView.swift          # Camera & scanning
├── Assets.xcassets/              # App assets
├── Info.plist                    # Permissions config
├── AppDelegate.swift             # App lifecycle
└── ContentView.swift             # Root view

```

## Building & Running

### Xcode Setup
1. Open `BlindCheck.xcodeproj` in Xcode
2. Select target device (physical iPhone recommended for camera)
3. Ensure development team is set in project settings
4. Build and run (⌘R)

### Testing
- **Simulator**: Grid and validation UI works, but camera is unavailable
- **Physical Device**: Full functionality including camera scanning

### Debugging
- Check console for text recognition results
- View recognized text overlay on camera feed
- Validation confidence scores help identify issues

## Best Practices for Field Use

1. **Lighting**: Ensure good lighting conditions for OCR accuracy
2. **Alignment**: Use the 3x3 grid overlay to align with physical layout
3. **Distance**: Maintain consistent distance from markers
4. **Stability**: Hold device steady when capturing
5. **Verification**: Always manually verify critical validations
6. **Notes**: Add detailed notes for any discrepancies
7. **Systematic**: Work row-by-row or section-by-section

## Troubleshooting

### Camera Not Working
- Check camera permissions in Settings
- Restart app
- Verify physical device (simulator doesn't support camera)

### Text Recognition Fails
- Improve lighting conditions
- Clean marker surface if possible
- Get closer to marker
- Capture multiple times
- Use manual validation as fallback

### App Crashes
- Check Xcode console for error messages
- Verify all files are included in target
- Clean build folder (⌘⇧K)
- Rebuild project

## License & Credits

Developed by Oleksii Ratiiev  
Date: December 3, 2025

This app is designed specifically for cemetery administration to ensure accurate record-keeping and proper management of interment rights.
