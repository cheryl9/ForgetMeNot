import SwiftUI

// MARK: - Quiz Question Types
// Single definition — do NOT redeclare in any other file
enum QuizQuestionType {
    case whoIsThis
    case whatRelationship
    case whereLive
    case funFact
    case memoryWho
    case memoryRecall
}

// MARK: - Quiz Question
// Single definition — do NOT redeclare in any other file
struct QuizQuestion: Identifiable {
    let id = UUID()
    let type: QuizQuestionType
    let person: PersonProfile
    let correctAnswer: String
    let wrongAnswers: [String]
    let promptText: String
    let memoryImage: UIImage?

    init(
        type: QuizQuestionType,
        person: PersonProfile,
        correctAnswer: String,
        wrongAnswers: [String],
        promptText: String,
        memoryImage: UIImage? = nil
    ) {
        self.type = type
        self.person = person
        self.correctAnswer = correctAnswer
        self.wrongAnswers = wrongAnswers
        self.promptText = promptText
        self.memoryImage = memoryImage
    }

    var allAnswers: [String] {
        Array((wrongAnswers.prefix(3) + [correctAnswer]).shuffled())
    }
}

// MARK: - Quiz Generator
// Single definition — do NOT redeclare in any other file
struct QuizGenerator {
    private static let fallbackNames         = ["Margaret", "Robert", "Susan", "David", "Linda", "Charles", "Karen", "James"]
    private static let fallbackRelationships = ["Friend", "Neighbour", "Colleague", "Cousin", "Uncle", "Aunt", "Doctor", "Nurse"]
    private static let fallbackLocations     = ["Auckland", "Wellington", "Christchurch", "Hamilton", "Tauranga", "Dunedin", "Napier", "Palmerston North"]
    private static let fallbackFacts         = ["Loves cooking", "Enjoys gardening", "Plays chess", "Likes hiking", "Reads a lot", "Enjoys painting", "Loves music", "Great at crosswords"]

    static func generateQuestions(
        from people: [PersonProfile],
        memoryEntries: [MemoryBoardEntry] = [],
        count: Int = 8
    ) -> [QuizQuestion] {
        let validPeople = people.filter { !$0.name.isEmpty }
        guard validPeople.count >= 2 else { return [] }

        var questions: [QuizQuestion] = []

        // ── Onboarding-based questions ──
        for person in validPeople {
            let others = validPeople.filter { $0.id != person.id }

            if !person.name.isEmpty {
                let wrongs = pickWrong(from: others.map(\.name), fallback: fallbackNames, excluding: person.name, count: 3)
                questions.append(QuizQuestion(
                    type: .whoIsThis, person: person,
                    correctAnswer: person.name, wrongAnswers: wrongs,
                    promptText: "Who is this?"))
            }
            if !person.relationship.isEmpty {
                let wrongs = pickWrong(from: others.map(\.relationship), fallback: fallbackRelationships, excluding: person.relationship, count: 3)
                questions.append(QuizQuestion(
                    type: .whatRelationship, person: person,
                    correctAnswer: person.relationship, wrongAnswers: wrongs,
                    promptText: "What is your relationship with \(person.name)?"))
            }
            if !person.location.isEmpty {
                let wrongs = pickWrong(from: others.map(\.location), fallback: fallbackLocations, excluding: person.location, count: 3)
                questions.append(QuizQuestion(
                    type: .whereLive, person: person,
                    correctAnswer: person.location, wrongAnswers: wrongs,
                    promptText: "Where does \(person.name) live?"))
            }
            if !person.funFact.isEmpty {
                let wrongs = pickWrong(from: others.map(\.funFact), fallback: fallbackFacts, excluding: person.funFact, count: 3)
                questions.append(QuizQuestion(
                    type: .funFact, person: person,
                    correctAnswer: person.funFact, wrongAnswers: wrongs,
                    promptText: "What is a fun fact about \(person.name)?"))
            }
        }

        // ── Memory Board questions ──
        let quizzableMemories = memoryEntries.filter {
            !$0.personName.isEmpty && !$0.text.isEmpty
        }

        for memory in quizzableMemories {
            let allNames = Array(Set(validPeople.map(\.name) + memoryEntries.map(\.personName)))
                .filter { !$0.isEmpty }

            let placeholder = validPeople.first(where: { $0.name == memory.personName })
                ?? PersonProfile(name: memory.personName, relationship: "", location: "", funFact: "")

            // Q: Who is this memory about?
            let nameWrongs = pickWrong(from: allNames, fallback: fallbackNames, excluding: memory.personName, count: 3)
            let memImg = memory.entryType == .photo ? memory.image : nil
            questions.append(QuizQuestion(
                type: .memoryWho,
                person: placeholder,
                correctAnswer: memory.personName,
                wrongAnswers: nameWrongs,
                promptText: "Who is this memory about?",
                memoryImage: memImg
            ))

            // Q: What do you remember about [person]?
            let shortText = String(memory.text.prefix(60))
            let otherTexts = quizzableMemories
                .filter { $0.id != memory.id }
                .map { String($0.text.prefix(60)) }
            let textWrongs = pickWrong(from: otherTexts, fallback: fallbackFacts, excluding: shortText, count: 3)
            questions.append(QuizQuestion(
                type: .memoryRecall,
                person: placeholder,
                correctAnswer: shortText,
                wrongAnswers: textWrongs,
                promptText: "What is a memory you have of \(memory.personName)?"
            ))
        }

        // Mix: up to 30% memory questions, rest normal
        let memoryQs = questions.filter { $0.type == .memoryWho || $0.type == .memoryRecall }.shuffled()
        let normalQs  = questions.filter { $0.type != .memoryWho && $0.type != .memoryRecall }.shuffled()
        let memorySlots = min(memoryQs.count, max(1, count / 3))
        let normalSlots = min(normalQs.count, count - memorySlots)
        let combined = (Array(normalQs.prefix(normalSlots)) + Array(memoryQs.prefix(memorySlots))).shuffled()
        return Array(combined.prefix(count))
    }

    private static func pickWrong(from pool: [String], fallback: [String], excluding correct: String, count: Int) -> [String] {
        var candidates = Array(Set(pool)).filter { !$0.isEmpty && $0 != correct }.shuffled()
        if candidates.count < count {
            candidates += fallback.filter { $0 != correct && !candidates.contains($0) }.shuffled()
        }
        return Array(candidates.prefix(count))
    }
}