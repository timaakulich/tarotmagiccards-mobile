import Foundation
import Observation
import SkipFuse

// MARK: - Navigation

enum AppRoute: Hashable {
    case textInput
    case spreadSelection
    case quiz
    case cardDrawing
    case revealCards
    case cardDetail(index: Int)
    case finalResult
    case history
    case readingDetail(readingId: Int)
}

// MARK: - ViewModel

@MainActor
@Observable public class ViewModel {
    // Navigation
    var path: [AppRoute] = []

    // Flow state
    var currentQuestion: String = ""
    var availableSpreads: [TarotSpread] = []
    var selectedSpread: TarotSpread?
    var userSpread: UserSpread?
    var clarifyingQuestions: [ClarifyingQuestion] = []
    var selectedAnswers: [String] = []
    var currentQuizIndex: Int = 0
    var drawnCards: [UserCard] = []
    var currentReading: ReadingResponse?
    var readings: [ReadingListItemResponse] = []
    var isLoading: Bool = false

    private let apiService = MockAPIService()

    init() {}

    // Step calculation

    var totalSteps: Int {
        1 + clarifyingQuestions.count + 1
    }

    var currentStep: Int {
        for route in path.reversed() {
            switch route {
            case .cardDrawing:
                return totalSteps
            case .quiz:
                return 2 + currentQuizIndex
            case .spreadSelection:
                return 1
            default:
                continue
            }
        }
        return 1
    }

    // MARK: - Flow Methods

    func submitQuestion(_ question: String) {
        currentQuestion = question
        isLoading = true
        Task {
            let spreads = await apiService.getAvailableSpreads()
            availableSpreads = spreads
            isLoading = false
            path.append(.spreadSelection)
        }
    }

    func selectSpread(_ spread: TarotSpread) {
        selectedSpread = spread
        isLoading = true
        Task {
            let us = await apiService.createUserSpread(spreadId: spread.id)
            let questions = await apiService.getClarifyingQuestions(message: currentQuestion)
            userSpread = us
            clarifyingQuestions = questions
            selectedAnswers = []
            currentQuizIndex = 0
            isLoading = false
            if questions.isEmpty {
                path.append(.cardDrawing)
            } else {
                path.append(.quiz)
            }
        }
    }

    func answerQuizQuestion(_ answer: String) {
        selectedAnswers.append(answer)
        if currentQuizIndex < clarifyingQuestions.count - 1 {
            currentQuizIndex += 1
        } else {
            path.append(.cardDrawing)
        }
    }

    func drawCard() {
        guard let userSpread = userSpread else { return }
        isLoading = true
        let cardIndex = drawnCards.count
        Task {
            let card = await apiService.drawCard(spreadId: userSpread.id, cardIndex: cardIndex)
            drawnCards.append(card)
            isLoading = false
        }
    }

    func finishDrawing() {
        guard let userSpread = userSpread else { return }
        isLoading = true
        Task {
            let reading = await apiService.createReading(
                mainQuestion: currentQuestion,
                userSpreadId: userSpread.id,
                questions: clarifyingQuestions,
                answers: selectedAnswers
            )
            currentReading = reading
            isLoading = false
            path.append(.revealCards)
        }
    }

    func loadHistory() {
        isLoading = true
        Task {
            let items = await apiService.getReadings()
            readings = items
            isLoading = false
        }
    }

    func viewReadingDetail(_ id: Int) {
        isLoading = true
        Task {
            let reading = await apiService.getReadingDetail(id: id)
            currentReading = reading
            isLoading = false
            path.append(.finalResult)
        }
    }

    func startNewReading() {
        currentQuestion = ""
        availableSpreads = []
        selectedSpread = nil
        userSpread = nil
        clarifyingQuestions = []
        selectedAnswers = []
        currentQuizIndex = 0
        drawnCards = []
        currentReading = nil
        path = []
    }

    func dismissFlow() {
        startNewReading()
    }
}
