import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: [SortDescriptor(\TodoItem.completedAt, order: .reverse)])
    private var allItems: [TodoItem]

    @AppStorage("confettiShownDate") private var confettiShownDate: String = ""
    @State private var showConfetti = false
    @State private var reactingTo: TodoItem?

    private static let isoDayFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f
    }()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    private static let reactionChoices = ["🙏", "❤️", "🎉", "👏", "🔥"]

    private var weekDays: [Date] {
        CalendarHelper.daysOfCurrentWeek()
    }

    private var weekStart: Date { weekDays.first ?? CalendarHelper.today }
    private var weekEnd: Date {
        guard let last = weekDays.last else { return CalendarHelper.today }
        return CalendarHelper.weekCalendar.date(byAdding: .day, value: 1, to: last) ?? last
    }

    private var itemsCompletedThisWeek: [TodoItem] {
        allItems.filter { item in
            guard let completedAt = item.completedAt else { return false }
            return completedAt >= weekStart && completedAt < weekEnd
        }
    }

    private var openItemsThisWeek: [TodoItem] {
        let calendar = CalendarHelper.weekCalendar
        return allItems.filter { item in
            guard item.completedAt == nil else { return false }
            return weekDays.contains { calendar.isDate($0, inSameDayAs: item.day) }
        }
    }

    private var itemsDueToday: [TodoItem] {
        let calendar = CalendarHelper.weekCalendar
        let today = CalendarHelper.today
        return allItems.filter { calendar.isDate($0.day, inSameDayAs: today) }
    }

    private var allTodayDone: Bool {
        let todays = itemsDueToday
        return !todays.isEmpty && todays.allSatisfy { $0.completedAt != nil }
    }

    private var recentActivity: [TodoItem] {
        Array(itemsCompletedThisWeek.prefix(10))
    }

    private var assigneeBreakdown: [(label: String, count: Int)] {
        var alex = 0
        var sam = 0
        var unassigned = 0
        for item in itemsCompletedThisWeek {
            switch item.assigneeId {
            case "alex": alex += 1
            case "sam": sam += 1
            default: unassigned += 1
            }
        }
        var rows: [(String, Int)] = []
        if alex > 0 { rows.append(("Alex", alex)) }
        if sam > 0 { rows.append(("Sam", sam)) }
        if unassigned > 0 { rows.append(("Unassigned", unassigned)) }
        return rows
    }

    private var todayKey: String {
        Self.isoDayFormatter.string(from: CalendarHelper.today)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if allTodayDone {
                        celebrationBanner
                    }
                    statsCard
                    activityCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Home")
            .overlay {
                if showConfetti {
                    ConfettiView()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            .confirmationDialog(
                "Add a reaction",
                isPresented: Binding(
                    get: { reactingTo != nil },
                    set: { if !$0 { reactingTo = nil } }
                ),
                titleVisibility: .visible,
                presenting: reactingTo
            ) { item in
                ForEach(Self.reactionChoices, id: \.self) { emoji in
                    Button(emoji) { addReaction(emoji, to: item) }
                }
                Button("Cancel", role: .cancel) { }
            }
        }
        .tint(.indigo)
        .onAppear { maybeTriggerConfetti() }
        .onChange(of: allTodayDone) { _, _ in
            maybeTriggerConfetti()
        }
    }

    // MARK: - Cards

    private var celebrationBanner: some View {
        VStack(spacing: 6) {
            Text("All done today! 🎉")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Nice work today!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(.indigo.opacity(0.12), in: .rect(cornerRadius: 16))
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("This week")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(itemsCompletedThisWeek.count)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(.indigo)
                    .contentTransition(.numericText())
                Text(itemsCompletedThisWeek.count == 1 ? "task done" : "tasks done")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            if !assigneeBreakdown.isEmpty {
                Text(assigneeBreakdownText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .padding(.vertical, 2)

            HStack(spacing: 8) {
                Image(systemName: "circle.dashed")
                    .foregroundStyle(.indigo)
                Text("\(openItemsThisWeek.count) ^[task](inflect: true) left this week")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
    }

    private var assigneeBreakdownText: String {
        assigneeBreakdown
            .map { "\($0.label) \($0.count)" }
            .joined(separator: " · ")
    }

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recent activity")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            if recentActivity.isEmpty {
                Text("No completed tasks yet this week.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            } else {
                ForEach(Array(recentActivity.enumerated()), id: \.element.id) { index, item in
                    activityRow(item)
                    if index < recentActivity.count - 1 {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
    }

    private func activityRow(_ item: TodoItem) -> some View {
        Button {
            reactingTo = item
        } label: {
            HStack(alignment: .top, spacing: 12) {
                assigneeChip(for: item.assigneeId)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(item.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        Spacer(minLength: 8)
                        if let completedAt = item.completedAt {
                            Text(Self.relativeFormatter.localizedString(for: completedAt, relativeTo: .now))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .multilineTextAlignment(.leading)

                    if !item.reactions.isEmpty {
                        Text(item.reactions.joined(separator: " "))
                            .font(.subheadline)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Add a reaction")
    }

    @ViewBuilder
    private func assigneeChip(for assigneeId: String?) -> some View {
        if let assignee = Assignee.find(id: assigneeId) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 26))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, assignee.color)
        } else {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 26))
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Actions

    private func addReaction(_ emoji: String, to item: TodoItem) {
        item.reactions.append(emoji)
    }

    private func maybeTriggerConfetti() {
        guard allTodayDone, confettiShownDate != todayKey else { return }
        confettiShownDate = todayKey
        withAnimation(.easeIn(duration: 0.15)) { showConfetti = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeOut(duration: 0.3)) { showConfetti = false }
        }
    }
}

// MARK: - Confetti

/// Lightweight emoji confetti rendered with Canvas + TimelineView. No
/// dependencies, ~2 seconds long, respects Reduce Motion.
private struct ConfettiView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let symbols = ["🎉", "✨", "⭐", "🎊"]
    private let particles: [Particle]
    private let start = Date()

    init() {
        var generator = SystemRandomNumberGenerator()
        self.particles = (0..<28).map { _ in
            Particle(
                symbol: Self.symbols.randomElement(using: &generator) ?? "🎉",
                startX: Double.random(in: 0...1, using: &generator),
                drift: Double.random(in: -0.15...0.15, using: &generator),
                fallDuration: Double.random(in: 1.4...1.9, using: &generator),
                delay: Double.random(in: 0...0.4, using: &generator),
                rotation: Double.random(in: -180...180, using: &generator),
                size: Double.random(in: 18...30, using: &generator)
            )
        }
    }

    var body: some View {
        if reduceMotion {
            // Honor Reduce Motion: skip the animation entirely.
            EmptyView()
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { context in
                Canvas { canvasContext, size in
                    let elapsed = context.date.timeIntervalSince(start)
                    for particle in particles {
                        let local = elapsed - particle.delay
                        guard local >= 0, local <= particle.fallDuration else { continue }
                        let progress = local / particle.fallDuration
                        let x = (particle.startX + particle.drift * progress) * size.width
                        let y = -40 + progress * (size.height + 80)
                        let angle = particle.rotation * progress
                        let opacity = 1.0 - max(0, progress - 0.7) / 0.3

                        var resolved = canvasContext.resolve(
                            Text(particle.symbol).font(.system(size: particle.size))
                        )
                        resolved.shading = .color(.primary.opacity(opacity))
                        canvasContext.drawLayer { layer in
                            layer.translateBy(x: x, y: y)
                            layer.rotate(by: .degrees(angle))
                            layer.draw(resolved, at: .zero)
                        }
                    }
                }
            }
        }
    }

    private struct Particle {
        let symbol: String
        let startX: Double
        let drift: Double
        let fallDuration: Double
        let delay: Double
        let rotation: Double
        let size: Double
    }
}

#Preview {
    HomeView()
        .modelContainer(AppModelContainer.shared)
}
