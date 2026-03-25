# Tarot Magic Cards — Application API Flow

This document describes every API call the mobile application makes to the backend,
in the order they occur during a typical user session. Each step includes request/response
examples and error handling notes.

**Base URL:** `https://api.example.com`
**API Prefix:** `/api/v1`

---

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        APPLICATION FLOW                                │
│                                                                        │
│  ┌──────────┐    ┌───────────┐    ┌─────────────┐    ┌──────────────┐  │
│  │ Firebase  │───>│   Login   │───>│  App Screen │───>│ Ask Question │  │
│  │  Auth     │    │ POST      │    │ GET /me     │    │ (local)      │  │
│  │ (client)  │    │ /auth/    │    │ GET /spreads│    │              │  │
│  └──────────┘    │  login    │    │  /all       │    └──────┬───────┘  │
│                  └───────────┘    └─────────────┘           │          │
│                                                             v          │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────────────┐  │
│  │ Quiz         │<───│   Spread     │<───│ Spread Selection         │  │
│  │ POST /insides│    │   Selection  │    │ GET /spreads/all         │  │
│  │ /clarifying- │    │ POST /spreads│    │ POST /spreads/           │  │
│  │  questions/  │    │              │    └──────────────────────────┘  │
│  └──────┬───────┘    └──────────────┘                                 │
│         │                                                              │
│         v                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────────────┐  │
│  │ Card Drawing │───>│ Create       │───>│ Reveal Cards             │  │
│  │ POST /spreads│    │ Reading      │    │ (no API call — uses      │  │
│  │ /{id}/       │    │ POST         │    │  ReadingResponse)        │  │
│  │  draw-card   │    │ /readings    │    └──────────┬───────────────┘  │
│  │ (N times)    │    └──────────────┘               │                  │
│  └──────────────┘                                   v                  │
│                                          ┌──────────────────────────┐  │
│  ┌──────────────┐                        │ Final Result             │  │
│  │ History      │                        │ (no API call — uses      │  │
│  │ GET /readings│                        │  ReadingResponse)        │  │
│  │ GET /readings│                        └──────────────────────────┘  │
│  │  /{id}       │                                                      │
│  └──────────────┘                                                      │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ Token Refresh: POST /auth/token/refresh (when 401 received)     │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

**Sequence summary:**

```
Firebase (client-side)
  └─> POST /auth/login
        └─> GET /users/me
        └─> GET /spreads/all
              └─> User types/speaks question (local)
                    └─> POST /spreads/  (create user spread)
                          └─> POST /insides/clarifying-questions/
                                └─> User answers quiz (local)
                                      └─> POST /spreads/{id}/draw-card  (×N)
                                            └─> POST /readings  (create reading)
                                                  └─> Reveal cards (local, from response)
                                                        └─> Final result (local, from response)

At any time:
  └─> GET /readings  (history list)
        └─> GET /readings/{id}  (reading detail)

On 401:
  └─> POST /auth/token/refresh
```

---

## Common Headers

All authenticated requests must include:

```
Authorization: Bearer <access_token>
Accept-Language: en        (or "ru" for Russian)
Content-Type: application/json
```

The `Accept-Language` header controls:
- i18n fields in cards and spreads (name, description, etc.)
- Language of AI-generated content (clarifying questions, readings)

---

## Step 0: Authentication

Authentication is a prerequisite for all protected endpoints. The app uses Firebase
for client-side authentication, then exchanges the Firebase token for backend JWT tokens.

### 0.1 Login — `POST /api/v1/auth/login`

Exchange a Firebase ID token for backend JWT access and refresh tokens.

**Auth required:** No

**Request:**

```http
POST /api/v1/auth/login
Content-Type: application/json
```

```json
{
  "token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vdGFyb3QtbWFnaWMiLCJhdWQiOiJ0YXJvdC1tYWdpYyIsInN1YiI6ImZpcmViYXNlLXVpZC0xMjM0NTYiLCJlbWFpbCI6InVzZXJAZXhhbXBsZS5jb20ifQ.signature"
}
```

**Response (200 OK):**

```json
{
  "user_id": 1,
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjEsImV4dGVybmFsX2lkIjoiZmlyZWJhc2UtdWlkLTEyMzQ1NiIsImV4cCI6MTcwOTMxODAwMH0.abc123",
  "token_type": "bearer",
  "refresh_token": "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2g3h4i5j6k7l8m9n0o1p2q3r4s5t6u7v8w9x0y1z2a3b4c5d6e7f8",
  "access_token_expires_in": 3600,
  "refresh_token_expires_in": 2592000
}
```

**Notes:**
- `access_token` is a JWT valid for 1 hour (3600 seconds)
- `refresh_token` is a 128-character random string valid for 30 days
- The server validates the Firebase token, creates or finds the user in the database, and issues JWT tokens
- Store both tokens securely on the device

**Error handling:**
- `401 Unauthorized` — Invalid or expired Firebase token
- `400 Bad Request` — Missing or malformed token field

---

### 0.2 Token Refresh — `POST /api/v1/auth/token/refresh`

Refresh an expired access token using the refresh token.

**Auth required:** No

**When to call:** When any authenticated request returns `401 Unauthorized`, attempt a token refresh before re-sending the original request.

**Request:**

```http
POST /api/v1/auth/token/refresh
Content-Type: application/json
```

```json
{
  "refresh_token": "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2g3h4i5j6k7l8m9n0o1p2q3r4s5t6u7v8w9x0y1z2a3b4c5d6e7f8"
}
```

**Response (200 OK):**

```json
{
  "user_id": 1,
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjEsImV4dGVybmFsX2lkIjoiZmlyZWJhc2UtdWlkLTEyMzQ1NiIsImV4cCI6MTcwOTMyMTYwMH0.xyz789",
  "token_type": "bearer",
  "refresh_token": "z9y8x7w6v5u4t3s2r1q0p9o8n7m6l5k4j3i2h1g0f9e8d7c6b5a4z3y2x1w0v9u8t7s6r5q4p3o2n1m0l9k8j7i6h5g4f3e2d1c0b9a8",
  "access_token_expires_in": 3600,
  "refresh_token_expires_in": 2592000
}
```

**Notes:**
- Both access and refresh tokens are rotated — store the new tokens
- If the refresh token is also expired, redirect the user to re-authenticate with Firebase

**Error handling:**
- `401 Unauthorized` — Invalid or expired refresh token; user must re-login via Firebase

---

## Step 1: App Screen (Main Screen)

After login, the app loads the user profile and available spread types.

### 1.1 Get User Profile — `GET /api/v1/users/me`

**Auth required:** Yes

**Request:**

```http
GET /api/v1/users/me
Authorization: Bearer <access_token>
Accept-Language: en
```

**Response (200 OK):**

```json
{
  "id": 1,
  "external_id": "firebase-uid-123456",
  "name": "Elena Petrova",
  "email": "elena@example.com",
  "created_at": "2024-06-15T10:30:00",
  "updated_at": "2024-11-20T14:22:00"
}
```

**Notes:**
- `name` and `email` may be `null` if not provided during Firebase registration
- Used to display user info in the app header/profile section

**Error handling:**
- `401 Unauthorized` — Token expired or invalid; trigger token refresh
- `404 Not Found` — User record not in database (should not happen after login)

---

### 1.2 Get Available Spreads — `GET /api/v1/spreads/all`

**Auth required:** No

**Request:**

```http
GET /api/v1/spreads/all
Accept-Language: en
```

**Response (200 OK):**

```json
[
  {
    "id": "three_card_spread",
    "image_url": "https://cdn.example.com/spreads/three_card.png",
    "name": "Three Card Spread",
    "description": "A simple three-card layout exploring past, present, and future influences.",
    "instructions": "Focus on your question, then draw three cards one at a time.",
    "tags": ["beginner", "quick", "general"],
    "positions": [
      {
        "id": 1,
        "x": 0.17,
        "y": 0.5,
        "rotation": 0.0,
        "name": "Past",
        "meaning": "Events and influences from the past that affect the situation"
      },
      {
        "id": 2,
        "x": 0.5,
        "y": 0.5,
        "rotation": 0.0,
        "name": "Present",
        "meaning": "Current circumstances and energies surrounding the question"
      },
      {
        "id": 3,
        "x": 0.83,
        "y": 0.5,
        "rotation": 0.0,
        "name": "Future",
        "meaning": "The likely outcome or direction based on current energies"
      }
    ]
  },
  {
    "id": "celtic_cross",
    "image_url": "https://cdn.example.com/spreads/celtic_cross.png",
    "name": "Celtic Cross",
    "description": "The most comprehensive and traditional tarot spread with 10 cards.",
    "instructions": "Clear your mind and focus deeply on your question before drawing.",
    "tags": ["advanced", "comprehensive", "traditional"],
    "positions": [
      {
        "id": 1,
        "x": 0.35,
        "y": 0.5,
        "rotation": 0.0,
        "name": "Present",
        "meaning": "The current situation or question"
      },
      {
        "id": 2,
        "x": 0.35,
        "y": 0.5,
        "rotation": 90.0,
        "name": "Challenge",
        "meaning": "The immediate challenge or obstacle"
      }
    ]
  },
  {
    "id": "daily_guidance",
    "image_url": null,
    "name": "Daily Guidance",
    "description": "A single card for daily insight and guidance.",
    "instructions": "Take a deep breath and ask for guidance for the day ahead.",
    "tags": ["daily", "quick", "beginner"],
    "positions": [
      {
        "id": 1,
        "x": 0.5,
        "y": 0.5,
        "rotation": 0.0,
        "name": "Guidance",
        "meaning": "Your guidance for today"
      }
    ]
  }
]
```

**Notes:**
- Spreads are loaded from YAML definitions; the list is static and can be cached
- `positions` array determines how many cards the user must draw
- `x`, `y` are normalized coordinates (0.0 to 1.0) for card placement in the UI
- `rotation` is in degrees (e.g., 90.0 for a crossed card in Celtic Cross)
- `image_url` may be `null`
- Text fields (`name`, `description`, `instructions`, position `name`/`meaning`) are i18n-resolved based on `Accept-Language`

**Error handling:**
- This endpoint has no expected error cases; always returns a list (possibly empty)

---

## Step 2: First Question (Voice/Text Input)

No API call at this step.

The user enters their question via text input or voice recording. The question text is
captured and stored locally on the device for use in later steps (clarifying questions
and reading creation).

Example question stored locally: `"Will I get promoted at work this year?"`

---

## Step 3: Spread Selection

The user selects a spread type and the app creates a user spread session.

### 3.1 List Spreads — `GET /api/v1/spreads/all`

Same as Step 1.2 above. If the spread list was already fetched and cached, this call
can be skipped.

### 3.2 Create User Spread — `POST /api/v1/spreads/`

After the user picks a spread, create a spread session to track their card draws.

**Auth required:** Yes

**Request:**

```http
POST /api/v1/spreads/
Authorization: Bearer <access_token>
Content-Type: application/json
```

```json
{
  "spread_id": "three_card_spread"
}
```

> **Note:** The `spread_id` value must match one of the `id` values returned by `GET /api/v1/spreads/all`.

**Response (200 OK):**

```json
{
  "id": 42,
  "spread_id": "three_card_spread",
  "created_at": "2024-11-20T15:00:00",
  "spread": {
    "id": "three_card_spread",
    "image_url": "https://cdn.example.com/spreads/three_card.png",
    "name": "Three Card Spread",
    "description": "A simple three-card layout exploring past, present, and future influences.",
    "instructions": "Focus on your question, then draw three cards one at a time.",
    "tags": ["beginner", "quick", "general"],
    "positions": [
      {
        "id": 1,
        "x": 0.17,
        "y": 0.5,
        "rotation": 0.0,
        "name": "Past",
        "meaning": "Events and influences from the past that affect the situation"
      },
      {
        "id": 2,
        "x": 0.5,
        "y": 0.5,
        "rotation": 0.0,
        "name": "Present",
        "meaning": "Current circumstances and energies surrounding the question"
      },
      {
        "id": 3,
        "x": 0.83,
        "y": 0.5,
        "rotation": 0.0,
        "name": "Future",
        "meaning": "The likely outcome or direction based on current energies"
      }
    ]
  }
}
```

**Notes:**
- Save the `id` (42 in this example) — this is the `user_spread_id` needed for drawing cards and creating the reading
- `spread_id` must be a valid spread ID from the spreads list
- Each call creates a new independent spread session

**Error handling:**
- `401 Unauthorized` — Token expired; trigger refresh
- `422 Unprocessable Entity` — Invalid `spread_id` (not in the allowed spread types)

---

## Step 4: Quiz (Clarifying Questions)

The app sends the user's main question to get AI-generated clarifying questions.

### 4.1 Get Clarifying Questions — `POST /api/v1/insides/clarifying-questions/`

**Auth required:** Yes

**Request:**

```http
POST /api/v1/insides/clarifying-questions/
Authorization: Bearer <access_token>
Accept-Language: en
Content-Type: application/json
```

```json
{
  "message": "Will I get promoted at work this year?"
}
```

**Response (201 Created):**

```json
{
  "response": {
    "content": {
      "type": "clarifying_questions",
      "questions": [
        {
          "question": "How long have you been in your current position?",
          "options": [
            { "label": "A", "text": "Less than 1 year" },
            { "label": "B", "text": "1-3 years" },
            { "label": "C", "text": "More than 3 years" }
          ]
        },
        {
          "question": "How would you describe your relationship with your supervisor?",
          "options": [
            { "label": "A", "text": "Very supportive and encouraging" },
            { "label": "B", "text": "Neutral, mostly professional" },
            { "label": "C", "text": "Tense or challenging" }
          ]
        },
        {
          "question": "What aspect of a promotion matters most to you right now?",
          "options": [
            { "label": "A", "text": "Financial growth and stability" },
            { "label": "B", "text": "Recognition and career advancement" },
            { "label": "C", "text": "New responsibilities and challenges" }
          ]
        }
      ]
    },
    "type": "ai",
    "timestamp": "2024-11-20T15:01:30.123456+00:00"
  }
}
```

**Notes:**
- The `questions` array may be empty if the AI determines no clarification is needed
- Store the questions and the user's selected answers locally for use in reading creation (Step 6)
- Each question has multiple choice options with `label` and `text`
- The user selects one option per question; the selected `text` values become the `answers` array in the reading request

**Error handling:**
- `401 Unauthorized` — Token expired; trigger refresh
- `500 Internal Server Error` — OpenAI API failure; show a generic error and allow retry
- `502 Bad Gateway` — AI response could not be parsed; show a generic error and allow retry

---

## Step 5: Cards (Card Drawing)

The user draws cards one at a time. Each draw is a separate API call. The number of
draws equals the number of positions in the selected spread.

### 5.1 Draw a Card — `POST /api/v1/spreads/{spread_id}/draw-card`

Call this endpoint once for each card position in the spread. For a Three Card Spread,
call it 3 times. For Celtic Cross, call it 10 times.

**Auth required:** Yes

**Path parameter:** `spread_id` — the numeric ID of the user spread (from Step 3.2, e.g., `42`)

**Request:**

```http
POST /api/v1/spreads/42/draw-card
Authorization: Bearer <access_token>
Accept-Language: en
```

No request body.

**Response — First draw (200 OK):**

```json
{
  "id": 101,
  "card_id": 18,
  "position": "upright",
  "card": {
    "card_id": 18,
    "arcana_type": "major_arcana",
    "number": 17,
    "suit": null,
    "element": "air",
    "image_url": "https://cdn.example.com/cards/17_the_star.png",
    "name": "The Star",
    "description": "A woman kneels by a pool, pouring water onto the land and into the pool. Above her, eight stars shine brightly in the night sky.",
    "upright_meaning": "Hope, faith, renewal, serenity, inspiration",
    "reversed_meaning": "Lack of faith, despair, disconnection, insecurity",
    "keywords": ["hope", "faith", "renewal", "inspiration", "serenity"],
    "upright_relationships": "A period of healing and renewed hope in relationships.",
    "upright_career": "Creative inspiration and recognition at work.",
    "symbolism": "The eight-pointed stars represent cosmic order and divine guidance."
  }
}
```

**Response — Second draw (200 OK):**

```json
{
  "id": 102,
  "card_id": 35,
  "position": "reversed",
  "card": {
    "card_id": 35,
    "arcana_type": "minor",
    "number": 9,
    "suit": "cups",
    "element": "water",
    "image_url": "https://cdn.example.com/cards/cups_09.png",
    "name": "Nine of Cups",
    "description": "A satisfied figure sits with arms crossed before a curved shelf displaying nine golden cups.",
    "upright_meaning": "Contentment, satisfaction, gratitude, wish fulfillment",
    "reversed_meaning": "Inner happiness, materialism, dissatisfaction, indulgence",
    "keywords": ["satisfaction", "contentment", "gratitude", "wishes"],
    "upright_relationships": "Deep emotional satisfaction and fulfillment in love.",
    "upright_career": "Achievement of professional goals and satisfaction.",
    "symbolism": "The nine cups arranged in an arc represent emotional abundance."
  }
}
```

**Response — Third draw (200 OK):**

```json
{
  "id": 103,
  "card_id": 62,
  "position": "upright",
  "card": {
    "card_id": 62,
    "arcana_type": "minor",
    "number": 3,
    "suit": "pentacles",
    "element": "earth",
    "image_url": "https://cdn.example.com/cards/pentacles_03.png",
    "name": "Three of Pentacles",
    "description": "An artisan works on a cathedral archway while two figures observe and consult plans.",
    "upright_meaning": "Teamwork, collaboration, learning, implementation",
    "reversed_meaning": "Disharmony, misalignment, working alone, lack of skill",
    "keywords": ["teamwork", "collaboration", "craftsmanship", "learning"],
    "upright_relationships": "Building something meaningful together through shared effort.",
    "upright_career": "Recognition of skills, teamwork leading to success.",
    "symbolism": "The three pentacles in the archway represent mastery through collaboration."
  }
}
```

**Notes:**
- Cards are randomly selected from the full 78-card deck, excluding cards already drawn in this spread (no duplicates)
- `position` is randomly assigned as `"upright"` or `"reversed"`
- The draw order determines position assignment: first draw = first position, etc.
- `suit` is `null` for Major Arcana cards
- `element`, `image_url`, `upright_relationships`, `upright_career`, `symbolism` may be `null`
- After drawing all cards, proceed to create the reading (Step 6)
- The card drawing happens while the user interacts with the deck animation; start the reading creation as soon as all cards are drawn

**Error handling:**
- `401 Unauthorized` — Token expired; trigger refresh
- `404 Not Found` — Spread not found or not owned by the current user
- `409 Conflict` — All positions already filled; all cards have been drawn for this spread

---

## Step 6: Create Reading

After all cards are drawn, send the collected data to create the reading. This invokes
the AI to generate card interpretations, insights, and the overall reading result.

### 6.1 Create Reading — `POST /api/v1/readings`

**Auth required:** Yes

**Request:**

```http
POST /api/v1/readings
Authorization: Bearer <access_token>
Accept-Language: en
Content-Type: application/json
```

```json
{
  "main_question": "Will I get promoted at work this year?",
  "user_spread_id": 42,
  "clarifying_questions": [
    {
      "question": "How long have you been in your current position?",
      "options": [
        { "label": "A", "text": "Less than 1 year" },
        { "label": "B", "text": "1-3 years" },
        { "label": "C", "text": "More than 3 years" }
      ]
    },
    {
      "question": "How would you describe your relationship with your supervisor?",
      "options": [
        { "label": "A", "text": "Very supportive and encouraging" },
        { "label": "B", "text": "Neutral, mostly professional" },
        { "label": "C", "text": "Tense or challenging" }
      ]
    },
    {
      "question": "What aspect of a promotion matters most to you right now?",
      "options": [
        { "label": "A", "text": "Financial growth and stability" },
        { "label": "B", "text": "Recognition and career advancement" },
        { "label": "C", "text": "New responsibilities and challenges" }
      ]
    }
  ],
  "answers": [
    "1-3 years",
    "Very supportive and encouraging",
    "Recognition and career advancement"
  ]
}
```

**Response (201 Created):**

```json
{
  "id": 5,
  "spread_id": "three_card_spread",
  "user_spread_id": 42,
  "main_question": "Will I get promoted at work this year?",
  "question_type": "CAREER",
  "cards": [
    {
      "position": 1,
      "position_name": "Past",
      "card_id": 18,
      "card_name": "The Star",
      "card_position": "upright",
      "card_suit": null,
      "symbolic_connection": "The Star in your past position reveals a period of renewed hope and inspiration that has been quietly guiding your professional journey. You've been planting seeds of faith in your abilities, and this celestial energy has been working behind the scenes to align opportunities with your true potential.",
      "tarot_insight": "Your past efforts have created a foundation of genuine talent and dedication that hasn't gone unnoticed. The Star's presence here suggests you've already proven yourself through consistent, quality work rather than self-promotion — and this authentic approach has built a solid reputation."
    },
    {
      "position": 2,
      "position_name": "Present",
      "card_id": 35,
      "card_name": "Nine of Cups",
      "card_position": "reversed",
      "card_suit": "cups",
      "symbolic_connection": "The reversed Nine of Cups in your present position suggests that while external success metrics look favorable, there's an inner questioning about whether this promotion will truly bring the fulfillment you seek. You may be chasing a title rather than genuine satisfaction.",
      "tarot_insight": "Right now, you're at a crossroads between what you think you should want and what actually fulfills you. The reversed wish card asks you to examine your true motivations — is this promotion about proving something to others, or does it align with your deeper career aspirations?"
    },
    {
      "position": 3,
      "position_name": "Future",
      "card_id": 62,
      "card_name": "Three of Pentacles",
      "card_position": "upright",
      "card_suit": "pentacles",
      "symbolic_connection": "The Three of Pentacles in your future position is a powerful indicator of collaborative success and skill recognition. This card suggests that advancement will come through demonstrating your expertise in a team context — your ability to work with others will be the key differentiator.",
      "tarot_insight": "The path forward involves actively showcasing your collaborative skills and technical mastery. A promotion is likely, but it will come through a specific project or initiative where your contributions are clearly visible. Focus on team achievements rather than solo accomplishments in the coming months."
    }
  ],
  "insights": [
    {
      "type": "blind_spot",
      "text": "You may be underestimating how much your colleagues and supervisors already value your work. Your supportive supervisor likely sees more potential in you than you realize — consider having a direct conversation about your career goals."
    },
    {
      "type": "pattern",
      "text": "There's a recurring theme of quiet competence in your reading. While this is admirable, the cards suggest that making your achievements more visible — not through boasting, but through strategic communication — will accelerate your advancement."
    },
    {
      "type": "trigger_event",
      "text": "Watch for an upcoming collaborative project or cross-team initiative. The Three of Pentacles strongly suggests this will be the catalyst for your promotion, likely within the next 3-6 months."
    }
  ],
  "result": "The cards paint a promising picture for your career advancement. Your past dedication (The Star) has built a solid foundation, though the reversed Nine of Cups in the present urges you to clarify your true motivations before pushing forward. The Three of Pentacles in your future is one of the strongest indicators of professional recognition through teamwork. The promotion is likely, but it will come through demonstrating collaborative excellence rather than individual ambition. Your supportive supervisor is an asset — don't hesitate to communicate your goals openly. Focus on an upcoming team project as your vehicle for advancement, and ensure your contributions are visible to decision-makers.",
  "created_at": "2024-11-20T15:05:30"
}
```

**Notes:**
- `main_question` must be 1-5000 characters
- `clarifying_questions` and `answers` arrays must have the same length; if no quiz was done, both can be empty arrays `[]`
- `answers` should contain the selected option `text` values (not labels)
- The `user_spread_id` must reference a spread where all positions have been filled (all cards drawn)
- `question_type` is AI-determined (e.g., "CAREER", "LOVE", "GENERAL")
- Card order in the response corresponds to draw order (first drawn = position 1)
- `card_suit` is `null` for Major Arcana cards
- This response contains all data needed for Steps 7 and 8 — no additional API calls required
- This call may take several seconds due to AI processing

**Error handling:**
- `401 Unauthorized` — Token expired; trigger refresh
- `404 Not Found` — `user_spread_id` not found or not owned by the current user
- `409 Conflict` — Spread is not fully drawn (not all card positions filled yet); draw remaining cards first
- `422 Unprocessable Entity` — Validation errors:
  - `clarifying_questions` and `answers` arrays have different lengths
  - `main_question` is empty or exceeds 5000 characters
- `500 Internal Server Error` — OpenAI API failure; show error and allow retry
- `502 Bad Gateway` — AI response parsing failed (wrong format or card count mismatch); retry

---

## Step 7: Reveal Card by Card

No additional API call. Uses the `ReadingResponse` from Step 6.

The app displays each card sequentially with its interpretation:
- For each card in the `cards` array (ordered by `position`):
  - Show the card image and name (`card_name`, `card_position`)
  - Display `position_name` (e.g., "Past", "Present", "Future")
  - Reveal `symbolic_connection` — the card's symbolic meaning in context
  - Reveal `tarot_insight` — the practical interpretation for the user's question

**Data source from Step 6 response:**

```json
{
  "cards": [
    {
      "position": 1,
      "position_name": "Past",
      "card_id": 18,
      "card_name": "The Star",
      "card_position": "upright",
      "card_suit": null,
      "symbolic_connection": "The Star in your past position reveals...",
      "tarot_insight": "Your past efforts have created a foundation..."
    }
  ]
}
```

---

## Step 8: Final Result

No additional API call. Uses the `ReadingResponse` from Step 6.

After revealing all cards, the app shows the overall reading summary:
- Display the `insights` array — each insight has a `type` and `text`
- Display the `result` — the complete narrative summary of the reading

**Data source from Step 6 response:**

```json
{
  "insights": [
    { "type": "blind_spot", "text": "You may be underestimating..." },
    { "type": "pattern", "text": "There's a recurring theme..." },
    { "type": "trigger_event", "text": "Watch for an upcoming..." }
  ],
  "result": "The cards paint a promising picture..."
}
```

**Insight types that may appear:**
- `blind_spot` — what person doesn't want to see
- `hidden_trap` — what looks like solution but worsens
- `core_lesson` — main lesson of the situation
- `turning_point` — where everything went wrong
- `trigger_event` — what will trigger events
- `point_of_choice` — when decision must be made
- `hidden_cost` — cost of each path
- `pattern` — what repeats in behavior
- `paradox` — contradiction to accept
- `first_conscious_step` — minimal action for shift

---

## Step 9: History

The user can view their past readings at any time from the history screen.

### 9.1 List Readings — `GET /api/v1/readings`

**Auth required:** Yes

**Query parameters:**
- `limit` (int, 1-100, default: 20) — number of readings to return
- `offset` (int, >= 0, default: 0) — pagination offset

**Request:**

```http
GET /api/v1/readings?limit=20&offset=0
Authorization: Bearer <access_token>
Accept-Language: en
```

**Response (200 OK):**

```json
[
  {
    "id": 5,
    "spread_id": "three_card_spread",
    "user_spread_id": 42,
    "main_question": "Will I get promoted at work this year?",
    "question_type": "CAREER",
    "cards": [
      { "card_id": 18, "card_name": "The Star", "card_position": "upright" },
      { "card_id": 35, "card_name": "Nine of Cups", "card_position": "reversed" },
      { "card_id": 62, "card_name": "Three of Pentacles", "card_position": "upright" }
    ],
    "created_at": "2024-11-20T15:05:30"
  },
  {
    "id": 3,
    "spread_id": "celtic_cross",
    "user_spread_id": 38,
    "main_question": "What should I focus on for personal growth?",
    "question_type": "PERSONAL",
    "cards": [
      { "card_id": 0, "card_name": "The Fool", "card_position": "upright" },
      { "card_id": 21, "card_name": "The World", "card_position": "upright" },
      { "card_id": 45, "card_name": "Ace of Swords", "card_position": "reversed" },
      { "card_id": 12, "card_name": "The Hanged Man", "card_position": "upright" },
      { "card_id": 56, "card_name": "Seven of Pentacles", "card_position": "upright" },
      { "card_id": 29, "card_name": "Three of Cups", "card_position": "reversed" },
      { "card_id": 8, "card_name": "Strength", "card_position": "upright" },
      { "card_id": 41, "card_name": "Five of Swords", "card_position": "reversed" },
      { "card_id": 67, "card_name": "Queen of Pentacles", "card_position": "upright" },
      { "card_id": 15, "card_name": "The Devil", "card_position": "reversed" }
    ],
    "created_at": "2024-11-18T09:12:00"
  }
]
```

**Notes:**
- Sorted by `created_at` descending (newest first)
- Card data in the list view is summarized: only `card_id`, `card_name`, `card_position` (no insights or interpretations)
- `user_spread_id` and `question_type` may be `null` for older readings
- Returns an empty array `[]` if the user has no readings
- Use `limit` and `offset` for infinite scroll / pagination

**Error handling:**
- `401 Unauthorized` — Token expired; trigger refresh
- `422 Unprocessable Entity` — Invalid query params (limit out of range, negative offset)

---

### 9.2 Get Reading Detail — `GET /api/v1/readings/{reading_id}`

**Auth required:** Yes

**Path parameter:** `reading_id` — numeric ID of the reading

**Request:**

```http
GET /api/v1/readings/5
Authorization: Bearer <access_token>
Accept-Language: en
```

**Response (200 OK):**

Same structure as the `POST /readings` response in Step 6 (`ReadingResponse`):

```json
{
  "id": 5,
  "spread_id": "three_card_spread",
  "user_spread_id": 42,
  "main_question": "Will I get promoted at work this year?",
  "question_type": "CAREER",
  "cards": [
    {
      "position": 1,
      "position_name": "Past",
      "card_id": 18,
      "card_name": "The Star",
      "card_position": "upright",
      "card_suit": null,
      "symbolic_connection": "The Star in your past position reveals...",
      "tarot_insight": "Your past efforts have created a foundation..."
    },
    {
      "position": 2,
      "position_name": "Present",
      "card_id": 35,
      "card_name": "Nine of Cups",
      "card_position": "reversed",
      "card_suit": "cups",
      "symbolic_connection": "The reversed Nine of Cups in your present...",
      "tarot_insight": "Right now, you're at a crossroads..."
    },
    {
      "position": 3,
      "position_name": "Future",
      "card_id": 62,
      "card_name": "Three of Pentacles",
      "card_position": "upright",
      "card_suit": "pentacles",
      "symbolic_connection": "The Three of Pentacles in your future...",
      "tarot_insight": "The path forward involves actively showcasing..."
    }
  ],
  "insights": [
    { "type": "blind_spot", "text": "You may be underestimating..." },
    { "type": "pattern", "text": "There's a recurring theme..." },
    { "type": "trigger_event", "text": "Watch for an upcoming..." }
  ],
  "result": "The cards paint a promising picture for your career advancement...",
  "created_at": "2024-11-20T15:05:30"
}
```

**Notes:**
- Full reading detail with all card interpretations, insights, and result
- Same response schema as the create reading response
- Users can only view their own readings; ownership is enforced server-side

**Error handling:**
- `401 Unauthorized` — Token expired; trigger refresh
- `404 Not Found` — Reading not found or not owned by the current user

---

## Additional Endpoints

### Delete User Account — `DELETE /api/v1/users/me`

**Auth required:** Yes

**Request:**

```http
DELETE /api/v1/users/me
Authorization: Bearer <access_token>
```

No request body.

**Response:** `204 No Content` (empty body)

**Notes:**
- Deletes both the Firebase account and the database record
- All associated data (readings, spreads, tokens) is cascade-deleted
- This action is irreversible

**Error handling:**
- `401 Unauthorized` — Token expired; trigger refresh

---

### List User Spreads — `GET /api/v1/spreads/`

**Auth required:** Yes

**Request:**

```http
GET /api/v1/spreads/
Authorization: Bearer <access_token>
```

**Response (200 OK):**

```json
[
  {
    "id": 42,
    "spread_id": "three_card_spread",
    "created_at": "2024-11-20T15:00:00",
    "spread": {
      "id": "three_card_spread",
      "image_url": "https://cdn.example.com/spreads/three_card.png",
      "name": "Three Card Spread",
      "description": "A simple three-card layout exploring past, present, and future influences.",
      "instructions": "Focus on your question, then draw three cards one at a time.",
      "tags": ["beginner", "quick", "general"],
      "positions": [
        { "id": 1, "x": 0.17, "y": 0.5, "rotation": 0.0, "name": "Past", "meaning": "Events and influences from the past" },
        { "id": 2, "x": 0.5, "y": 0.5, "rotation": 0.0, "name": "Present", "meaning": "Current circumstances" },
        { "id": 3, "x": 0.83, "y": 0.5, "rotation": 0.0, "name": "Future", "meaning": "The likely outcome" }
      ]
    }
  }
]
```

**Notes:**
- Returns all spread sessions created by the current user, sorted by `created_at` descending
- Each item includes the resolved `spread` definition via computed field
- Useful for resuming an incomplete spread session

**Error handling:**
- `401 Unauthorized` — Token expired; trigger refresh

---

### Get User Spread Detail — `GET /api/v1/spreads/{spread_id}`

**Auth required:** Yes

**Path parameter:** `spread_id` — the numeric ID of the user spread (e.g., `42`)

**Request:**

```http
GET /api/v1/spreads/42
Authorization: Bearer <access_token>
```

**Response (200 OK):**

```json
{
  "id": 42,
  "spread_id": "three_card_spread",
  "created_at": "2024-11-20T15:00:00",
  "spread": {
    "id": "three_card_spread",
    "image_url": "https://cdn.example.com/spreads/three_card.png",
    "name": "Three Card Spread",
    "description": "A simple three-card layout exploring past, present, and future influences.",
    "instructions": "Focus on your question, then draw three cards one at a time.",
    "tags": ["beginner", "quick", "general"],
    "positions": [
      { "id": 1, "x": 0.17, "y": 0.5, "rotation": 0.0, "name": "Past", "meaning": "Events and influences from the past" },
      { "id": 2, "x": 0.5, "y": 0.5, "rotation": 0.0, "name": "Present", "meaning": "Current circumstances" },
      { "id": 3, "x": 0.83, "y": 0.5, "rotation": 0.0, "name": "Future", "meaning": "The likely outcome" }
    ]
  },
  "cards": [
    {
      "id": 101,
      "card_id": 18,
      "position": "upright",
      "card": {
        "card_id": 18,
        "arcana_type": "major_arcana",
        "number": 17,
        "suit": null,
        "element": "air",
        "image_url": "https://cdn.example.com/cards/17_the_star.png",
        "name": "The Star",
        "description": "A woman kneels by a pool, pouring water onto the land and into the pool.",
        "upright_meaning": "Hope, faith, renewal, serenity, inspiration",
        "reversed_meaning": "Lack of faith, despair, disconnection, insecurity",
        "keywords": ["hope", "faith", "renewal", "inspiration", "serenity"],
        "upright_relationships": "A period of healing and renewed hope in relationships.",
        "upright_career": "Creative inspiration and recognition at work.",
        "symbolism": "The eight-pointed stars represent cosmic order and divine guidance."
      }
    }
  ]
}
```

**Notes:**
- Returns the spread session with all drawn cards
- `cards` array contains the cards drawn so far (may be empty if no cards drawn yet)
- Each card includes the full `TarotCard` data via computed field
- Only the spread owner can access this endpoint

**Error handling:**
- `401 Unauthorized` — Token expired; trigger refresh
- `404 Not Found` — Spread not found or not owned by the current user

---

### Generate Test Persona — `POST /api/v1/insides/test-persona/`

**Auth required:** Yes

**Request:**

```http
POST /api/v1/insides/test-persona/
Authorization: Bearer <access_token>
Accept-Language: en
```

No request body.

**Response (201 Created):**

```json
{
  "response": {
    "content": {
      "type": "test_persona",
      "name": "Maria Ivanova",
      "age": 34,
      "occupation": "Marketing Manager",
      "life_situation": "Recently passed over for a promotion she expected. Considering whether to stay at her current company or look for new opportunities.",
      "emotional_state": "Frustrated but hopeful. Feels undervalued but knows she has strong skills.",
      "question": "Should I stay at my current job or start looking for a new position?"
    },
    "type": "ai",
    "timestamp": "2024-11-20T15:10:00.000000+00:00"
  }
}
```

**Notes:**
- Generates a fictional test persona for prompt testing and development
- The persona includes a life situation and a tarot question
- Use the persona data as input for `/test-persona-answers/`

**Error handling:**
- `401 Unauthorized` — Token expired; trigger refresh
- `500 Internal Server Error` — OpenAI API failure
- `502 Bad Gateway` — AI response parsing failed

---

### Generate Test Persona Answers — `POST /api/v1/insides/test-persona-answers/`

**Auth required:** Yes

**Request:**

```http
POST /api/v1/insides/test-persona-answers/
Authorization: Bearer <access_token>
Accept-Language: en
Content-Type: application/json
```

```json
{
  "name": "Maria Ivanova",
  "age": 34,
  "occupation": "Marketing Manager",
  "life_situation": "Recently passed over for a promotion she expected.",
  "emotional_state": "Frustrated but hopeful.",
  "main_question": "Should I stay at my current job or start looking for a new position?",
  "clarifying_questions": [
    {
      "question": "How long have you been in your current position?",
      "options": [
        { "label": "A", "text": "Less than 1 year" },
        { "label": "B", "text": "1-3 years" },
        { "label": "C", "text": "More than 3 years" }
      ]
    }
  ]
}
```

**Response (201 Created):**

```json
{
  "response": {
    "content": {
      "type": "test_persona_answers",
      "answers": [
        {
          "question": "How long have you been in your current position?",
          "selected_label": "C",
          "selected_text": "More than 3 years"
        }
      ]
    },
    "type": "ai",
    "timestamp": "2024-11-20T15:12:00.000000+00:00"
  }
}
```

**Notes:**
- Generates answers from the test persona's perspective to clarifying questions
- Use output from `/test-persona/` as input for this endpoint
- The AI selects answers that are consistent with the persona's life situation and emotional state

**Error handling:**
- `401 Unauthorized` — Token expired; trigger refresh
- `500 Internal Server Error` — OpenAI API failure
- `502 Bad Gateway` — AI response parsing failed

---

### Health Check — `GET /healthz`

**Auth required:** No

**Request:**

```http
GET /healthz
```

**Response (200 OK):**

```json
{
  "status": "ok",
  "ts": "2024-11-20T15:00:00.000000+00:00"
}
```

**Notes:**
- Checks database connectivity
- Use this endpoint to verify the API is reachable before attempting login
