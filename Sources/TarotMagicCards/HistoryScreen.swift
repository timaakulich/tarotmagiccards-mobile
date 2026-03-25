import SwiftUI

struct HistoryScreen: View {
    @Environment(ViewModel.self) var viewModel

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            // Decorative ellipses
            VStack {
                Spacer()
                Ellipse()
                    .fill(Theme.accentRed.opacity(0.2))
                    .frame(width: 300, height: 200)
                    .blur(radius: 80)
                    .offset(y: 60)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                ZStack {
                    Text("History")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)

                    HStack {
                        Button {
                            viewModel.path.removeLast()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                if viewModel.isLoading && viewModel.readings.isEmpty {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(viewModel.readings) { reading in
                                HistoryReadingCard(reading: reading)
                                    .onTapGesture {
                                        viewModel.viewReadingDetail(reading.id)
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        #if !os(macOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .onAppear {
            viewModel.loadHistory()
        }
    }
}

// MARK: - History Reading Card

struct HistoryReadingCard: View {
    let reading: ReadingListItemResponse

    private var formattedDate: String {
        let parts = reading.createdAt.split(separator: "T")
        guard let datePart = parts.first else { return reading.createdAt }
        let dateComponents = datePart.split(separator: "-")
        guard dateComponents.count == 3,
              let month = Int(dateComponents[1]),
              let day = Int(dateComponents[2]) else { return String(datePart) }

        let monthNames = ["January", "February", "March", "April", "May", "June",
                          "July", "August", "September", "October", "November", "December"]
        guard month >= 1, month <= 12 else { return String(datePart) }
        return "\(day) \(monthNames[month - 1])"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(formattedDate)
                .font(.system(size: 13))
                .foregroundStyle(Theme.secondaryText)

            Text(reading.mainQuestion)
                .font(.system(size: 18, design: .serif))
                .foregroundStyle(.white)
                .lineLimit(2)

            // Card preview area
            ZStack {
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color.white.opacity(0.04))
                RoundedRectangle(cornerRadius: 32)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)

                HStack(spacing: -8) {
                    ForEach(Array(reading.cards.enumerated()), id: \.offset) { index, _ in
                        MiniCardBack(rotation: cardRotation(index: index, total: reading.cards.count))
                    }
                }
            }
            .frame(height: 181)
            .clipShape(RoundedRectangle(cornerRadius: 32))
        }
        .padding(20)
        .glassCard()
    }

    private func cardRotation(index: Int, total: Int) -> Double {
        guard total > 1 else { return 0 }
        let mid = Double(total - 1) / 2.0
        return (Double(index) - mid) * 5.0
    }
}

// MARK: - Mini Card Back

struct MiniCardBack: View {
    var rotation: Double = 0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#C20000").opacity(0.6), Color(hex: "#C20000").opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(hex: "#C20000").opacity(0.5), lineWidth: 1)
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color(hex: "#C20000").opacity(0.3), lineWidth: 0.5)
                .padding(4)
        }
        .frame(width: 44, height: 66)
        .shadow(color: Color(red: 205/255, green: 0, blue: 20/255).opacity(0.15), radius: 12, y: 8)
        .rotationEffect(.degrees(rotation))
    }
}
