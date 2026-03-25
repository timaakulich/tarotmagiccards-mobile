import SwiftUI

struct QuizScreen: View {
    @Environment(ViewModel.self) var viewModel
    @State var showCustomAnswer: Bool = false
    @State var customAnswerText: String = ""
    @State var selectedAnswer: String? = nil

    var body: some View {
        let question = currentQuestion

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

                // Question text
                if let question = question {
                    Text(question.question)
                        .font(.system(size: 18, design: .serif))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 40)
                        .padding(.bottom, 32)
                }

                // Answer options
                ScrollView {
                    VStack(spacing: 8) {
                        if let question = question {
                            ForEach(question.options, id: \.label) { option in
                                AnswerOptionCard(
                                    text: option.text,
                                    isSelected: selectedAnswer == option.text
                                ) {
                                    submitAnswer(option.text)
                                }
                            }
                        }

                        // Write your answer option
                        if showCustomAnswer {
                            CustomAnswerCard(
                                text: $customAnswerText,
                                onSubmit: {
                                    let answer = customAnswerText.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !answer.isEmpty else { return }
                                    submitAnswer(answer)
                                }
                            )
                        } else {
                            AnswerOptionCard(
                                text: "Write your answer",
                                isSelected: false
                            ) {
                                showCustomAnswer = true
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        #if !os(macOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }

    var currentQuestion: ClarifyingQuestion? {
        let index = viewModel.currentQuizIndex
        guard index < viewModel.clarifyingQuestions.count else { return nil }
        return viewModel.clarifyingQuestions[index]
    }

    private func submitAnswer(_ answer: String) {
        selectedAnswer = answer
        // Brief delay to show selection, then advance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            selectedAnswer = nil
            showCustomAnswer = false
            customAnswerText = ""
            viewModel.answerQuizQuestion(answer)
        }
    }
}

// MARK: - Answer Option Card

struct AnswerOptionCard: View {
    let text: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 92)
                .background(
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Theme.glassBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(
                            isSelected ? Color.white.opacity(0.4) : Theme.glassBorder,
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 32))
        }
    }
}

// MARK: - Custom Answer Card

struct CustomAnswerCard: View {
    @Binding var text: String
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            TextField("Type your answer...", text: $text)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)

            HStack {
                Spacer()
                Button(action: onSubmit) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Theme.backgroundGradient)
                        .clipShape(Circle())
                }
                .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1.0)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(Theme.glassBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(Theme.glassBorderHighlight, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 32))
    }
}
