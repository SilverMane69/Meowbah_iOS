import Foundation
import ActivityKit

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var activity: Activity<MeowTalkLiveAttributes>?

    func startIfNeeded(initialPhrase: String, name: String = "MeowTalk") async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        if let activity {
            await update(phrase: initialPhrase)
            return
        }

        let attributes = MeowTalkLiveAttributes(name: name)
        let state = MeowTalkLiveAttributes.ContentState(phrase: initialPhrase)

        do {
            let activity = try Activity.request(
                attributes: attributes,
                contentState: state,
                pushType: nil
            )
            self.activity = activity
        } catch {
            // Optionally log error
        }
    }

    func update(phrase: String) async {
        if activity == nil {
            await startIfNeeded(initialPhrase: phrase)
            return
        }
        let state = MeowTalkLiveAttributes.ContentState(phrase: phrase)
        await activity?.update(using: state)
    }

    func end(immediately: Bool = false) async {
        guard let activity else { return }
        let finalState = MeowTalkLiveAttributes.ContentState(phrase: "")
        await activity.end(using: finalState, dismissalPolicy: immediately ? .immediate : .default)
        self.activity = nil
    }
}
