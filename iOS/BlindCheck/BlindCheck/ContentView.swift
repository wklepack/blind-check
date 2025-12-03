//
//  ContentView.swift
//  BlindCheck
//
//  Created by Oleksii Ratiiev on 03.12.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = BlindCheckViewModel()
    @State private var isLoggedIn = false
    @State private var isContractVerified = false
    @State private var enteredContractID = ""
    
    var body: some View {
        Group {
            if !isLoggedIn {
                LoginView(isLoggedIn: $isLoggedIn)
            } else if !isContractVerified {
                ContractIDView(
                    enteredContractID: $enteredContractID,
                    isContractVerified: $isContractVerified
                )
                .onChange(of: isContractVerified) { newValue in
                    if newValue {
                        // Reset all validation states when entering a new contract
                        viewModel.resetAllValidationStates()
                    }
                }
            } else {
                // Main app content - directly show GridView
                NavigationView {
                    GridView(viewModel: viewModel) {
                        // Navigate back to ContractIDView
                        isContractVerified = false
                        enteredContractID = ""
                    }
                        .navigationTitle("Contract: \(enteredContractID)")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Menu {
                                    Button(action: {
                                        viewModel.loadSampleData()
                                    }) {
                                        Label("Reset Data", systemImage: "arrow.clockwise")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                }
                            }
                            
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Logout") {
                                    // Reset validation states
                                    viewModel.resetAllValidationStates()
                                    // Reset to login state
                                    isLoggedIn = false
                                    isContractVerified = false
                                    enteredContractID = ""
                                }
                            }
                        }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
