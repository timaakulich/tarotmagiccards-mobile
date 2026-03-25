import Foundation

/* SKIP @bridge */
final class MockAPIService: Sendable {

    // MARK: - Spreads

    func getAvailableSpreads() async -> [TarotSpread] {
        await simulateDelay(0.5)
        return [
            TarotSpread(
                id: "three_card_spread",
                positions: [
                    SpreadPosition(id: 1, x: 0.17, y: 0.5, rotation: 0.0, name: "Past", meaning: "Events and influences from the past that affect the situation"),
                    SpreadPosition(id: 2, x: 0.5, y: 0.5, rotation: 0.0, name: "Present", meaning: "Current circumstances and energies surrounding the question"),
                    SpreadPosition(id: 3, x: 0.83, y: 0.5, rotation: 0.0, name: "Future", meaning: "The likely outcome or direction based on current energies")
                ],
                imageUrl: nil,
                name: "Three Card Spread",
                description: "A simple three-card layout exploring past, present, and future influences.",
                instructions: "Focus on your question, then draw three cards one at a time.",
                tags: ["beginner", "quick", "general"]
            ),
            TarotSpread(
                id: "celtic_cross",
                positions: [
                    SpreadPosition(id: 1, x: 0.35, y: 0.5, rotation: 0.0, name: "Present", meaning: "The current situation or question"),
                    SpreadPosition(id: 2, x: 0.35, y: 0.5, rotation: 90.0, name: "Challenge", meaning: "The immediate challenge or obstacle")
                ],
                imageUrl: nil,
                name: "Celtic Cross",
                description: "The most comprehensive and traditional tarot spread with 10 cards.",
                instructions: "Clear your mind and focus deeply on your question before drawing.",
                tags: ["advanced", "comprehensive", "traditional"]
            ),
            TarotSpread(
                id: "daily_guidance",
                positions: [
                    SpreadPosition(id: 1, x: 0.5, y: 0.5, rotation: 0.0, name: "Guidance", meaning: "Your guidance for today")
                ],
                imageUrl: nil,
                name: "Daily Guidance",
                description: "A single card for daily insight and guidance.",
                instructions: "Take a deep breath and ask for guidance for the day ahead.",
                tags: ["daily", "quick", "beginner"]
            )
        ]
    }

    func createUserSpread(spreadId: String) async -> UserSpread {
        await simulateDelay(0.8)
        let spreads = await getAvailableSpreads()
        let spread = spreads.first(where: { $0.id == spreadId }) ?? spreads[0]
        return UserSpread(
            id: 42,
            spreadId: spreadId,
            createdAt: "2024-11-20T15:00:00",
            spread: spread
        )
    }

    // MARK: - Clarifying Questions

    func getClarifyingQuestions(message: String) async -> [ClarifyingQuestion] {
        await simulateDelay(1.0)
        return [
            ClarifyingQuestion(
                question: "How long have you been in your current position?",
                options: [
                    QuestionOption(label: "A", text: "Less than 1 year"),
                    QuestionOption(label: "B", text: "1-3 years"),
                    QuestionOption(label: "C", text: "More than 3 years")
                ]
            ),
            ClarifyingQuestion(
                question: "How would you describe your relationship with your supervisor?",
                options: [
                    QuestionOption(label: "A", text: "Very supportive and encouraging"),
                    QuestionOption(label: "B", text: "Neutral, mostly professional"),
                    QuestionOption(label: "C", text: "Tense or challenging")
                ]
            ),
            ClarifyingQuestion(
                question: "What aspect of a promotion matters most to you right now?",
                options: [
                    QuestionOption(label: "A", text: "Financial growth and stability"),
                    QuestionOption(label: "B", text: "Recognition and career advancement"),
                    QuestionOption(label: "C", text: "New responsibilities and challenges")
                ]
            )
        ]
    }

    // MARK: - Card Drawing

    private let mockCards: [UserCard] = [
        UserCard(
            id: 101,
            position: .upright,
            cardId: 18,
            card: TarotCard(
                cardId: 18,
                arcanaType: .majorArcana,
                number: 17,
                suit: nil,
                element: "air",
                imageUrl: nil,
                name: "The Star",
                description: "A woman kneels by a pool, pouring water onto the land and into the pool. Above her, eight stars shine brightly in the night sky.",
                uprightMeaning: "Hope, faith, renewal, serenity, inspiration",
                reversedMeaning: "Lack of faith, despair, disconnection, insecurity",
                keywords: ["hope", "faith", "renewal", "inspiration", "serenity"]
            )
        ),
        UserCard(
            id: 102,
            position: .reversed,
            cardId: 35,
            card: TarotCard(
                cardId: 35,
                arcanaType: .minor,
                number: 9,
                suit: .cups,
                element: "water",
                imageUrl: nil,
                name: "Nine of Cups",
                description: "A satisfied figure sits with arms crossed before a curved shelf displaying nine golden cups.",
                uprightMeaning: "Contentment, satisfaction, gratitude, wish fulfillment",
                reversedMeaning: "Inner happiness, materialism, dissatisfaction, indulgence",
                keywords: ["satisfaction", "contentment", "gratitude", "wishes"]
            )
        ),
        UserCard(
            id: 103,
            position: .upright,
            cardId: 62,
            card: TarotCard(
                cardId: 62,
                arcanaType: .minor,
                number: 3,
                suit: .pentacles,
                element: "earth",
                imageUrl: nil,
                name: "Three of Pentacles",
                description: "An artisan works on a cathedral archway while two figures observe and consult plans.",
                uprightMeaning: "Teamwork, collaboration, learning, implementation",
                reversedMeaning: "Disharmony, misalignment, working alone, lack of skill",
                keywords: ["teamwork", "collaboration", "craftsmanship", "learning"]
            )
        )
    ]

    func drawCard(spreadId: Int, cardIndex: Int) async -> UserCard {
        await simulateDelay(0.5)
        let index = min(cardIndex, mockCards.count - 1)
        return mockCards[max(0, index)]
    }

    // MARK: - Readings

    func createReading(mainQuestion: String, userSpreadId: Int, questions: [ClarifyingQuestion], answers: [String]) async -> ReadingResponse {
        await simulateDelay(1.5)
        return makeFullReadingResponse()
    }

    func getReadings() async -> [ReadingListItemResponse] {
        await simulateDelay(0.8)
        return [
            ReadingListItemResponse(
                id: 5,
                spreadId: "three_card_spread",
                mainQuestion: "Will I get promoted at work this year?",
                cards: [
                    ReadingListCardResponse(cardId: 18, cardName: "The Star", cardPosition: "upright"),
                    ReadingListCardResponse(cardId: 35, cardName: "Nine of Cups", cardPosition: "reversed"),
                    ReadingListCardResponse(cardId: 62, cardName: "Three of Pentacles", cardPosition: "upright")
                ],
                createdAt: "2024-11-20T15:05:30"
            ),
            ReadingListItemResponse(
                id: 3,
                spreadId: "celtic_cross",
                mainQuestion: "What should I focus on for personal growth?",
                cards: [
                    ReadingListCardResponse(cardId: 0, cardName: "The Fool", cardPosition: "upright"),
                    ReadingListCardResponse(cardId: 21, cardName: "The World", cardPosition: "upright"),
                    ReadingListCardResponse(cardId: 45, cardName: "Ace of Swords", cardPosition: "reversed"),
                    ReadingListCardResponse(cardId: 12, cardName: "The Hanged Man", cardPosition: "upright"),
                    ReadingListCardResponse(cardId: 56, cardName: "Seven of Pentacles", cardPosition: "upright"),
                    ReadingListCardResponse(cardId: 29, cardName: "Three of Cups", cardPosition: "reversed"),
                    ReadingListCardResponse(cardId: 8, cardName: "Strength", cardPosition: "upright"),
                    ReadingListCardResponse(cardId: 41, cardName: "Five of Swords", cardPosition: "reversed"),
                    ReadingListCardResponse(cardId: 67, cardName: "Queen of Pentacles", cardPosition: "upright"),
                    ReadingListCardResponse(cardId: 15, cardName: "The Devil", cardPosition: "reversed")
                ],
                createdAt: "2024-11-18T09:12:00"
            )
        ]
    }

    func getReadingDetail(id: Int) async -> ReadingResponse {
        await simulateDelay(0.8)
        return makeFullReadingResponse()
    }

    // MARK: - Private Helpers

    private func makeFullReadingResponse() -> ReadingResponse {
        ReadingResponse(
            id: 5,
            spreadId: "three_card_spread",
            userSpreadId: 42,
            mainQuestion: "Will I get promoted at work this year?",
            questionType: "CAREER",
            cards: [
                ReadingCardResponse(
                    position: 1,
                    positionName: "Past",
                    cardId: 18,
                    cardName: "The Star",
                    cardPosition: "upright",
                    cardSuit: nil,
                    symbolicConnection: "The Star in your past position reveals a period of renewed hope and inspiration that has been quietly guiding your professional journey. You've been planting seeds of faith in your abilities, and this celestial energy has been working behind the scenes to align opportunities with your true potential.",
                    tarotInsight: "Your past efforts have created a foundation of genuine talent and dedication that hasn't gone unnoticed. The Star's presence here suggests you've already proven yourself through consistent, quality work rather than self-promotion — and this authentic approach has built a solid reputation."
                ),
                ReadingCardResponse(
                    position: 2,
                    positionName: "Present",
                    cardId: 35,
                    cardName: "Nine of Cups",
                    cardPosition: "reversed",
                    cardSuit: "cups",
                    symbolicConnection: "The reversed Nine of Cups in your present position suggests that while external success metrics look favorable, there's an inner questioning about whether this promotion will truly bring the fulfillment you seek. You may be chasing a title rather than genuine satisfaction.",
                    tarotInsight: "Right now, you're at a crossroads between what you think you should want and what actually fulfills you. The reversed wish card asks you to examine your true motivations — is this promotion about proving something to others, or does it align with your deeper career aspirations?"
                ),
                ReadingCardResponse(
                    position: 3,
                    positionName: "Future",
                    cardId: 62,
                    cardName: "Three of Pentacles",
                    cardPosition: "upright",
                    cardSuit: "pentacles",
                    symbolicConnection: "The Three of Pentacles in your future position is a powerful indicator of collaborative success and skill recognition. This card suggests that advancement will come through demonstrating your expertise in a team context — your ability to work with others will be the key differentiator.",
                    tarotInsight: "The path forward involves actively showcasing your collaborative skills and technical mastery. A promotion is likely, but it will come through a specific project or initiative where your contributions are clearly visible. Focus on team achievements rather than solo accomplishments in the coming months."
                )
            ],
            insights: [
                InsightItem(
                    type: "blind_spot",
                    text: "You may be underestimating how much your colleagues and supervisors already value your work. Your supportive supervisor likely sees more potential in you than you realize — consider having a direct conversation about your career goals."
                ),
                InsightItem(
                    type: "pattern",
                    text: "There's a recurring theme of quiet competence in your reading. While this is admirable, the cards suggest that making your achievements more visible — not through boasting, but through strategic communication — will accelerate your advancement."
                ),
                InsightItem(
                    type: "trigger_event",
                    text: "Watch for an upcoming collaborative project or cross-team initiative. The Three of Pentacles strongly suggests this will be the catalyst for your promotion, likely within the next 3-6 months."
                )
            ],
            result: "The cards paint a promising picture for your career advancement. Your past dedication (The Star) has built a solid foundation, though the reversed Nine of Cups in the present urges you to clarify your true motivations before pushing forward. The Three of Pentacles in your future is one of the strongest indicators of professional recognition through teamwork. The promotion is likely, but it will come through demonstrating collaborative excellence rather than individual ambition. Your supportive supervisor is an asset — don't hesitate to communicate your goals openly. Focus on an upcoming team project as your vehicle for advancement, and ensure your contributions are visible to decision-makers.",
            createdAt: "2024-11-20T15:05:30"
        )
    }

    private func simulateDelay(_ seconds: Double) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
