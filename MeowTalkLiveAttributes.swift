import Foundation
#if os(iOS)
import ActivityKit

// Live Activity attributes for MeowTalk
public struct MeowTalkLiveAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // The current phrase to show in the Live Activity / Dynamic Island
        public var phrase: String

        public init(phrase: String) {
            self.phrase = phrase
        }
    }

    // A simple attribute for demonstration; not used for rendering but part of the attributes
    public var name: String

    public init(name: String) {
        self.name = name
    }
}
#endif
