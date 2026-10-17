import os

/// Waits for a task that the caller does not own, and stops the wait when
/// the task of the caller is cancelled. The awaited task goes on. A plain
/// `await task.value` ignores the cancel of the caller, so a stopped speech
/// could wait for a slow fetch and hold back the next speech.
enum CancellableWait {
    static func wait(for task: Task<Void, Never>) async {
        let resumer = OnceResumer()
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                resumer.keep(continuation)
                Task {
                    await task.value
                    resumer.resume()
                }
            }
        } onCancel: {
            resumer.resume()
        }
    }
}

/// Resumes a continuation exactly one time: after the task or after the
/// cancel, whichever comes first. The cancel can come before the
/// continuation exists.
private final class OnceResumer: Sendable {
    private enum State {
        case waiting
        case kept(CheckedContinuation<Void, Never>)
        case resumed
    }

    private let state = OSAllocatedUnfairLock(initialState: State.waiting)

    func keep(_ continuation: CheckedContinuation<Void, Never>) {
        let isResumed = state.withLock { state in
            if case .resumed = state { return true }
            state = .kept(continuation)
            return false
        }
        if isResumed {
            continuation.resume()
        }
    }

    func resume() {
        let continuation = state.withLock { state -> CheckedContinuation<Void, Never>? in
            defer { state = .resumed }
            if case .kept(let continuation) = state { return continuation }
            return nil
        }
        continuation?.resume()
    }
}
