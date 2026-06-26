import WidgetKit
import SwiftUI

@main
struct TodayWidgetBundle: WidgetBundle {
  var body: some Widget {
    TodayWidget()
  }
}

struct TodayWidget: Widget {
  let kind: String = "TodayWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      TodayWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("今日课程")
    .description("查看今日课程安排和下一节课")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}
