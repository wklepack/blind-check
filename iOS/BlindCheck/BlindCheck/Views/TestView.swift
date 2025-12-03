//
//  TestView.swift
//  BlindCheck
//
//  Created by Oleksii Ratiiev on 03.12.2025.
//

import SwiftUI

struct TestView: View {
    let marker: MarkerData
    @ObservedObject var viewModel: BlindCheckViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        Color.red
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 20) {
                    Text("RED SCREEN!")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("If you see this, it works!")
                        .font(.title)
                        .foregroundColor(.white)
                    
                    Button("TAP TO CLOSE") {
                        isPresented = false
                    }
                    .font(.title)
                    .padding(20)
                    .background(Color.white)
                    .foregroundColor(.red)
                    .cornerRadius(10)
                }
            )
            .onAppear {
                print("🔥 TestView appeared!")
            }
    }
}