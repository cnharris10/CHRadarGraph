//
//  SwiftUIDemoView.swift
//  CHRadarGraph
//
//  Demonstrates the CHRadarGraph SwiftUI wrapper (as opposed to the
//  delegate/dataSource-based CHRadarGraphView used by ViewController) - the
//  same PR-count data, but with no protocol conformance required.
//

import SwiftUI
import CHRadarGraph

@available(iOS 14.0, *)
struct SwiftUIDemoView: View {

    private let sectors: [CHRadarGraph.Sector] = [
        .init(height: 4, label: "7am", color: .blue),
        .init(height: 8, label: "8am", color: .blue),
        .init(height: 12, label: "9am", color: .blue),
        .init(height: 16, label: "10am", color: .blue),
        .init(height: 20, label: "11am", color: .blue),
        .init(height: 24, label: "12pm", color: .blue),
        .init(height: 28, label: "1pm", color: .blue),
        .init(height: 32, label: "2pm", color: .blue),
        .init(height: 36, label: "3pm", color: .blue),
        .init(height: 40, label: "4pm", color: .blue)
    ]

    @State private var selectionText: String?

    var body: some View {
        VStack(spacing: 16) {
            Text(selectionText ?? "Tap a sector")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(selectionText == nil ? .secondary : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(white: 0.95))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.top, 12)

            CHRadarGraph(
                sectors: sectors,
                totalSectorSlots: 16,
                numberOfRings: 10,
                title: "Number of GitHub PR's created",
                onSelect: { sector, _ in
                    selectionText = "\(Int(sector.height)) PR's created at \(sector.label ?? "")"
                },
                onDeselectAll: {
                    selectionText = nil
                }
            )
            // CHRadarGraph's underlying UIView has no intrinsic content size,
            // so SwiftUI collapses it to zero height unless told to fill
            // whatever space is available.
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("SwiftUI Wrapper")
    }
}
