/// The side effects of a list with a cursor: the voice, the pause between
/// rows, the cursor store and VoiceOver. The app makes them once. Tests
/// give fakes.
struct ListServices {
    let speaker: any Speaking
    let sleeper: any Sleeping
    let cursorStore: any ListCursorStoring
    let voiceOver: any VoiceOverAnnouncing

    /// Returns a copy with another cursor store and the same voice.
    func makeCopy(cursorStore newCursorStore: any ListCursorStoring) -> ListServices {
        ListServices(speaker: speaker, sleeper: sleeper, cursorStore: newCursorStore, voiceOver: voiceOver)
    }
}
