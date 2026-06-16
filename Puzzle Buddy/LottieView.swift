//
//  LottieView.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 10/27/22.
//

import Lottie
import SwiftUI

private struct LottieView: UIViewRepresentable {
    var name: String
    var loopMode: LottieLoopMode

    init(name: String, loopMode: LottieLoopMode) {
        self.name = name
        self.loopMode = loopMode
    }

    func makeUIView(context: UIViewRepresentableContext<LottieView>) -> UIView {
        let view = UIView(frame: .zero)

        let animationView = LottieAnimationView()
        let animation = Animation.named(name)

        animationView.animation = animation
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loopMode
        animationView.play()

        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)

        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])

        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

public enum LottieAnimations: String {
    case login = "login"
    case profile = "profile"
    case photo = "photo"
    case puzzle = "puzzle"
}

public struct PuzzleAnimation: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var name: LottieAnimations
    @State private var loopMode: LottieLoopMode

    public init(_ name: LottieAnimations = .login, loopMode: LottieLoopMode) {
        self.name = name
        self.loopMode = loopMode
    }

    public var body: some View {
        if reduceMotion {
            Image(systemName: "puzzlepiece.extension.fill")
                .font(.largeTitle)
                .foregroundStyle(Brand.accent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityHidden(true)
        } else {
            LottieView(name: name.rawValue, loopMode: loopMode)
                .accessibilityHidden(true)
        }
    }
}

struct PuzzleAnimation_Previews: PreviewProvider {
    static var previews: some View {
        LottieView(name: "login", loopMode: .loop)
    }
}
