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
                        Text("Card Drawing")
                    case .revealCards:
                        Text("Reveal Cards")
                    case .cardDetail(let index):
                        Text("Card Detail \(index)")
                    case .finalResult:
                        Text("Final Result")
                    case .history:
                        Text("History")
                    case .readingDetail(let readingId):
                        Text("Reading Detail \(readingId)")
                    }
                }
        }
        .environment(viewModel)
        .preferredColorScheme(.dark)
    }
}
