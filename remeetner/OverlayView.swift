//
//  OverlayView.swift
//  remeetner
//
//  Created by Alberto Diaz on 24-06-25.
//

import SwiftUI

struct OverlayView: View {
    let secondsRemaining: Int
    let duration: Int
    let onTap: () -> Void

    var progress: Double {
        duration > 0 ? 1 - Double(secondsRemaining) / Double(duration) : 1
    }

    var body: some View {
        VStack(spacing: 30) {
            Text("⏳ Time to take a break!")
                .font(.largeTitle)
                .foregroundColor(.white)

            Text("Rest your eyes and stretch a bit.")
                .font(.title2)
                .foregroundColor(.white.opacity(0.85))

            VStack(spacing: 10) {
                Text("It will close in \(secondsRemaining) seconds.")
                    .font(.headline)
                    .foregroundColor(.white)

                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .frame(width: 200)
            }

            Text("(Click anywhere to continue)")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}
