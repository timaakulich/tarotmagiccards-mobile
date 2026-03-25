import SwiftUI

struct SpreadSelectionScreen: View {
    @Environment(ViewModel.self) var viewModel

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                // Header: step progress + close button
                HStack {
                    Spacer()
                    StepProgressBar(
                        currentStep: viewModel.currentStep,
                        totalSteps: viewModel.totalSteps
                    )
                    Spacer()
                    Button {
                        viewModel.dismissFlow()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // Title
                Text("Pick your spread to reveal the cards' message.")
                    .font(.system(size: 24, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 32)
                    .padding(.bottom, 24)

                // Spread list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.availableSpreads) { spread in
                            SpreadCard(spread: spread) {
                                viewModel.selectSpread(spread)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }

                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                        .padding(.bottom, 16)
                }
            }
        }
        #if !os(macOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }
}

// MARK: - Spread Card

struct SpreadCard: View {
    let spread: TarotSpread
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Spread name
                Text(spread.name)
                    .font(.system(size: 22, design: .serif))
                    .foregroundStyle(.white)

                // Tags row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(spread.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.08))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                    }
                }

                // Card count
                Text("\(spread.positions.count) cards")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.secondaryText)

                // Description
                Text(spread.description)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Card position preview
                SpreadPositionPreview(positions: spread.positions)
                    .frame(height: 80)
                    .frame(maxWidth: .infinity)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard()
        }
    }
}

// MARK: - Spread Position Preview

struct SpreadPositionPreview: View {
    let positions: [SpreadPosition]

    var body: some View {
        GeometryReader { geometry in
            let cardWidth: CGFloat = 36
            let cardHeight: CGFloat = 54

            ZStack {
                ForEach(positions) { pos in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.accentRed.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Theme.accentRed.opacity(0.8), lineWidth: 1)
                        )
                        .frame(width: cardWidth, height: cardHeight)
                        .rotationEffect(.degrees(pos.rotation))
                        .position(
                            x: pos.x * geometry.size.width,
                            y: pos.y * geometry.size.height
                        )
                }
            }
        }
    }
}
