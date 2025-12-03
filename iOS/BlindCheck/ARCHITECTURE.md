# BlindCheck Architecture Diagram

## App Structure

```
┌─────────────────────────────────────────────────────────────┐
│                     BlindCheck App                          │
│                   (Cemetery Marker Validation)              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        ContentView                          │
│                     (SwiftUI Root View)                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                         MainView                            │
│                      (TabView Controller)                   │
│  ┌──────────────┬──────────────┬──────────────────────┐    │
│  │   Grid Tab   │   Scan Tab   │   Status Tab         │    │
│  │   (Grid)     │  (Camera)    │  (Validation List)   │    │
│  └──────────────┴──────────────┴──────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
         │                │                    │
         ▼                ▼                    ▼
┌─────────────┐  ┌──────────────┐   ┌──────────────────┐
│  GridView   │  │  CameraView  │   │ValidationListView│
│             │  │              │   │                  │
│  • 3x3 Grid │  │ • Camera     │   │ • Statistics     │
│  • Details  │  │ • OCR        │   │ • Marker List    │
│  • Validate │  │ • Overlay    │   │ • Status Badges  │
└─────────────┘  └──────────────┘   └──────────────────┘
         │                │                    │
         └────────────────┼────────────────────┘
                          ▼
         ┌─────────────────────────────────────┐
         │     BlindCheckViewModel             │
         │                                     │
         │  • Grid Management                  │
         │  • Text Recognition Processing      │
         │  • Validation Logic                 │
         │  • Data Persistence Integration     │
         │  • Report Generation                │
         └─────────────────────────────────────┘
                          │
                          ▼
    ┌────────────────────────────────────────┐
    │          Data Layer                    │
    │                                        │
    │  ┌──────────────┐  ┌──────────────┐  │
    │  │ MarkerData   │  │ DataManager  │  │
    │  │ Models       │  │ (Singleton)  │  │
    │  │              │  │              │  │
    │  │ • Marker     │  │ • Save/Load  │  │
    │  │ • Grid       │  │ • Export     │  │
    │  │ • Validation │  │ • Import     │  │
    │  └──────────────┘  └──────────────┘  │
    └────────────────────────────────────────┘
                          │
                          ▼
             ┌───────────────────────┐
             │    UserDefaults       │
             │  (Local Persistence)  │
             └───────────────────────┘
```

## Data Flow Diagram

```
┌──────────────┐
│     User     │
└──────┬───────┘
       │
       │ Interacts
       ▼
┌──────────────────┐
│   SwiftUI View   │
│                  │
│ • GridView       │
│ • CameraView     │
│ • MainView       │
└──────┬───────────┘
       │
       │ Actions/Events
       ▼
┌────────────────────────┐
│  BlindCheckViewModel   │
│                        │
│ @Published Properties: │
│ • currentGrid         │
│ • allMarkers          │
│ • validationResults   │
│ • isScanning          │
└──────┬─────────────────┘
       │
       │ Updates
       ▼
┌─────────────────┐      ┌──────────────┐
│  MarkerData     │      │ DataManager  │
│  (Models)       │◄────►│              │
│                 │      │ • Save       │
│ • Marker info   │      │ • Load       │
│ • Position      │      │ • Export     │
│ • Validation    │      └──────────────┘
└─────────────────┘
       │
       │ Persisted
       ▼
┌─────────────────┐
│  UserDefaults   │
│  (JSON Data)    │
└─────────────────┘
```

## Camera & OCR Flow

```
┌────────────┐
│   Camera   │
│   Button   │
└─────┬──────┘
      │ Tap
      ▼
┌──────────────────┐
│ AVCaptureSession │
│                  │
│ • Start Preview  │
│ • Capture Photo  │
└────────┬─────────┘
         │
         │ Photo Data
         ▼
┌────────────────────────┐
│ VNRecognizeTextRequest │
│                        │
│ • Process Image        │
│ • Extract Text         │
│ • Recognition Level    │
└────────┬───────────────┘
         │
         │ Recognized Strings
         ▼
┌─────────────────────────┐
│  ViewModel Processing   │
│                         │
│ • Match with Database   │
│ • Calculate Confidence  │
│ • Update Markers        │
└────────┬────────────────┘
         │
         │ Validation Results
         ▼
┌────────────────────┐
│   Grid Update      │
│                    │
│ • Status Colors    │
│ • Marker Details   │
│ • Confidence Score │
└────────────────────┘
```

## Validation State Machine

```
┌──────────────┐
│ Not Scanned  │ (Gray)
│   (Initial)  │
└──────┬───────┘
       │
       │ Camera Scan OR Manual Input
       ▼
┌──────────────────┐
│   Processing     │
│  (OCR Running)   │
└──────┬───────────┘
       │
       ├─────────────────┬────────────────┐
       │                 │                │
       ▼                 ▼                ▼
┌──────────┐      ┌─────────────┐   ┌──────────┐
│  Valid   │      │Partial Match│   │ Invalid  │
│  (Green) │      │  (Orange)   │   │  (Red)   │
│          │      │             │   │          │
│ Match    │      │Some Issues  │   │Mismatch  │
│ 80%+     │      │ 50-80%      │   │ < 50%    │
└──────────┘      └─────────────┘   └──────────┘
```

## Grid Navigation

```
Current Position: (2, 2)

┌─────────┬─────────┬─────────┐
│ (1,1)   │ (1,2)   │ (1,3)   │
│  Top    │  Top    │  Top    │
│  Left   │ Center  │  Right  │
├─────────┼─────────┼─────────┤
│ (2,1)   │ (2,2)   │ (2,3)   │
│ Center  │ CENTER  │ Center  │
│  Left   │ ★★★★★   │  Right  │
├─────────┼─────────┼─────────┤
│ (3,1)   │ (3,2)   │ (3,3)   │
│ Bottom  │ Bottom  │ Bottom  │
│  Left   │ Center  │  Right  │
└─────────┴─────────┴─────────┘

Navigation:
• Select any cell → Recenters grid
• Always shows 3x3 around center
• Edge markers show partial grid
```

## Component Dependencies

```
AppDelegate.swift
    │
    └─► ContentView.swift
            │
            └─► MainView.swift
                    │
                    ├─► GridView.swift ──┐
                    │                    │
                    ├─► CameraView.swift ┤
                    │        │           │
                    │        ├─► CameraViewModel
                    │        │           │
                    │        └─► VNRecognizeTextRequest
                    │                    │
                    └─► ValidationListView
                                        │
                         ┌──────────────┴──────────────┐
                         │                             │
                         ▼                             ▼
              BlindCheckViewModel              MarkerData Models
                         │                             │
                         └─────────► DataManager ◄─────┘
                                         │
                                         ▼
                                   UserDefaults
```

## Feature Map

```
BlindCheck Features
│
├── Data Management
│   ├── Create/Load Markers
│   ├── Save to Persistence
│   ├── Export Reports
│   └── Import Data
│
├── Grid Visualization
│   ├── 3x3 Grid Display
│   ├── Marker Selection
│   ├── Status Indicators
│   └── Position Navigation
│
├── Camera Scanning
│   ├── Live Preview
│   ├── Photo Capture
│   ├── OCR Processing
│   └── Text Recognition
│
├── Validation System
│   ├── Automatic (OCR-based)
│   ├── Manual (User input)
│   ├── Confidence Scoring
│   └── Notes & Timestamps
│
└── Reporting
    ├── Validation Summary
    ├── Export to Text
    ├── Copy to Clipboard
    └── Statistics Dashboard
```

## Technology Stack

```
┌─────────────────────────────────────┐
│         Application Layer           │
│                                     │
│  SwiftUI Views + ViewModels         │
│  (Declarative UI, Reactive)         │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│        Framework Layer              │
│                                     │
│  • AVFoundation (Camera)            │
│  • Vision (OCR)                     │
│  • Combine (Reactive)               │
│  • Foundation (Data)                │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│         System Layer                │
│                                     │
│  • iOS SDK                          │
│  • UserDefaults                     │
│  • File System                      │
└─────────────────────────────────────┘
```

## User Journey Map

```
Start App
   ↓
View Grid (Default: Center 2,2)
   ↓
   ├─► Navigate Grid ──► Select Marker ──┐
   │                                     │
   ├─► Switch to Scan Tab ────────────┐ │
   │        ↓                          │ │
   │   Open Camera                     │ │
   │        ↓                          │ │
   │   Align & Capture                 │ │
   │        ↓                          │ │
   │   OCR Processing                  │ │
   │        ↓                          │ │
   │   Return to Grid ─────────────────┘ │
   │                                     │
   └────────────────────────────────────►│
                                         ↓
                            View Marker Details
                                         ↓
                         ┌───────────────┴────────────┐
                         │                            │
                         ▼                            ▼
                  Validate (Auto)              Validate (Manual)
                         │                            │
                         └────────────┬───────────────┘
                                      ▼
                              Status Updated
                                      ↓
                            Check Status Tab
                                      ↓
                            Export Report
```

---

This visual architecture helps understand:
- How components interact
- Data flow through the system
- User navigation paths
- Feature organization
- Technology layers
