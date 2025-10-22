import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Welcome to DIY Genie.")
                .font(.title2)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
