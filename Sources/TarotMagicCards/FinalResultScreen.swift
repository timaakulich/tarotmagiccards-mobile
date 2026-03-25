import SwiftUI

struct FinalResultScreen: View {
    @Environment(ViewModel.self) var viewModel

    private var reading: ReadingResponse? {
        viewModel.currentReading
    }

    private var spreadName: String {
        viewModel.selectedSpread?.name ?? reading?.spreadId.replacingOccurrences(of: "_", with: " ").capitalized ?? "Reading"
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if let reading = reading {
                VStack(spacing: 0) {
                    // Nav title
                    Text(spreadName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.secondaryText)
                        .textCase(.uppercase)
                        .tracking(2)
                        .padding(.top, 8)

                    ScrollView {
                        VStack(spacing: 24) {
                            // Cards strip
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Array(reading.cards.enumerated()), id: \.offset) { index, card in
                                        CardThumbnail(card: card)
                                            .onTapGesture {
                                                viewModel.path.append(.cardDetail(index: index))
                                            }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }

                            Text("Tap a card to view its insight")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.secondaryText)

                            // Full spread overview heading
                            Text("Full spread overview")
                                .font(.system(size: 27, weight: .bold, design: .serif))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)

                            // Insight sections
                            ForEach(Array(reading.insights.enumerated()), id: \.offset) { _, insight in
                                InsightCard(insight: insight)
                                    .padding(.horizontal, 24)
                            }

                            // Result narrative
                            if !reading.result.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 8) {
                                        Text("Summary")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .textCase(.uppercase)
                                            .tracking(1)
                                    }
                                    Rectangle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 1)
                                    Text(reading.result)
                                        .font(.system(size: 15))
                                        .foregroundStyle(.white.opacity(0.85))
                                        .lineSpacing(4)
                                }
                                .padding(20)
                                .glassCard()
                                .padding(.horizontal, 24)
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }

                    // Finish button
                    PillButton(title: "Finish") {
                        viewModel.startNewReading()
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
}

// MARK: - Card Thumbnail

struct CardThumbnail: View {
    let card: ReadingCardResponse

    private var cardColor: Color {
        Theme.cardColor(forSuit: card.cardSuit)
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [cardColor.opacity(0.3), cardColor.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                RoundedRectangle(cornerRadius: 10)
                    .stroke(cardColor.opacity(0.4), lineWidth: 1)
                Text(card.cardName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(4)
            }
            .frame(width: 83, height: 127)

            Text(card.positionName)
                .font(.system(size: 11))
                .foregroundStyle(Theme.secondaryText)
        }
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let insight: InsightItem

    private var emoji: String {
        switch insight.type {
        case "blind_spot": return "\u{1F441}"
        case "hidden_trap": return "\u{1F573}"
        case "core_lesson": return "\u{2696}"
        case "first_conscious_step": return "\u{1F463}"
        case "pattern": return "\u{1F504}"
        case "trigger_event": return "\u{26A1}"
        case "point_of_choice": return "\u{1F3AF}"
        case "hidden_cost": return "\u{1F48E}"
        case "paradox": return "\u{1F500}"
        case "turning_point": return "\u{21A9}"
        default: return "\u{2728}"
        }
    }

    private var title: String {
        insight.type.replacingOccurrences(of: "_", with: " ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 18))
                Text(title.uppercased())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .tracking(1)
            }
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
            Text(insight.text)
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(4)
        }
        .padding(20)
        .glassCard()
    }
}
