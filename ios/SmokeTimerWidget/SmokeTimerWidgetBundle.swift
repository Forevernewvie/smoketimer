import WidgetKit
import SwiftUI

@main
struct SmokeTimerWidgetBundle: WidgetBundle {
    /// Registers every widget shipped with the Smoke Timer extension target.
    var body: some Widget {
        SmokeTimerWidget()
    }
}
