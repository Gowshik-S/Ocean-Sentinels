import SwiftUI

// MARK: - SplashScreen

/// Splash screen with logo animation.
struct SplashScreen: View {
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo
            Image(systemName: "water.waves")
                .font(.system(size: 64))
                .foregroundStyle(.white)
                .frame(width: 120, height: 120)
                .background(Color.oceanPrimary, in: RoundedRectangle(cornerRadius: 32))
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.8)

            VStack(spacing: 8) {
                Text("Ocean Sentinels")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Color.oceanPrimary)

                Text("Secure Access to India's Coastal Network")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(isVisible ? 1 : 0)

            Spacer()

            ProgressView()
                .tint(Color.oceanPrimary)

            Text("Version 1.0.0")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 32)
        }
        .padding(32)
        .onAppear {
            withAnimation(.easeOut(duration: 1)) {
                isVisible = true
            }
        }
    }
}
