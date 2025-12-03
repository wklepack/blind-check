//
//  ContractIDView.swift
//  BlindCheck
//
//  Created by Oleksii Ratiiev on 03.12.2025.
//

import SwiftUI

struct ContractIDView: View {
    @State private var contractID: String = ""
    @Binding var enteredContractID: String
    @Binding var isContractVerified: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                // Header Section
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Enter Contract ID")
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    Text("Please enter your contract ID to access the verification system")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Input Section
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contract ID")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter contract ID", text: $contractID)
                            .textFieldStyle(.roundedBorder)
                            .font(.body)
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                    }
                    
                    Button(action: {
                        enteredContractID = contractID
                        isContractVerified = true
                    }) {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                            Text("Verify")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(contractID.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(contractID.isEmpty)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding()
            .navigationTitle("BlindCheck")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContractIDView(
        enteredContractID: .constant(""),
        isContractVerified: .constant(false)
    )
}