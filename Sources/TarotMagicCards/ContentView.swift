import SwiftUI

struct ContentView: View {
    @State var viewModel = ViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack(path: $viewModel.path) {
            MainScreen()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .textInput:
                        TextInputScreen()
                    case .spreadSelection:
                        SpreadSelectionScreen()
                    case .quiz:
                        QuizScreen()
                    case .cardDrawing:
                        CardDrawingScreen()
                    case .revealCards:
                        RevealCardsScreen()
                    case .cardDetail(let index):
                        CardDetailView(index: index)
                    case .finalResult:
                        FinalResultScreen()
                    case .history:
                        HistoryScreen()
                    case .readingDetail:
                        FinalResultScreen()
                    }
                }
        }
        .environment(viewModel)
        .preferredColorScheme(.dark)
    }
}
