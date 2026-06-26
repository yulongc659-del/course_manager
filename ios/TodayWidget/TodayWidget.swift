import WidgetKit
import SwiftUI

// Shared data access from App Group
private let appGroup = "group.com.course.manager"
private func sharedDefaults() -> UserDefaults {
  return UserDefaults(suiteName: appGroup) ?? UserDefaults.standard
}
private func loadWidgetData() -> [String: Any]? {
  guard let json = sharedDefaults().string(forKey: "widget_data"),
        let data = json.data(using: .utf8) else { return nil }
  return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
}

private let courseColors: [Color] = [
  Color(red: 0.13, green: 0.59, blue: 0.95),
  Color(red: 0.20, green: 0.78, blue: 0.35),
  Color(red: 1.00, green: 0.58, blue: 0.00),
  Color(red: 0.69, green: 0.32, blue: 0.87),
  Color(red: 1.00, green: 0.18, blue: 0.33),
  Color(red: 0.35, green: 0.78, blue: 0.98),
  Color(red: 0.55, green: 0.44, blue: 0.28),
  Color(red: 0.43, green: 0.47, blue: 0.54),
]

@available(iOS 14.0, *)
struct Provider: TimelineProvider {
  typealias Entry = WidgetEntry

  func placeholder(in context: Context) -> WidgetEntry {
    WidgetEntry(date: Date(), data: [:])
  }

  func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
    completion(WidgetEntry(date: Date(), data: loadWidgetData() ?? [:]))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
    let entry = WidgetEntry(date: Date(), data: loadWidgetData() ?? [:])
    let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
    completion(Timeline(entries: [entry], policy: .after(next)))
  }
}

struct WidgetEntry: TimelineEntry {
  let date: Date
  let data: [String: Any]
}

@available(iOS 14.0, *)
struct SmallView: View {
  let data: [String: Any]
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(data["semesterName"] as? String ?? "").font(.caption2).foregroundColor(.secondary)
        Spacer()
        Text("W\(data["currentWeek"] as? Int ?? 1)").font(.caption).bold()
      }
      Spacer()
      if let next = data["nextClass"] as? [String: Any] {
        Text("下一节").font(.caption2).foregroundColor(.secondary)
        VStack(alignment: .leading, spacing: 2) {
          Text(next["name"] as? String ?? "").font(.headline).lineLimit(1)
          Text("\(next["time"] as? String ?? "")").font(.caption).foregroundColor(.secondary)
          if let room = next["classroom"] as? String, !room.isEmpty {
            HStack(spacing: 2) {
              Image(systemName: "location.fill").font(.caption2)
              Text(room).font(.caption2)
            }.foregroundColor(.secondary)
          }
        }
      } else {
        Image(systemName: "checkmark.circle.fill").font(.title2).foregroundColor(.green)
        Text("今日无课").font(.subheadline)
      }
      Spacer()
    }.padding()
  }
}

@available(iOS 14.0, *)
struct MediumView: View {
  let data: [String: Any]
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text("今日课程").font(.headline)
        Spacer()
        Text("W\(data["currentWeek"] as? Int ?? 1)").font(.headline)
      }
      Text(data["todayDate"] as? String ?? "").font(.caption).foregroundColor(.secondary)
      Spacer()
      if let courses = data["todayCourses"] as? [[String: Any]], !courses.isEmpty {
        ForEach(courses.prefix(4).indices, id: \.self) { i in
          let c = courses[i]
          HStack(spacing: 6) {
            Circle().fill(courseColors[(c["color"] as? Int ?? 0) % courseColors.count])
              .frame(width: 8, height: 8)
            Text(c["name"] as? String ?? "").font(.caption).lineLimit(1)
            Spacer()
            Text(c["period"] as? String ?? "").font(.caption2).foregroundColor(.secondary)
          }
        }
      } else {
        Text("今日无课程安排").font(.subheadline).foregroundColor(.secondary)
      }
      Spacer()
    }.padding()
  }
}

@available(iOS 14.0, *)
struct LargeView: View {
  let data: [String: Any]
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        VStack(alignment: .leading) {
          Text("今日课程").font(.title3).bold()
          Text(data["todayDate"] as? String ?? "").font(.subheadline).foregroundColor(.secondary)
        }
        Spacer()
        VStack(alignment: .trailing) {
          Text("W\(data["currentWeek"] as? Int ?? 1)").font(.title2).bold()
          Text("\(data["todayCourseCount"] as? Int ?? 0)门").font(.caption).foregroundColor(.secondary)
        }
      }
      if let courses = data["todayCourses"] as? [[String: Any]], !courses.isEmpty {
        Divider()
        ForEach(courses.indices, id: \.self) { i in
          let c = courses[i]
          VStack(spacing: 4) {
            HStack(spacing: 8) {
              Circle().fill(courseColors[(c["color"] as? Int ?? 0) % courseColors.count])
                .frame(width: 10, height: 10)
              VStack(alignment: .leading, spacing: 1) {
                Text(c["name"] as? String ?? "").font(.subheadline).bold().lineLimit(1)
                HStack(spacing: 8) {
                  Text(c["period"] as? String ?? "").font(.caption2)
                  Text(c["teacher"] as? String ?? "").font(.caption2).foregroundColor(.secondary)
                  if let room = c["classroom"] as? String, !room.isEmpty {
                    HStack(spacing: 2) {
                      Image(systemName: "location.fill").font(.caption2)
                      Text(room).font(.caption2)
                    }.foregroundColor(.secondary)
                  }
                }
              }
              Spacer()
              Text(c["time"] as? String ?? "").font(.caption).foregroundColor(.secondary)
            }
          }
          if i < courses.count - 1 { Divider() }
        }
      } else {
        Spacer()
        HStack { Spacer()
          VStack {
            Image(systemName: "checkmark.circle.fill").font(.largeTitle).foregroundColor(.green)
            Text("今日无课程安排").font(.subheadline).foregroundColor(.secondary)
          }
          Spacer()
        }
        Spacer()
      }
      if let tip = data["aiTip"] as? String, !tip.isEmpty {
        Divider()
        HStack(spacing: 4) {
          Image(systemName: "sparkles").font(.caption2).foregroundColor(.blue)
          Text(tip).font(.caption2).foregroundColor(.secondary).lineLimit(2)
        }
      }
    }.padding()
  }
}
