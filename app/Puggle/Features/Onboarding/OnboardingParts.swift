import SwiftUI

/// The steps of first run, in order. The raw value gives the direction of travel.
enum OnboardingStep: Int, CaseIterable {
    case welcome, joining, found, logging, everyChild, together, lookingBack, privacy, you, child, more, invite, family

    /// The pages about the app, before any question: one feature each. Sharing is left out of a build without iCloud.
    static var pages: [OnboardingStep] {
        var all: [OnboardingStep] = [.logging, .everyChild, .together, .lookingBack, .privacy]
        #if DEBUG
        // For checking every page in a build without iCloud: "-debugFirstRunAll 1".
        if UserDefaults.standard.string(forKey: "debugFirstRunAll") == "1" { return all }
        #endif
        if !Persistence.cloudSyncEnabled { all.removeAll { $0 == .together } }
        return all
    }
    /// The setup screens. Adding another child returns to the second.
    static var setup: [OnboardingStep] { Persistence.cloudSyncEnabled ? [.you, .child, .more, .invite] : [.you, .child, .more] }

    /// Where this step is in its run, for the progress bar.
    var dots: (current: Int, count: Int)? {
        if let index = Self.pages.firstIndex(of: self) { return (index, Self.pages.count) }
        if let index = Self.setup.firstIndex(of: self) { return (index, Self.setup.count) }
        return nil
    }

    /// The page after this one, among the pages about the app; setup follows the last.
    var nextPage: OnboardingStep {
        guard let index = Self.pages.firstIndex(of: self), index + 1 < Self.pages.count else { return .you }
        return Self.pages[index + 1]
    }

    /// The page before this one, among the pages about the app; the welcome comes before the first.
    var previousPage: OnboardingStep {
        guard let index = Self.pages.firstIndex(of: self), index > 0 else { return .welcome }
        return Self.pages[index - 1]
    }
}
