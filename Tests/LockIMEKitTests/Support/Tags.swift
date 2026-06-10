import Testing

extension Tag {
    /// Tests that touch the real keyboard/input-source system. Opt in by setting
    /// `LOCKIME_HW_TESTS=1`; excluded from the default (CI-safe) run.
    @Tag static var hardware: Tag
}
