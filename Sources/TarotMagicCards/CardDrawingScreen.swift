import SwiftUI

struct CardDrawingScreen: View {
    @Environment(ViewModel.self) var viewModel

    @State var deckCards: [Int] = Array(0..<9)
    @State var filledSlots: Int = 0

    private var totalSlots: Int {
        viewModel.selectedSpread?.positions.count ?? 3
    }

    private var allSlotsFilled: Bool {
        viewModel.drawnCards.count >= totalSlots
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header: step progress + close
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

                // Instruction text
                Text("Select the cards one by one from the deck")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 24)

                // Selected cards row
                HStack(spacing: 8) {
                    ForEach(0..<totalSlots, id: \.self) { index in
                        CardSlot(isFilled: index < viewModel.drawnCards.count)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                // Card deck fan
                ZStack {
                    ForEach(deckCards, id: \.self) { cardIndex in
                        DeckCard(
                            index: cardIndex,
                            totalCards: 9
                        )
                        .onTapGesture {
                            guard !viewModel.isLoading, !allSlotsFilled else { return }
                            withAnimation(.easeInOut(duration: 0.4)) {
                                deckCards.removeAll { $0 == cardIndex }
                            }
                            viewModel.drawCard()
                        }
                    }
                }
                .frame(height: 220)
                .padding(.bottom, 40)
            }

            // Loading overlay
            if viewModel.isLoading && allSlotsFilled {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                    Text("Reading the cards...")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                }
            }
        }
        #if !os(macOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .onChange(of: viewModel.drawnCards.count) { _, newCount in
            if newCount >= totalSlots {
                viewModel.finishDrawing()
            }
        }
    }
}

// MARK: - Card Slot

struct CardSlot: View {
    let isFilled: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(isFilled ? Theme.accentRed.opacity(0.3) : Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isFilled ? Theme.accentRed.opacity(0.6) : Color.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
            .frame(width: 62, height: 92)
            .shadow(
                color: isFilled ? Color(hex: "#CD0014").opacity(0.15) : .clear,
                radius: 12,
                y: 8
            )
    }
}

// MARK: - Deck Card (face-down)

struct DeckCard: View {
    let index: Int
    let totalCards: Int

    private var fanOffset: CGFloat {
        let center = CGFloat(totalCards - 1) / 2.0
        return (CGFloat(index) - center) * 32
    }

    private var fanRotation: Double {
        let center = Double(totalCards - 1) / 2.0
        return (Double(index) - center) * 5.0
    }

    private var yOffset: CGFloat {
        let center = CGFloat(totalCards - 1) / 2.0
        let distance = abs(CGFloat(index) - center)
        return distance * 4
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#2A0008"), Color(hex: "#8B0000")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.accentRed.opacity(0.6), lineWidth: 1)
            // Inner decorative border
            RoundedRectangle(cornerRadius: 7)
                .stroke(Theme.accentRed.opacity(0.3), lineWidth: 0.5)
                .padding(4)
        }
        .frame(width: 72, height: 108)
        .shadow(color: Color.black.opacity(0.3), radius: 4, y: 2)
        .rotationEffect(.degrees(fanRotation))
        .offset(x: fanOffset, y: yOffset)
    }
}
