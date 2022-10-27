//
//  LottieView.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 10/27/22.
//

import Lottie
import SwiftUI

struct LottieView: UIViewRepresentable {
    var name = "login"
    var loopMode: LottieLoopMode = .loop

    init(name: String = "login", loopMode: LottieLoopMode) {
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

struct PuzzleAnimation: View {
    var body: some View {
        LottieView(name: "login", loopMode: .autoReverse)
    }
}

struct PuzzleAnimation_Previews: PreviewProvider {
    static var previews: some View {
        LottieView(name: "login", loopMode: .loop)
    }
}
