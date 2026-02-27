import SwiftUI
import AVFoundation

struct QuizView: View {
    let level: Int
    let onExitToHome: (() -> Void)?
    @EnvironmentObject var memoryStore: MemoryStore
    @EnvironmentObject var onboardingStore: OnboardingStore
    @EnvironmentObject var levelStore: LevelStore
    @EnvironmentObject var memoryBoardStore: MemoryBoardStore
    @EnvironmentObject var dropletStore: DropletStore
    @Environment(\.dismiss) var dismiss

    @State private var questions: [QuizQuestion] = []
    @State private var currentIndex = 0
    @State private var selectedAnswer: String? = nil
    @State private var score = 0
    @State private var quizComplete = false
    @State private var appeared = false
    @State private var dropletsEarned = 0
    @State private var showDropletAnimation = false
    @State private var showMemoryPrompt = false
    @State private var answeredWrong: [QuizQuestion] = []

    let questionCount = 8

    var current: QuizQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let isIPad = geo.size.width >= 768
            let contentWidth: CGFloat = isIPad ? min(geo.size.width * 0.82, 760) : geo.size.width

            ZStack {
                Image("garden_background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()
                Color.white.opacity(0.45).ignoresSafeArea()

                if quizComplete {
                    ScrollView {
                        QuizCompleteView(
                            score: score,
                            dropletsEarned: dropletsEarned,
                            total: questions.count,
                            onDone: { backToGarden() },
                            onMemoryBoard: { showMemoryPrompt = true }
                        )
                        .padding(.vertical, 40)
                    }
                    .frame(width: contentWidth)
                    .frame(maxWidth: .infinity)

                } else if let q = current {
                    if isLandscape {
                        HStack(alignment: .center, spacing: 0) {
                            VStack(spacing: 0) {
                                topBar
                                    .padding(.horizontal, 20)
                                    .padding(.top, 14)
                                Spacer(minLength: 8)
                                questionCard(q: q, imgSize: 90, fontSize: 16)
                                    .padding(.horizontal, 20)
                                    .scaleEffect(appeared ? 1 : 0.92)
                                    .opacity(appeared ? 1 : 0)
                                Spacer(minLength: 8)
                            }
                            .frame(width: contentWidth * 0.48)

                            VStack {
                                Spacer()
                                answerGrid(q: q, columns: 1)
                                    .padding(.horizontal, 20)
                                Spacer()
                            }
                            .frame(width: contentWidth * 0.52)
                        }
                        .frame(width: contentWidth, height: geo.size.height)
                        .frame(maxWidth: .infinity)

                    } else {
                        VStack(spacing: 0) {
                            topBar
                                .padding(.horizontal, 20)
                                .padding(.top, geo.safeAreaInsets.top + 16)
                                .padding(.bottom, 12)

                            Spacer(minLength: 0)

                            questionCard(
                                q: q,
                                imgSize: isIPad ? 160 : 120,
                                fontSize: isIPad ? 22 : 18
                            )
                            .padding(.horizontal, 20)
                            .scaleEffect(appeared ? 1 : 0.92)
                            .opacity(appeared ? 1 : 0)

                            Spacer(minLength: 0)

                            answerGrid(q: q, columns: 2)
                                .padding(.horizontal, 20)
                                .padding(.bottom, (geo.safeAreaInsets.bottom > 0 ? geo.safeAreaInsets.bottom : 20) + (isIPad ? 32 : 16))
                        }
                        .frame(width: contentWidth)
                        .frame(maxWidth: .infinity)
                        .frame(height: geo.size.height)
                    }

                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "aaaaaa"))
                        Text("Not enough people added")
                            .font(.custom("Snell Roundhand", size: 24))
                            .foregroundColor(Color(hex: "7ba7bc"))
                        Text("Please add at least 2 people in onboarding.")
                            .font(.custom("Georgia", size: 14))
                            .foregroundColor(Color(hex: "888888"))
                            .multilineTextAlignment(.center)
                        Button("Go Back") { dismiss() }
                            .font(.custom("Georgia", size: 15))
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(Color(hex: "a8c5a0")))
                    }
                    .padding(32)
                    .background(RoundedRectangle(cornerRadius: 28).fill(.ultraThinMaterial))
                    .padding(.horizontal, 32)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .onAppear {
            questions = QuizGenerator.generateQuestions(from: onboardingStore.people, count: questionCount)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { appeared = true }
        }
        .sheet(isPresented: $showMemoryPrompt) {
            MemoryPromptView(questions: answeredWrong) { entry in
                memoryBoardStore.add(entry)
            }
        }
    }

    func backToGarden() {
        if let onExitToHome = onExitToHome {
            onExitToHome()
        } else {
            dismiss()
        }
    }

    // MARK: - Top Bar
    var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(Color(hex: "aaaaaa"))
            }
            .frame(width: 44, height: 44)

            Spacer()

            HStack(spacing: 6) {
                ForEach(0..<questions.count, id: \.self) { i in
                    Circle()
                        .fill(
                            i < currentIndex
                                ? Color(hex: "a8c5a0")
                                : i == currentIndex
                                    ? Color(hex: "7ba7bc")
                                    : Color(hex: "dddddd")
                        )
                        .frame(width: 8, height: 8)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Text("💧")
                    .font(.system(size: 18))
                    .scaleEffect(showDropletAnimation ? 1.4 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.4), value: showDropletAnimation)
                Text("\(dropletsEarned)")
                    .font(.custom("Georgia", size: 15))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "7ba7bc"))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color(hex: "7ba7bc").opacity(0.15)))
            .frame(minWidth: 64)
        }
        .frame(height: 50)
    }

    // MARK: - Question Card
    @ViewBuilder
    func questionCard(q: QuizQuestion, imgSize: CGFloat, fontSize: CGFloat) -> some View {
        VStack(spacing: 16) {
            Text(q.promptText)
                .font(.custom("Georgia", size: fontSize))
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "444444"))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)

            if let img = q.person.image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: imgSize, height: imgSize)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            } else {
                Circle()
                    .fill(Color(hex: "7ba7bc").opacity(0.2))
                    .frame(width: imgSize, height: imgSize)
                    .overlay(
                        Text(q.person.name.prefix(1).uppercased())
                            .font(.system(size: imgSize * 0.4, weight: .semibold))
                            .foregroundColor(Color(hex: "7ba7bc"))
                    )
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white.opacity(0.75))
                .background(RoundedRectangle(cornerRadius: 28).fill(.ultraThinMaterial))
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.7), lineWidth: 1.5))
                .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 8)
        )
    }

    // MARK: - Answer Grid
    @ViewBuilder
    func answerGrid(q: QuizQuestion, columns: Int) -> some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 12), count: columns)
        LazyVGrid(columns: cols, spacing: 12) {
            ForEach(q.allAnswers, id: \.self) { choice in
                AnswerButton(
                    text: choice,
                    state: answerState(for: choice, correct: q.correctAnswer),
                    action: { selectAnswer(choice, correct: q.correctAnswer) }
                )
            }
        }
    }

    func answerState(for choice: String, correct: String) -> AnswerButton.AnswerState {
        guard let selected = selectedAnswer else { return .idle }
        if choice == correct { return .correct }
        if choice == selected { return .wrong }
        return .idle
    }

    func selectAnswer(_ choice: String, correct: String) {
        guard selectedAnswer == nil else { return }
        selectedAnswer = choice

        if choice == correct {
            score += 1
            dropletsEarned += 1
            showDropletAnimation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { showDropletAnimation = false }
        } else {
            if let q = current { answeredWrong.append(q) }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            advanceQuestion()
        }
    }

    func advanceQuestion() {
        if currentIndex + 1 < questions.count {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                currentIndex += 1
                selectedAnswer = nil
                appeared = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation { appeared = true }
            }
        } else {
            levelStore.completeLevel(level)
            dropletStore.add(dropletsEarned)
            withAnimation { quizComplete = true }
        }
    }
}

// MARK: - Memory Prompt
struct MemoryPromptView: View {
    @Environment(\.dismiss) var dismiss
    let questions: [QuizQuestion]
    let onSave: (MemoryBoardEntry) -> Void

    @State private var text = ""
    @State private var selectedImage: UIImage?
    @State private var showPhotoPicker = false
    @State private var selectedPersonName = ""

    var body: some View {
        ZStack {
            // Solid background — no more bleed-through
            Color(hex: "f7f3ee").ignoresSafeArea()

            // Subtle garden texture on top
            Image("garden_background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.08)

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Spacer()
                    Button("Skip") { dismiss() }
                        .font(.custom("Georgia", size: 15))
                        .foregroundColor(Color(hex: "aaaaaa"))
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                }

                Spacer()

                // Main content — vertically centered
                VStack(spacing: 22) {

                    // Title
                    VStack(spacing: 6) {
                        Text("Keep a Memory")
                            .font(.custom("Snell Roundhand", size: 34))
                            .foregroundColor(Color(hex: "5c4a3a"))
                        Text("Write something you'd like to remember")
                            .font(.custom("Georgia", size: 14))
                            .foregroundColor(Color(hex: "9a8a7a"))
                            .multilineTextAlignment(.center)
                    }

                    // Person pills
                    if !questions.isEmpty {
                        VStack(spacing: 8) {
                            Text("About who?")
                                .font(.custom("Georgia", size: 13))
                                .foregroundColor(Color(hex: "b0a090"))
                            HStack(spacing: 10) {
                                ForEach(Array(Set(questions.map { $0.person.name })), id: \.self) { name in
                                    Button(action: { selectedPersonName = name }) {
                                        Text(name)
                                            .font(.custom("Georgia", size: 14))
                                            .foregroundColor(selectedPersonName == name ? .white : Color(hex: "7ba7bc"))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule().fill(selectedPersonName == name
                                                    ? Color(hex: "7ba7bc")
                                                    : Color(hex: "7ba7bc").opacity(0.12))
                                            )
                                    }
                                }
                            }
                        }
                    }

                    // Photo picker
                    Button { showPhotoPicker = true } label: {
                        if let img = selectedImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "ede8e0"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 80)
                                .overlay(
                                    HStack(spacing: 8) {
                                        Image(systemName: "photo.badge.plus")
                                            .foregroundColor(Color(hex: "b0a090"))
                                        Text("Add a photo (optional)")
                                            .font(.custom("Georgia", size: 14))
                                            .foregroundColor(Color(hex: "b0a090"))
                                    }
                                )
                        }
                    }

                    // Text field
                    TextField("Write your memory here...", text: $text, axis: .vertical)
                        .font(.custom("Georgia", size: 16))
                        .foregroundColor(Color(hex: "333333"))
                        .lineLimit(3...5)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(hex: "ede8e0"))
                        )

                    // Save button
                    Button {
                        var entry = MemoryBoardEntry()
                        entry.text = text
                        entry.personName = selectedPersonName
                        if let img = selectedImage {
                            entry.imageFilename = ImageFileStorage.save(img, compressionQuality: 0.5)
                        }
                        entry.createdFrom = "quiz_wrong"
                        onSave(entry)
                        dismiss()
                    } label: {
                        Text("Save to Memory Board")
                            .font(.custom("Georgia", size: 16))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        text.isEmpty
                                        ? LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                                        : LinearGradient(colors: [Color(hex: "7ba7bc"), Color(hex: "a8c5a0")], startPoint: .leading, endPoint: .trailing)
                                    )
                            )
                    }
                    .disabled(text.isEmpty)
                }
                .padding(.horizontal, 32)
                .frame(maxWidth: 500)

                Spacer()
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker(image: $selectedImage)
        }
    }
}

// MARK: - Answer Button
struct AnswerButton: View {
    enum AnswerState { case idle, correct, wrong }
    let text: String
    let state: AnswerState
    let action: () -> Void
    @State private var pressed = false

    var bgColor: Color {
        switch state {
        case .idle:    return Color(hex: "d8eaf8")
        case .correct: return Color(hex: "a8c5a0")
        case .wrong:   return Color(hex: "f4a0a0")
        }
    }
    var textColor: Color { state == .idle ? Color(hex: "555577") : .white }

    var body: some View {
        Button(action: {
            guard state == .idle else { return }
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { pressed = false; action() }
        }) {
            Text(text)
                .font(.custom("Georgia", size: 15))
                .fontWeight(.semibold)
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
                .padding(.vertical, 16)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 60)
                .background(
                    Capsule()
                        .fill(bgColor)
                        .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1.5))
                        .shadow(color: bgColor.opacity(0.4), radius: 6, x: 0, y: 3)
                )
        }
        .scaleEffect(pressed ? 0.93 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.5), value: state)
    }
}

// MARK: - Quiz Complete View
struct QuizCompleteView: View {
    let score: Int
    let dropletsEarned: Int
    let total: Int
    let onDone: () -> Void
    let onMemoryBoard: () -> Void

    var isPerfect: Bool { score == total }

    var message: String {
        let r = Double(score) / Double(total)
        if r == 1.0 { return "Perfect! All memories recalled!" }
        if r >= 0.75 { return "Great job! Keep it up!" }
        if r >= 0.5 { return "Good effort! Let's try again!" }
        return "Keep practicing, you're doing great!"
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Level Complete!")
                .font(.custom("Snell Roundhand", size: 32))
                .foregroundColor(Color(hex: "7ba7bc"))
            Text("\(score) / \(total) correct")
                .font(.custom("Georgia", size: 20))
                .foregroundColor(Color(hex: "555555"))
            HStack(spacing: 8) {
                Text("💧 × \(dropletsEarned)")
                    .font(.custom("Georgia", size: 18))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "7ba7bc"))
                Text("earned!")
                    .font(.custom("Georgia", size: 15))
                    .foregroundColor(Color(hex: "888888"))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(Capsule().fill(Color(hex: "7ba7bc").opacity(0.12)))

            Text(message)
                .font(.custom("Georgia", size: 15))
                .foregroundColor(Color(hex: "888888"))
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                Button(action: onDone) {
                    Text("Back to Garden")
                        .font(.custom("Snell Roundhand", size: 20))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [Color(hex: "a8c5a0"), Color(hex: "7eb8a4")],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .shadow(color: Color(hex: "a8c5a0").opacity(0.4), radius: 8, x: 0, y: 4)
                        )
                }

                if !isPerfect {
                    Button(action: onMemoryBoard) {
                        Text("Write a Memory")
                            .font(.custom("Georgia", size: 15))
                            .foregroundColor(Color(hex: "5c4a3a"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "7ba7bc").opacity(0.1))
                                    .overlay(Capsule().stroke(Color(hex: "7ba7bc").opacity(0.3), lineWidth: 1))
                            )
                    }
                }
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(Color.white.opacity(0.75))
                .background(RoundedRectangle(cornerRadius: 32).fill(.ultraThinMaterial))
                .shadow(color: .black.opacity(0.1), radius: 24, x: 0, y: 10)
        )
        .padding(.horizontal, 24)
        .padding(.vertical, 50)
    }
}

// MARK: - Voice Player View
struct VoicePlayerView: View {
    let voiceData: Data?
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false

    var body: some View {
        HStack(spacing: 16) {
            Button { togglePlay() } label: {
                ZStack {
                    Circle().fill(Color(hex: "7ba7bc")).frame(width: 52, height: 52)
                    Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 20)).foregroundColor(.white)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "e8f4f8")))
    }

    func togglePlay() {
        if isPlaying { player?.stop(); isPlaying = false }
        else {
            guard let data = voiceData else { return }
            player = try? AVAudioPlayer(data: data)
            player?.play()
            isPlaying = true
        }
    }
}