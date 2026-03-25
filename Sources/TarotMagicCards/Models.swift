import Foundation

// MARK: - Spread Models

/* SKIP @bridge */
enum SpreadID: String, Codable, Hashable, CaseIterable {
    case celticCross = "celtic_cross"
    case dailyGuidance = "daily_guidance"
    case horseshoe = "horseshoe"
    case relationship = "relationship"
    case threeCardSpread = "three_card_spread"
}

/* SKIP @bridge */
struct SpreadPosition: Codable, Hashable, Identifiable {
    var id: Int
    var x: Double
    var y: Double
    var rotation: Double = 0.0
    var name: String
    var meaning: String
}

/* SKIP @bridge */
struct TarotSpread: Codable, Hashable, Identifiable {
    var id: String
    var positions: [SpreadPosition]
    var imageUrl: String?
    var name: String
    var description: String
    var instructions: String
    var tags: [String]

    var spreadID: SpreadID? {
        SpreadID(rawValue: id)
    }

    enum CodingKeys: String, CodingKey {
        case id, positions
        case imageUrl = "image_url"
        case name, description, instructions, tags
    }
}

/* SKIP @bridge */
struct UserSpread: Codable, Hashable, Identifiable {
    var id: Int
    var spreadId: String
    var createdAt: String
    var spread: TarotSpread

    enum CodingKeys: String, CodingKey {
        case id
        case spreadId = "spread_id"
        case createdAt = "created_at"
        case spread
    }
}

// MARK: - Card Models

/* SKIP @bridge */
enum ArcanaType: String, Codable, Hashable {
    case majorArcana = "major_arcana"
    case minor = "minor"
}

/* SKIP @bridge */
enum Suit: String, Codable, Hashable {
    case wands
    case cups
    case swords
    case pentacles
}

/* SKIP @bridge */
enum CardOrientation: String, Codable, Hashable {
    case upright
    case reversed
}

/* SKIP @bridge */
struct TarotCard: Codable, Hashable, Identifiable {
    var id: Int { cardId }
    var cardId: Int
    var arcanaType: ArcanaType
    var number: Int
    var suit: Suit?
    var element: String?
    var imageUrl: String?
    var name: String
    var description: String
    var uprightMeaning: String
    var reversedMeaning: String
    var keywords: [String]

    enum CodingKeys: String, CodingKey {
        case cardId = "card_id"
        case arcanaType = "arcana_type"
        case number, suit, element
        case imageUrl = "image_url"
        case name, description
        case uprightMeaning = "upright_meaning"
        case reversedMeaning = "reversed_meaning"
        case keywords
    }
}

/* SKIP @bridge */
struct UserCard: Codable, Hashable, Identifiable {
    var id: Int
    var position: CardOrientation
    var cardId: Int
    var card: TarotCard

    enum CodingKeys: String, CodingKey {
        case id
        case position
        case cardId = "card_id"
        case card
    }
}

// MARK: - Quiz Models

/* SKIP @bridge */
struct QuestionOption: Codable, Hashable {
    var label: String
    var text: String
}

/* SKIP @bridge */
struct ClarifyingQuestion: Codable, Hashable {
    var question: String
    var options: [QuestionOption]
}

// MARK: - Reading Models

/* SKIP @bridge */
struct ReadingCardResponse: Codable, Hashable, Identifiable {
    var id: Int { position }
    var position: Int
    var positionName: String
    var cardId: Int
    var cardName: String
    var cardPosition: String
    var cardSuit: String?
    var symbolicConnection: String
    var tarotInsight: String

    enum CodingKeys: String, CodingKey {
        case position
        case positionName = "position_name"
        case cardId = "card_id"
        case cardName = "card_name"
        case cardPosition = "card_position"
        case cardSuit = "card_suit"
        case symbolicConnection = "symbolic_connection"
        case tarotInsight = "tarot_insight"
    }
}

/* SKIP @bridge */
struct InsightItem: Codable, Hashable {
    var type: String
    var text: String
}

/* SKIP @bridge */
struct ReadingResponse: Codable, Hashable, Identifiable {
    var id: Int
    var spreadId: String
    var userSpreadId: Int?
    var mainQuestion: String
    var questionType: String?
    var cards: [ReadingCardResponse]
    var insights: [InsightItem]
    var result: String
    var createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case spreadId = "spread_id"
        case userSpreadId = "user_spread_id"
        case mainQuestion = "main_question"
        case questionType = "question_type"
        case cards, insights, result
        case createdAt = "created_at"
    }
}

/* SKIP @bridge */
struct ReadingListCardResponse: Codable, Hashable {
    var cardId: Int
    var cardName: String
    var cardPosition: String

    enum CodingKeys: String, CodingKey {
        case cardId = "card_id"
        case cardName = "card_name"
        case cardPosition = "card_position"
    }
}

/* SKIP @bridge */
struct ReadingListItemResponse: Codable, Hashable, Identifiable {
    var id: Int
    var spreadId: String
    var mainQuestion: String
    var cards: [ReadingListCardResponse]
    var createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case spreadId = "spread_id"
        case mainQuestion = "main_question"
        case cards
        case createdAt = "created_at"
    }
}
