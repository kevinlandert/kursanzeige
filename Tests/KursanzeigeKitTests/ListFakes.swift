import Foundation
import Testing
@testable import KursanzeigeKit

/// A voice that records each text in the order of the start.
///
/// With `holdsSpeech`, each text plays until the test calls
/// `finishSpeech()` or someone calls `stop()`. Without it, each text ends
/// at once. A stopped text gives false, as the real voice does.
@MainActor
final class FakeSpeaker: Speaking {
    private(set) var spokenTexts: [String] = []
    private(set) var stopCount = 0
    /// The largest number of texts that played at the same time. A list
    /// must keep it at 1.
    private(set) var largestOverlap = 0
    private var playingCount = 0
    private var heldTexts: [CheckedContinuation<Bool, Never>] = []
    private let holdsSpeech: Bool

    init(holdsSpeech: Bool = false) {
        self.holdsSpeech = holdsSpeech
    }

    var isSpeaking: Bool {
        !heldTexts.isEmpty
    }

    func speak(_ text: String) async -> Bool {
        spokenTexts.append(text)
        playingCount += 1
        largestOverlap = max(largestOverlap, playingCount)
        let isFinished = holdsSpeech ? await withCheckedContinuation { heldTexts.append($0) } : true
        playingCount -= 1
        return isFinished
    }

    func stop() {
        stopCount += 1
        heldTexts.forEach { $0.resume(returning: false) }
        heldTexts = []
    }

    /// Ends the oldest held text as if the voice read it to the end.
    func finishSpeech() {
        guard !heldTexts.isEmpty else {
            Issue.record("The voice plays no text that can finish.")
            return
        }
        heldTexts.removeFirst().resume(returning: true)
    }
}

/// A pause that records each duration.
///
/// With `holdsPause`, each pause lasts until the test calls `finishPause()`
/// or the task is cancelled. Without it, each pause ends at once.
@MainActor
final class FakeSleeper: Sleeping {
    private(set) var pauses: [TimeInterval] = []
    private var heldPauses: [CheckedContinuation<Void, Never>] = []
    private let holdsPause: Bool

    init(holdsPause: Bool = false) {
        self.holdsPause = holdsPause
    }

    var isPausing: Bool {
        !heldPauses.isEmpty
    }

    func sleep(for seconds: TimeInterval) async throws {
        guard !Task.isCancelled else { throw CancellationError() }
        pauses.append(seconds)
        if holdsPause {
            await withTaskCancellationHandler {
                await withCheckedContinuation { heldPauses.append($0) }
            } onCancel: {
                Task { @MainActor in self.endAllPauses() }
            }
        }
        guard !Task.isCancelled else { throw CancellationError() }
    }

    func finishPause() {
        guard !heldPauses.isEmpty else {
            Issue.record("No pause runs that can finish.")
            return
        }
        heldPauses.removeFirst().resume()
    }

    private func endAllPauses() {
        heldPauses.forEach { $0.resume() }
        heldPauses = []
    }
}

/// Keeps the cursors in memory.
@MainActor
final class FakeListCursorStore: ListCursorStoring {
    private var cursors: [String: String] = [:]

    func loadCursorRowId(list: String) -> String? {
        cursors[list]
    }

    func saveCursorRowId(_ rowId: String, list: String) {
        cursors[list] = rowId
    }
}

/// The VoiceOver switch of the test device. Records each announcement.
@MainActor
final class FakeVoiceOver: VoiceOverAnnouncing {
    var isRunning = false
    private(set) var announcedTexts: [String] = []
    private(set) var announcedPriorities: [AnnouncementPriority] = []

    func announce(_ text: String, priority: AnnouncementPriority) {
        announcedTexts.append(text)
        announcedPriorities.append(priority)
    }
}

/// The fakes of one list, given to the reader as its services.
@MainActor
struct ListFakes {
    let speaker: FakeSpeaker
    let sleeper: FakeSleeper
    let cursorStore: FakeListCursorStore
    let voiceOver: FakeVoiceOver

    init(holdsSpeech: Bool = false, holdsPause: Bool = false) {
        speaker = FakeSpeaker(holdsSpeech: holdsSpeech)
        sleeper = FakeSleeper(holdsPause: holdsPause)
        cursorStore = FakeListCursorStore()
        voiceOver = FakeVoiceOver()
    }

    var services: ListServices {
        ListServices(speaker: speaker, sleeper: sleeper, cursorStore: cursorStore, voiceOver: voiceOver)
    }
}

/// Lets the tasks on the main actor run until the condition is true.
/// Records an issue when the condition stays false.
@MainActor
func waitUntil(
    _ condition: () -> Bool,
    sourceLocation: SourceLocation = #_sourceLocation
) async {
    for _ in 0..<1_000 {
        if condition() { return }
        await Task.yield()
    }
    Issue.record("The condition stayed false.", sourceLocation: sourceLocation)
}

/// Lets the tasks on the main actor run for a short time. A test uses it
/// to show that something does not occur.
@MainActor
func letTasksRun() async {
    for _ in 0..<100 {
        await Task.yield()
    }
}
