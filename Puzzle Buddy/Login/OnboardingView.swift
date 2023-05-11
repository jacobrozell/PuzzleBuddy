//
//  OnboardingView.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 5/11/23.
//

import SwiftUI

struct OnboardingView: View {
    enum Tab {
        case first
        case second
        case finish

        mutating func increment() {
            switch self {
            case .first:
                self = .second

            case .second:
                self = .finish

            case .finish:
                self = .finish
            }
        }

        mutating func decrement() {
            switch self {
            case .first:
                self = .first

            case .second:
                self = .first

            case .finish:
                self = .second
            }
        }
    }

    @Binding var isPresented: Bool
    @State private var page: Tab = .first

    var body: some View {
        VStack {
            TabView(selection: $page) {
                switch page {
                case .first:
                    VStack {
                        Text("Welcome to \(Config.appName)!")

                        Spacer()

                        NavigationButtonStack(page: $page, isPresented: .constant(true))
                    }

                case .second:
                    VStack {
                        Text("Track your puzzles!")

                        Spacer()

                        NavigationButtonStack(page: $page, isPresented: .constant(true))
                    }

                case .finish:
                    VStack {
                        Text("Thank you!")

                        Spacer()

                        NavigationButtonStack(page: $page, isPresented: $isPresented)
                    }
                    .task {
                        UserDefaults.standard.setValue(true, forKey: "PuzzlePal_Onboarding_Complete")
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
}

fileprivate struct NavigationButtonStack: View {
    @Binding var page: OnboardingView.Tab
    @Binding var isPresented: Bool

    var body: some View {
        switch page {
        case .first:
            HStack {
                Button {
                    page = .finish
                } label: {
                    Text("Skip")
                }

                Spacer()

                Button {
                    page.increment()
                } label: {
                    Text("Next")
                }
            }
            .padding(.horizontal)

        case .second:
            HStack {
                Button {
                    page.decrement()
                } label: {
                    Text("Back")
                }

                Spacer()

                Button {
                    page.increment()
                } label: {
                    Text("Next")
                }
            }
            .padding(.horizontal)

        case .finish:
            HStack {
                Button {
                    page.decrement()
                } label: {
                    Text("Back")
                }

                Spacer()

                Button {
                    isPresented.toggle()
                } label: {
                    Text("Finish")
                }
            }
            .padding(.horizontal)
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isPresented: .constant(true))
    }
}
