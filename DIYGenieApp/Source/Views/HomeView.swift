//
//  HomeView.swift
//  DIYGenieApp
//

import SwiftUI

struct HomeView: View {
    @State private var currentSlide = 0
    private let slides = ["room1", "room2", "room3"] // Replace with your real image assets
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "#5B1FFF").opacity(0.15),
                        Color(hex: "#8C4BFF").opacity(0.10),
                        Color.white
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        
                        // MARK: - Header
                        HStack {
                            Image("DIYGenieIcon")
                                .resizable()
                                .frame(width: 36, height: 36)
                                .cornerRadius(8)
                                .shadow(radius: 2)
                            
                            Spacer()
                        }
                        .padding(.top, 12)
                        .padding(.horizontal, 20)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome back, Tye")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                            
                            Text("Ready to start your next DIY project?")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        
                        // MARK: - Hero Section
                        VStack(spacing: 10) {
                            TabView(selection: $currentSlide) {
                                ForEach(slides.indices, id: \.self) { index in
                                    Image(slides[index])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 180)
                                        .cornerRadius(14)
                                        .clipped()
                                        .overlay(
                                            Text("See your space transform")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                                .shadow(radius: 4)
                                                .padding(.bottom, 12),
                                            alignment: .bottom
                                        )
                                        .tag(index)
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            .frame(height: 180)
                            
                            // Progress dots
                            HStack(spacing: 6) {
                                ForEach(slides.indices, id: \.self) { index in
                                    Circle()
                                        .fill(index == currentSlide ? Color.purple : Color.gray.opacity(0.4))
                                        .frame(width: 6, height: 6)
                                }
                            }
                            
                            // Step indicator
                            Text("1 Describe • 2 Scan • 3 Preview • 4 Build")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 20)
                        
                        // MARK: - Templates Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Start with a template")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color(hex: "#5B1FFF"))
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 14) {
                                TemplateCard(title: "Shelf", subtitle: "Clean, modern storage")
                                TemplateCard(title: "Accent Wall", subtitle: "Add depth and contrast")
                                TemplateCard(title: "Mudroom Bench", subtitle: "Entryway organization")
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 60)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Template Card
struct TemplateCard: View {
    var title: String
    var subtitle: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            Spacer()
            NavigationLink(destination: NewProjectView()) {
                Text("Create")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 18)
                    .background(
                        LinearGradient(colors: [Color.purple, Color(hex: "#8C4BFF")],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                            .cornerRadius(20)
                    )
                    .shadow(color: .purple.opacity(0.3), radius: 3, x: 0, y: 2)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}
