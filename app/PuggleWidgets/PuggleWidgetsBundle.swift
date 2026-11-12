import SwiftUI
import WidgetKit

@main
struct PuggleWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TimerLiveActivity()
        ChildWidget()
        FamilyWidget()
        if #available(iOS 18.0, *) {
            StartSleepControl()
        }
    }
}
