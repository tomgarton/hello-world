import SwiftUI
import WidgetKit

/// Two bundles, because a bundle cannot say "this widget, or else that one". From iOS 18 the Live Activity
/// has a small card for Apple Watch and CarPlay, and Control Centre has a button.
@main
struct PuggleWidgetsEntry {
    static func main() {
        if #available(iOS 18.0, *) {
            PuggleWidgetsBundle.main()
        } else {
            PuggleWidgetsBundleBefore18.main()
        }
    }
}

@available(iOS 18.0, *)
struct PuggleWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TimerLiveActivityWithSmall()
        SnapshotWidget()
        ChildWidget()
        FamilyWidget()
        StartSleepControl()
    }
}

struct PuggleWidgetsBundleBefore18: WidgetBundle {
    var body: some Widget {
        TimerLiveActivity()
        SnapshotWidget()
        ChildWidget()
        FamilyWidget()
    }
}
