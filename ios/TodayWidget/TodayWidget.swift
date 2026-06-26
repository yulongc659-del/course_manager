import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> WidgetEntry {
    WidgetEntry(date: Date(), widgetData: sampleData())
  }

  func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
    let entry = WidgetEntry(date: Date(), widgetData: loadOrSample())
    completion(entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
    let entry = WidgetEntry(date: Date(), widgetData: loadOrSample())
    let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
    let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
    completion(timeline)
  }

  func loadOrSample() -> [String: Any] {
    return WidgetData.loadWidgetData() ?? sampleData()
  }

  func sampleData() -> [String: Any] {
    return [
      "currentWeek": 1,
      "semesterName": "春季学期",
      "todayDate": "周一",
      "todayCourseCount": 3,
      "todayCourses": [],
      "nextClass": nil as Any? as Any,
      "aiTip": "",
    ]
  }
}

struct WidgetEntry: TimelineEntry {
  let date: Date
  let widgetData: [String: Any]
}

struct TodayWidgetEntryView: View {
  var entry: Provider.Entry
  @Environment(\.widgetFamily) var family

  var body: some View {
    switch family {
    case .systemSmall:
      SmallWidgetView(data: entry.widgetData)
    case .systemMedium:
      MediumWidgetView(data: entry.widgetData)
    case .systemLarge:
      LargeWidgetView(data: entry.widgetData)
    default:
      MediumWidgetView(data: entry.widgetData)
    }
  }
}

struct SmallWidgetView: View {
  let data: [String: Any]

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(data["semesterName"] as? String ?? "")
          .font(.caption2)
          .foregroundColor(.secondary)
        Spacer()
        Text("W\(data["currentWeek"] as? Int ?? 1)")
          .font(.caption)
          .fontWeight(.bold)
      }
      Spacer()
      if let next = data["nextClass"] as? [String: Any] {
        VStack(alignment: .leading, spacing: 2) {
          Text("下一节")
            .font(.caption2)
            .foregroundColor(.secondary)
          Text(next["name"] as? String ?? "")
            .font(.headline)
            .lineLimit(1)
          Text("\(next["time"] as? String ?? "")")
            .font(.caption)
            .foregroundColor(.secondary)
          if let room = next["classroom"] as? String, !room.isEmpty {
            Label(room, systemImage: "location.fill")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        }
      } else {
        VStack(alignment: .leading, spacing: 2) {
          Image(systemName: "checkmark.circle.fill")
            .font(.title2)
            .foregroundColor(.green)
          Text("今日无课")
            .font(.subheadline)
        }
      }
      Spacer()
    }
    .padding()
    .containerBackground(.ultraThinMaterial, for: .widget)
  }
}

struct MediumWidgetView: View {
  let data: [String: Any]

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("今日课程")
          .font(.headline)
        Text(data["todayDate"] as? String ?? "")
          .font(.caption)
          .foregroundColor(.secondary)
        Text("第\(data["currentWeek"] as? Int ?? 1)周 · \(data["todayCourseCount"] as? Int ?? 0)门课")
          .font(.caption2)
          .foregroundColor(.secondary)

        Spacer()

        if let courses = data["todayCourses"] as? [[String: Any]], !courses.isEmpty {
          ForEach(courses.prefix(4).indices, id: \.self) { i in
            let course = courses[i]
            HStack(spacing: 6) {
              Circle()
                .fill(courseColor(Int(course["color"] as? Int ?? 0)))
                .frame(width: 8, height: 8)
              Text(course["name"] as? String ?? "")
                .font(.caption)
                .lineLimit(1)
              Spacer()
              Text(course["period"] as? String ?? "")
                .font(.caption2)
                .foregroundColor(.secondary)
            }
          }
        } else {
          Text("今日无课程安排")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        Spacer()
      }
      Spacer()
    }
    .padding()
    .containerBackground(.ultraThinMaterial, for: .widget)
  }

  func courseColor(_ index: Int) -> Color {
    let colors: [Color] = [
      Color(red: 0.13, green: 0.59, blue: 0.95),
      Color(red: 0.20, green: 0.78, blue: 0.35),
      Color(red: 1.00, green: 0.58, blue: 0.00),
      Color(red: 0.69, green: 0.32, blue: 0.87),
      Color(red: 1.00, green: 0.18, blue: 0.33),
      Color(red: 0.35, green: 0.78, blue: 0.98),
      Color(red: 0.55, green: 0.44, blue: 0.28),
      Color(red: 0.43, green: 0.47, blue: 0.54),
    ]
    return colors[index % colors.count]
  }
}

struct LargeWidgetView: View {
  let data: [String: Any]

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        VStack(alignment: .leading) {
          Text("今日课程")
            .font(.title3).bold()
          Text(data["todayDate"] as? String ?? "")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        Spacer()
        VStack(alignment: .trailing) {
          Text("W\(data["currentWeek"] as? Int ?? 1)")
            .font(.title2).bold()
          Text("\(data["todayCourseCount"] as? Int ?? 0)门")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      if let courses = data["todayCourses"] as? [[String: Any]], !courses.isEmpty {
        Divider()
        ForEach(courses.indices, id: \.self) { i in
          let course = courses[i]
          HStack(spacing: 8) {
            Circle()
              .fill(courseColor(Int(course["color"] as? Int ?? 0)))
              .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 1) {
              Text(course["name"] as? String ?? "")
                .font(.subheadline).bold()
                .lineLimit(1)
              HStack(spacing: 8) {
                Text(course["period"] as? String ?? "")
                  .font(.caption2)
                Text(course["teacher"] as? String ?? "")
                  .font(.caption2)
                  .foregroundColor(.secondary)
                if let room = course["classroom"] as? String, !room.isEmpty {
                  Label(room, systemImage: "location.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
              }
            }
            Spacer()
            Text(course["time"] as? String ?? "")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          if i < courses.count - 1 { Divider() }
        }
      } else {
        Spacer()
        HStack {
          Spacer()
          VStack {
            Image(systemName: "checkmark.circle.fill")
              .font(.largeTitle)
              .foregroundColor(.green)
            Text("今日无课程安排")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          Spacer()
        }
        Spacer()
      }

      if let tip = data["aiTip"] as? String, !tip.isEmpty {
        Divider()
        HStack(spacing: 4) {
          Image(systemName: "sparkles")
            .font(.caption2)
            .foregroundColor(.blue)
          Text(tip)
            .font(.caption2)
            .foregroundColor(.secondary)
            .lineLimit(2)
        }
      }
    }
    .padding()
    .containerBackground(.ultraThinMaterial, for: .widget)
  }

  func courseColor(_ index: Int) -> Color {
    let colors: [Color] = [
      Color(red: 0.13, green: 0.59, blue: 0.95),
      Color(red: 0.20, green: 0.78, blue: 0.35),
      Color(red: 1.00, green: 0.58, blue: 0.00),
      Color(red: 0.69, green: 0.32, blue: 0.87),
      Color(red: 1.00, green: 0.18, blue: 0.33),
      Color(red: 0.35, green: 0.78, blue: 0.98),
      Color(red: 0.55, green: 0.44, blue: 0.28),
      Color(red: 0.43, green: 0.47, blue: 0.54),
    ]
    return colors[index % colors.count]
  }
}
