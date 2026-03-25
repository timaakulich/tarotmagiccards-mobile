import SwiftUI

struct CardDetailView: View {
    @Environment(ViewModel.self) var viewModel
    let index: Int

    private var reading: ReadingResponse? {
        viewModel.currentReading
    }

    private var card: ReadingCardResponse? {
        guard let reading = reading, index < reading.cards.count else { return nil }
        return reading.cards[index]
    }

    private var isLastCard: Bool {
        guard let reading = reading else { return true }
        return index >= reading.cards.count - 1
    }

    private var cardColor: Color {
        guard let card = card else { return Theme.accentRed }
        if card.cardSuit == nil {
            // Major Arcana - gold tint
            return Color(hex: "#B8860B")
        }
        switch card.cardSuit {
        case "cups": return Color(hex: "#1E90FF")
        case "wands": return Color(hex: "#FF6347")
        case "swords": return Color(hex: "#87CEEB")
        case "pentacles": return Color(hex: "#228B22")
        default: return Theme.accentRed
        }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if let card = card {
                VStack(spacing: 0) {
                    // Position name header
                    Text(card.positionName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.secondaryText)
                        .textCase(.uppercase)
                        .tracking(2)
                        .padding(.top, 8)

                    ScrollView {
                        VStack(spacing: 20) {
                            // Card image placeholder
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [cardColor.opacity(0.3), cardColor.opacity(0.1)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(cardColor.opacity(0.4), lineWidth: 1)
                                VStack(spacing: 8) {
                                    Text(card.cardName)
                                        .font(.system(size: 20, weight: .bold, design: .serif))
                                        .foregroundStyle(.white)
                                    Text(card.cardPosition)
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.secondaryText)
                                        .textCase(.uppercase)
                                }
                            }
                            .frame(width: 147, height: 253)

                            // Card name in caps
                            Text(card.cardName.uppercased())
                                .font(.system(size: 22, weight: .bold, design: .serif))
                                .foregroundStyle(.white)
                                .tracking(2)

                            // One-liner: first sentence of symbolic connection
                            Text(firstSentence(from: card.symbolicConnection))
                                .font(.system(size: 16))
                                .foregroundStyle(Theme.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)

                            // Divider
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 295, height: 1)

                            // Full tarot insight
                            Text(card.tarotInsight)
                                .font(.system(size: 16))
                                .foregroundStyle(.white.opacity(0.85))
                                .lineSpacing(4)
                                .padding(.horizontal, 24)
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }

                    // Bottom buttons
                    VStack(spacing: 8) {
                        if isLastCard {
                            PillButton(title: "Show full spread overview") {
                                viewModel.path.append(.finalResult)
                            }
                        } else {
                            PillButton(title: "Next card") {
                                viewModel.path.append(.cardDetail(index: index + 1))
                            }
                            PillButton(title: "Skip to full spread overview", style: .secondary) {
                                viewModel.path.append(.finalResult)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
            }
        }
        #if !os(macOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }

    private func firstSentence(from text: String) -> String {
        if let dotRange = text.range(of: ".") {
            return String(text[text.startIndex...dotRange.lowerBound])
        }
        return text
    }
}
