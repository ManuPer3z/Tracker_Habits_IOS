//
//  MakiLiveActivity.swift
//  Maki
//
//  Created by Nick Elao on 28/1/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct MakiAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct MakiLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MakiAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension MakiAttributes {
    fileprivate static var preview: MakiAttributes {
        MakiAttributes(name: "World")
    }
}

extension MakiAttributes.ContentState {
    fileprivate static var smiley: MakiAttributes.ContentState {
        MakiAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: MakiAttributes.ContentState {
         MakiAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: MakiAttributes.preview) {
   MakiLiveActivity()
} contentStates: {
    MakiAttributes.ContentState.smiley
    MakiAttributes.ContentState.starEyes
}
