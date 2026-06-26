import WidgetKit
import SwiftUI

@available(iOS 14.0, *)
struct TodayWidgetEntryView: View {
  var entry: Provider.Entry
  @Environment(\.widgetFamily) var family

  var body: some View {
    switch family {
    case .systemSmall: SmallView(data: entry.data)
    case .systemMedium: MediumView(data: entry.data)
    case .systemLarge: LargeView(data: entry.data)
    default: MediumView(data: entry.data)
    }
  }
}

@available(iOS 14.0, *)
struct TodayWidgetBundle: WidgetBundle {
  var body: some Widget {
    TodayWidget()
  }
}

@available(iOS 14.0, *)
struct TodayWidget: Widget {
  let kind = "TodayWidget"
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      TodayWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("今日课程")
    .description("查看今日课程安排和下一节课")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

@main
struct AppWidgetBundle {
  static func main() {
    if #available(iOS 14.0, *) {
      TodayWidgetBundle.main()
    }
  }
}
