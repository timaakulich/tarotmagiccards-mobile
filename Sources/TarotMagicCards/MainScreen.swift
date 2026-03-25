import SwiftUI

struct MainScreen: View {
    @Environment(ViewModel.self) var viewModel

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                // Top bar with history button
                HStack {
                    Spacer()
                    Button {
                        viewModel.path.append(.history)
                    } label: {
                        Text("history")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()

                // Center question text
                Text("What is your question to the cards?")
                    .font(.system(size: 40, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 307)

                Spacer()

                // Bottom input area
                VStack(spacing: 12) {
                    // Voice input card (simulated - navigates to text input)
                    Button {
                        viewModel.path.append(.textInput)
                    } label: {
                        VStack(spacing: 16) {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                                .overlay(
                                    Image(systemName: "mic.fill")
                                        .foregroundStyle(Theme.accentRed)
                                        .font(.system(size: 20))
                                )
                                .frame(width: 48, height: 48)

                            Text("Ask the cards aloud")
                                .font(.system(size: 17))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 40)
                        .glassCard()
                    }

                    // Text input card
                    Button {
                        viewModel.path.append(.textInput)
                    } label: {
                        Text("Type it instead ...")
                            .font(.system(size: 17))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .glassCard()
                    }
                }
                .frame(width: 343)
                .padding(.bottom, 40)
            }
        }
        #if !os(macOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }
}
