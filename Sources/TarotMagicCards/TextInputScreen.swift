import SwiftUI

struct TextInputScreen: View {
    @Environment(ViewModel.self) var viewModel
    @State var questionText: String = ""
    @FocusState var isTextEditorFocused: Bool

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    Button {
                        if !viewModel.path.isEmpty { viewModel.path.removeLast() }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                    }

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
                .padding(.vertical, 12)

                // Text editor area
                ZStack(alignment: .topLeading) {
                    if questionText.isEmpty {
                        Text("Share your question with the cards...")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.white.opacity(0.55))
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }

                    TextEditor(text: $questionText)
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 12)
                        .focused($isTextEditorFocused)
                }
                .frame(maxHeight: .infinity)

                // Bottom area with send button
                HStack {
                    Spacer()

                    if viewModel.isLoading {
                        // Loading spinner
                        ProgressView()
                            .tint(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.55))
                            .clipShape(Circle())
                    } else {
                        // Send button
                        Button {
                            guard !questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                            viewModel.submitQuestion(questionText)
                        } label: {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(Theme.backgroundGradient)
                                .clipShape(Circle())
                        }
                        .opacity(questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1.0)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        #if !os(macOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .onAppear {
            isTextEditorFocused = true
        }
    }
}
