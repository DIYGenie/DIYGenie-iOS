//
//  ProfileView.swift
//  DIYGenieApp
//

import SwiftUI
import SafariServices

struct ProfileView: View {
    // Persisted user info (aligns with your existing keys)
    @AppStorage("user_id") private var userId: String = ""
    @AppStorage("user_name") private var userName: String = ""
    @AppStorage("user_email") private var userEmail: String = ""
    @AppStorage("subscription_tier") private var subscriptionTier: String = "Free" // Free | Casual | Pro

    @State private var showBilling = false
    @State private var billingURL = URL(string: "https://api.diygenieapp.com/billing")! // Your Stripe portal endpoint
    @State private var showAlert = false
    @State private var alertText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                // THEME BACKGROUND
                LinearGradient(
                    colors: [
                        Color(red: 28/255, green: 26/255, blue: 40/255),
                        Color(red: 58/255, green: 35/255, blue: 110/255)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // Header
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Profile")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            Text("Manage your account and plan.")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // Card: User info
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .center, spacing: 14) {
                                Circle()
                                    .fill(Color.white.opacity(0.12))
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        Text(initials(from: userName))
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(.white)
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(displayName)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text(displayEmail)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                Spacer()
                            }

                            Divider().background(Color.white.opacity(0.15))

                            HStack {
                                planBadge
                                Spacer()
                                NavigationLink(destination: BillingInfoView(tier: subscriptionTier)) {
                                    Text("View Plan Details")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Color.white.opacity(0.08))
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1))
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(18)
                        .padding(.horizontal, 20)

                        // Card: Manage subscription
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Subscription")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)

                            Text(subscriptionCopy(for: subscriptionTier))
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.75))

                            HStack(spacing: 12) {
                                Button {
                                    openBillingPortal()
                                } label: {
                                    Text("Manage Subscription")
                                        .font(.system(size: 16, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            LinearGradient(colors: [
                                                Color(red: 115/255, green: 73/255, blue: 224/255),
                                                Color(red: 146/255, green: 86/255, blue: 255/255)
                                            ], startPoint: .leading, endPoint: .trailing)
                                        )
                                        .foregroundColor(.white)
                                        .cornerRadius(14)
                                }

                                NavigationLink(destination: PricingCompareView()) {
                                    Text("Compare Plans")
                                        .font(.system(size: 16, weight: .medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.white.opacity(0.08))
                                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.15), lineWidth: 1))
                                        .foregroundColor(.white)
                                        .cornerRadius(14)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(18)
                        .padding(.horizontal, 20)

                        // Card: Support & feedback
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Support")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)

                            VStack(spacing: 12) {
                                LinkButton(title: "Send Feedback", url: URL(string: "https://diygenieapp.com/feedback")!)
                                LinkButton(title: "Help Center", url: URL(string: "https://diygenieapp.com/help")!)
                                LinkButton(title: "Terms & Privacy", url: URL(string: "https://diygenieapp.com/legal")!)
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(18)
                        .padding(.horizontal, 20)

                        // Danger area
                        VStack(spacing: 12) {
                            Button(role: .destructive) {
                                signOut()
                            } label: {
                                Text("Sign Out")
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.red.opacity(0.18))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.35), lineWidth: 1))
                                    .foregroundColor(.white)
                                    .cornerRadius(14)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Profile")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .sheet(isPresented: $showBilling) {
                SafariView(url: billingURL)
                    .ignoresSafeArea()
            }
            .alert("Notice", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertText)
            }
        }
    }

    // MARK: - Helpers

    private var displayName: String {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "DIY Genie User" : trimmed
    }

    private var displayEmail: String {
        let trimmed = userEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "no-email@diygenieapp.com" : trimmed
    }

    private var planBadge: some View {
        let (label, color): (String, Color) = {
            switch subscriptionTier.lowercased() {
            case "pro": return ("Pro", Color.green)
            case "casual": return ("Casual", Color.blue)
            default: return ("Free", Color.gray)
            }
        }()
        return Text(label.uppercased())
            .font(.system(size: 12, weight: .bold))
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(color.opacity(0.25))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.5), lineWidth: 1))
            .cornerRadius(8)
            .foregroundColor(.white)
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map { String($0) } ?? "D"
        let second = (parts.dropFirst().first?.first).map { String($0) } ?? "G"
        return (first + second).uppercased()
    }

    private func subscriptionCopy(for tier: String) -> String {
        switch tier.lowercased() {
        case "pro":
            return "Pro unlocks up to 10 projects with visual previews, faster processing, and priority support."
        case "casual":
            return "Casual unlocks up to 5 projects with visual previews and standard support."
        default:
            return "Free includes 2 plan generations without previews. Upgrade to unlock previews and more projects."
        }
    }

    private func openBillingPortal() {
        // Append user_id if your backend expects it
        if var comps = URLComponents(url: billingURL, resolvingAgainstBaseURL: false), !userId.isEmpty {
            comps.queryItems = (comps.queryItems ?? []) + [URLQueryItem(name: "user_id", value: userId)]
            if let url = comps.url { billingURL = url }
        }
        showBilling = true
    }

    private func signOut() {
        // If you have a real AuthService, call it here.
        // AuthService.shared.signOut()

        // Fallback: clear local session
        userId = ""
        userName = ""
        userEmail = ""
        subscriptionTier = "Free"
        alertText = "You’ve been signed out."
        showAlert = true
    }
}

// MARK: - Small Components

private struct LinkButton: View {
    let title: String
    let url: URL

    var body: some View {
        Link(destination: url) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(14)
            .background(Color.white.opacity(0.06))
            .cornerRadius(12)
        }
    }
}

private struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: url) }
    func updateUIViewController(_ vc: SFSafariViewController, context: Context) {}
}

// Optional: lightweight details view for "View Plan Details" entry
struct BillingInfoView: View {
    let tier: String
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 28/255, green: 26/255, blue: 40/255),
                    Color(red: 58/255, green: 35/255, blue: 110/255)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("Your Plan")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text(tierDescription(tier))
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()
            }
            .padding(20)
        }
        .navigationTitle("Plan Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tierDescription(_ tier: String) -> String {
        switch tier.lowercased() {
        case "pro":
            return "Pro: up to 10 projects with visual previews, faster processing, and priority support."
        case "casual":
            return "Casual: up to 5 projects with visual previews and standard support."
        default:
            return "Free: 2 plan generations without previews."
        }
    }
}

struct PricingCompareView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 28/255, green: 26/255, blue: 40/255),
                    Color(red: 58/255, green: 35/255, blue: 110/255)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Compare Plans")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                planRow("Free", "2 plan generations, no previews.")
                planRow("Casual", "5 projects + visual previews.")
                planRow("Pro", "10 projects + visual previews + priority support.")

                Spacer()
            }
            .padding(20)
        }
        .navigationTitle("Compare Plans")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func planRow(_ title: String, _ detail: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            Text(detail)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.75))
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
    }
}
