//
//  ProgressOverlay.swift
//  DIYGenieApp
//
//  Blocking progress overlay shown during plan generation.
//

import SwiftUI

struct ProgressOverlay: View {
    let message: String
    
    init(message: String = "Generating your plan...") {
        self.message = message
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                
                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("This may take up to a minute")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(DS.Colors.background.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(DS.Colors.cardBorder, lineWidth: 1)
                    )
            )
            .padding(40)
        }
    }
}

