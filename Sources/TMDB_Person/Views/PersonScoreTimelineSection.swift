import Charts
import SwiftUI
import TMDB_Shared_Backend

/// One rated movie, placed on the timeline by release year.
struct PersonScorePoint: Identifiable, Equatable {
    let id: Int
    let title: String
    let year: Int
    let score: Double

    /// Below this many votes a score is noise: a single 10/10 from one viewer would top the chart.
    static let minimumVoteCount = 10

    /// Unreleased and barely rated titles are left out: TMDB reports a 0 average for a movie nobody
    /// has voted on, which would plot as a flop rather than as missing data.
    static func points(from credits: [PersonMovieCredit]) -> [PersonScorePoint] {
        credits
            .compactMap { credit in
                guard credit.voteCount >= minimumVoteCount, let year = credit.releaseYearText.flatMap(Int.init) else { return nil }
                return PersonScorePoint(id: credit.id, title: credit.title, year: year, score: credit.voteAverage)
            }
            .sorted { ($0.year, $0.id) < ($1.year, $1.id) }
    }
}

@available(iOS 16.0, *)
struct PersonScoreTimelineSection: View {
    let points: [PersonScorePoint]

    init(credits: [PersonMovieCredit]) {
        points = PersonScorePoint.points(from: credits)
    }

    /// The trend line follows the mean score of each year, so several releases in one year don't zigzag.
    private var yearlyAverages: [(year: Int, score: Double)] {
        Dictionary(grouping: points, by: \.year)
            .map { year, points in (year, points.map(\.score).reduce(0, +) / Double(points.count)) }
            .sorted { $0.year < $1.year }
    }

    var body: some View {
        // A single point is not a trend.
        if points.count > 1 {
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStringResource.personScoreTimeline)
                    .font(.headline)

                Chart {
                    ForEach(yearlyAverages, id: \.year) { average in
                        LineMark(
                            x: .value(Text(LocalizedStringResource.personChartYear), average.year),
                            y: .value(Text(LocalizedStringResource.personChartScore), average.score)
                        )
                        // Monotone never overshoots, so the line stays inside the 0...10 scale.
                        .interpolationMethod(.monotone)
                        .foregroundStyle(Color.accentColor)
                    }

                    ForEach(points) { point in
                        PointMark(
                            x: .value(Text(LocalizedStringResource.personChartYear), point.year),
                            y: .value(Text(LocalizedStringResource.personChartScore), point.score)
                        )
                        .foregroundStyle(Color.accentColor.opacity(0.45))
                        .accessibilityLabel(point.title)
                        .accessibilityValue("\(point.year), \(point.score.formatted(.number.precision(.fractionLength(1))))")
                    }
                }
                .chartYScale(domain: 0 ... 10)
                .chartXScale(domain: .automatic(includesZero: false))
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            // The default number format would render years as "2,010".
                            if let year = value.as(Int.self) {
                                Text(String(year))
                            }
                        }
                    }
                }
                .frame(height: 200)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityIdentifier("personDetail.scoreTimeline.chart")
            }
        }
    }
}
