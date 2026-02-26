import SwiftUI

// MARK: - Quiz Question Types
enum QuizQuestionType {
    case whoIsThis
    case whatRelationship
    case whereLive
    case funFact
}

// MARK: - Quiz Question (single definition used everywhere)
struct QuizQuestion {
    let type: QuizQuestionType
    let person: PersonProfile
    let correctAnswer: String
    let wrongAnswers: [String]
    let promptText: String

    var allAnswers: [String] {
        // FIX 2: Always return exactly 4 options (correct + up to 3 wrongs, padded if needed)
        let available = Array(wrongAnswers.prefix(3))
        return (available + [correctAnswer]).shuffled()
    }
}

// MARK: - Quiz Generator
struct QuizGenerator {

    // FIX 2: Fallback pools so we always have 3 wrong answers even with few people
    private static let fallbackNames = ["Margaret", "Robert", "Susan", "David", "Linda", "Charles", "Karen", "James"]
    private static let fallbackRelationships = ["Friend", "Neighbour", "Colleague", "Cousin", "Uncle", "Aunt", "Doctor", "Nurse"]
    private static let fallbackLocations = ["Auckland", "Wellington", "Christchurch", "Hamilton", "Tauranga", "Dunedin", "Napier", "Palmerston North"]
    private static let fallbackFacts = ["Loves cooking", "Enjoys gardening", "Plays chess", "Likes hiking", "Reads a lot", "Enjoys painting", "Loves music", "Great at crosswords"]

    static func generateQuestions(from people: [PersonProfile], count: Int = 5) -> [QuizQuestion] {
        let validPeople = people.filter { !$0.name.isEmpty }
        guard validPeople.count >= 2 else { return [] }

        var questions: [QuizQuestion] = []

        for person in validPeople {
            let others = validPeople.filter { $0.id != person.id }

            // Who is this?
            if !person.name.isEmpty {
                let pool = others.map(\.name).filter { !$0.isEmpty }
                let wrongs = pickWrong(from: pool, fallback: fallbackNames, excluding: person.name, count: 3)
                questions.append(QuizQuestion(
                    type: .whoIsThis,
                    person: person,
                    correctAnswer: person.name,
                    wrongAnswers: wrongs,
                    promptText: "Who is this?"
                ))
            }

            // Relationship
            if !person.relationship.isEmpty {
                let pool = others.map(\.relationship).filter { !$0.isEmpty }
                let wrongs = pickWrong(from: pool, fallback: fallbackRelationships, excluding: person.relationship, count: 3)
                questions.append(QuizQuestion(
                    type: .whatRelationship,
                    person: person,
                    correctAnswer: person.relationship,
                    wrongAnswers: wrongs,
                    promptText: "What is your relationship with \(person.name)?"
                ))
            }

            // Location
            if !person.location.isEmpty {
                let pool = others.map(\.location).filter { !$0.isEmpty }
                let wrongs = pickWrong(from: pool, fallback: fallbackLocations, excluding: person.location, count: 3)
                questions.append(QuizQuestion(
                    type: .whereLive,
                    person: person,
                    correctAnswer: person.location,
                    wrongAnswers: wrongs,
                    promptText: "Where does \(person.name) live?"
                ))
            }

            // Fun fact
            if !person.funFact.isEmpty {
                let pool = others.map(\.funFact).filter { !$0.isEmpty }
                let wrongs = pickWrong(from: pool, fallback: fallbackFacts, excluding: person.funFact, count: 3)
                questions.append(QuizQuestion(
                    type: .funFact,
                    person: person,
                    correctAnswer: person.funFact,
                    wrongAnswers: wrongs,
                    promptText: "What is a fun fact about \(person.name)?"
                ))
            }
        }

        return Array(questions.shuffled().prefix(count))
    }

    // FIX 2: pickWrong pads with fallback values when pool is too small
    private static func pickWrong(from pool: [String], fallback: [String], excluding correct: String, count: Int) -> [String] {
        var candidates = Array(Set(pool)).filter { $0 != correct }.shuffled()
        if candidates.count < count {
            let extras = fallback.filter { $0 != correct && !candidates.contains($0) }.shuffled()
            candidates += extras
        }
        return Array(candidates.prefix(count))
    }
}

// MARK: - Auto Quiz View (free play, no levels)
struct AutoQuizView: View {
    @EnvironmentObject var onboardingStore: OnboardingStore
    @Environment(\.dismiss) var dismiss

    let onExitToHome: (() -> Void)? = nil

    @State private var questions: [QuizQuestion] = []
    @State private var currentIndex = 0
    @State private var selectedAnswer: String? = nil
    @State private var score = 0
    @State private var isFinished = false

    var current: QuizQuestion? { questions.indices.contains(currentIndex) ? questions[currentIndex] : nil }

    var body: some View {
        ZStack {
            Image("garden_background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            Color.white.opacity(0.45).ignoresSafeArea()

            if isFinished {
                QuizFinishedView(score: score, total: questions.count, onBackToGarden: { backToGarden() })
            } else if let q = current {
                VStack(spacing: 0) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.4))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: "7ba7bc"))
                                .frame(width: geo.size.width * CGFloat(currentIndex) / CGFloat(max(questions.count, 1)), height: 6)
                                .animation(.easeInOut, value: currentIndex)
                        }
                    }
                    .frame(height: 6)
                    .padding(.horizontal, 32)
                    .padding(.top, 70)

                    Spacer()

                    VStack(spacing: 24) {
                        if let img = q.person.image {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 140, height: 140)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                                .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
                        }

                        Text(q.promptText)
                            .font(.custom("Georgia", size: 20))
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "444444"))
                            .multilineTextAlignment(.center)

                        VStack(spacing: 12) {
                            ForEach(q.allAnswers, id: \.self) { answer in
                                AutoAnswerButton(
                                    answer: answer,
                                    selected: selectedAnswer,
                                    correct: q.correctAnswer,
                                    onTap: {
                                        guard selectedAnswer == nil else { return }
                                        selectedAnswer = answer
                                        if answer == q.correctAnswer { score += 1 }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { advance() }
                                    }
                                )
                            }
                        }
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 36)
                            .fill(Color.white.opacity(0.8))
                            .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 8)
                    )
                    .padding(.horizontal, 24)

                    Spacer()
                }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            questions = QuizGenerator.generateQuestions(from: onboardingStore.people, count: 6)
        }
    }

    func backToGarden() {
        if let onExitToHome = onExitToHome {
            onExitToHome()
        } else {
            dismiss()
        }
    }

    func advance() {
        selectedAnswer = nil
        if currentIndex + 1 >= questions.count { isFinished = true }
        else { currentIndex += 1 }
    }
}

// MARK: - AutoAnswerButton
struct AutoAnswerButton: View {
    let answer: String
    let selected: String?
    let correct: String
    let onTap: () -> Void

    var isSelected: Bool { selected == answer }
    var isCorrect: Bool { answer == correct }
    var hasSelected: Bool { selected != nil }

    var bgColor: Color {
        guard hasSelected else { return Color.white }
        if isCorrect { return Color(hex: "a8c5a0").opacity(0.3) }
        if isSelected { return Color(hex: "f07080").opacity(0.25) }
        return Color.white
    }

    var borderColor: Color {
        guard hasSelected else { return Color(hex: "dddddd") }
        if isCorrect { return Color(hex: "a8c5a0") }
        if isSelected { return Color(hex: "f07080") }
        return Color(hex: "dddddd")
    }

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(answer)
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(Color(hex: "333333"))
                    .multilineTextAlignment(.leading)
                Spacer()
                if hasSelected {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : (isSelected ? "xmark.circle.fill" : ""))
                        .foregroundColor(isCorrect ? Color(hex: "a8c5a0") : Color(hex: "f07080"))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(bgColor)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderColor, lineWidth: 1.5))
            )
        }
        .disabled(hasSelected)
        .animation(.easeInOut(duration: 0.2), value: selected)
    }
}

// MARK: - Quiz Finished View
struct QuizFinishedView: View {
    let score: Int
    let total: Int
    let onBackToGarden: () -> Void

    var emoji: String {
        let pct = Double(score) / Double(max(total, 1))
        if pct >= 0.8 { return "🌸" }
        if pct >= 0.5 { return "🌷" }
        return "🌱"
    }

    var message: String {
        let pct = Double(score) / Double(max(total, 1))
        if pct >= 0.8 { return "Wonderful memory!" }
        if pct >= 0.5 { return "Good effort!" }
        return "Keep practicing, you're growing 🌱"
    }

    var body: some View {
        VStack(spacing: 28) {
            Text(emoji).font(.system(size: 72))
            Text(message)
                .font(.custom("Snell Roundhand", size: 36))
                .foregroundColor(Color(hex: "7ba7bc"))
                .multilineTextAlignment(.center)
            Text("\(score) out of \(total) correct")
                .font(.custom("Georgia", size: 18))
                .foregroundColor(Color(hex: "888888"))
            Button(action: onBackToGarden) {
                Text("Back to Garden")
                    .font(.custom("Georgia", size: 17))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(colors: [Color(hex: "7ba7bc"), Color(hex: "a8c5a0")], startPoint: .leading, endPoint: .trailing))
                    )
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 36)
                .fill(Color.white.opacity(0.8))
                .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: 10)
        )
        .padding(.horizontal, 28)
    }
}