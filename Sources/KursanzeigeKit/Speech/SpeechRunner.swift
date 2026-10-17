/// Runs the speech of a list in one task at a time. A new task cancels
/// the old task and stops the voice. It starts only after the old task
/// ended, so two texts of one list never play at the same time. The
/// table and the chart page each have a runner. `AppModel` stops the
/// table before the chart page opens, and the speaker stops an old text
/// before it starts a new one.
///
/// Each step of a task checks the cancel flag before it speaks or moves
/// the cursor. The flag changes on the main actor before the new task
/// exists. Thus a cancelled task never speaks again and never moves the
/// cursor.
@MainActor
final class SpeechRunner {
    private let speaker: any Speaking
    private let sleeper: any Sleeping
    private var task: Task<Void, Never>?

    init(speaker: any Speaking, sleeper: any Sleeping) {
        self.speaker = speaker
        self.sleeper = sleeper
    }

    /// Stops the old speech and runs `operation` as the new speech.
    func replaceSpeech(with operation: @escaping @MainActor () async -> Void) {
        let previousTask = task
        stopSpeech()
        task = Task {
            await previousTask?.value
            guard !Task.isCancelled else { return }
            await operation()
        }
    }

    /// Cancels the task and stops the voice at once. A pause between rows
    /// ends too, because the cancel ends the sleep.
    func stopSpeech() {
        task?.cancel()
        speaker.stop()
    }

    /// Speaks the text in the current task. Returns true when the voice
    /// read the text to the end. Returns false when the task is cancelled
    /// before or during the speech, or when the voice stopped. Then the
    /// caller must stop.
    @discardableResult
    func speak(_ text: String) async -> Bool {
        guard !Task.isCancelled else { return false }
        let isFinished = await speaker.speak(text)
        return isFinished && !Task.isCancelled
    }

    /// Waits in the current task. Returns false when the task is cancelled
    /// before or during the wait. Then the caller must stop.
    func pause(for seconds: Double) async -> Bool {
        do {
            try await sleeper.sleep(for: seconds)
        } catch {
            return false
        }
        return !Task.isCancelled
    }

    /// Waits until the speech ends, also a speech that replaces it. For tests.
    func waitForSpeech() async {
        while let currentTask = task {
            await currentTask.value
            guard currentTask != task else { return }
        }
    }
}
