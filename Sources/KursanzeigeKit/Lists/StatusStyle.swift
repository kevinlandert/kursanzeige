/// The look of the status line above the buttons.
public enum StatusStyle: Sendable, Hashable {
    /// Ink on the neutral fill: the cursor row is selected.
    case idle
    /// White on blue: Vorlesen reads.
    case reading
}
