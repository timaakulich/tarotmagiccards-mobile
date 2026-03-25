import SwiftUI

struct RevealCardsScreen: View {
    @Environment(ViewModel.self) var viewModel


    private var totalSlots: Int {
        viewModel.currentReading?.cards.count ?? viewModel.drawnCards.count
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header: close button
                HStack {
                    Spacer()
                    Button {
                        viewModel.startNewReading()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // Card slots row (all filled)
                HStack(spacing: 8) {
                    ForEach(0..<totalSlots, id: \.self) { _ in
                        CardSlot(isFilled: true)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Text("Your cards have been drawn")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.top, 16)

                Spacer()

                PillButton(title: "Reveal the cards") {
                    viewModel.path.append(.cardDetail(index: 0))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        #if !os(macOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }
}
