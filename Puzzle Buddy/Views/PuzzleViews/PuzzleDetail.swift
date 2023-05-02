//
//  PuzzleDetail.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/31/22.
//

import FirebaseFirestore
import SwiftUI

struct PuzzleDetail: View {
    @ObservedObject var ps: PuzzleStore
    @State private var isEditable = false
    @Binding var puzzle: Puzzle

    var body: some View {
        VStack {
            if isEditable {
                // making a new copy of the puzzle here ???
                // this is why cell is not updating right away
                PuzzleFormInternal(formVm: .init(puzzle: puzzle))
            } else {
                ScrollView {
                    DetailView(puzzle: $puzzle)
                }
            }
        }
        .animation(.easeInOut, value: isEditable)
        .navigationTitle("\(puzzle.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    guard isEditable else {
                        isEditable.toggle()
                        return
                    }

                    // Save Pressed
                    //Attempt to save to database
                    ps.update(puzzle: puzzle)

                    // Then Switch back if successful
                    isEditable.toggle()

                } label: {
                    Text("\(isEditable ? "Save" : "Edit")")
                }
            }
        }
    }
}

// MARK: - DetailView
struct DetailView: View {
    @Binding var puzzle: Puzzle

    var body: some View {
        VStack {
            GroupBox {
                if let image = puzzle.image {
                    Image(uiImage: image)
                        .resizable()
                        .foregroundColor(Color.accentColor)
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: 130, alignment: .center)
                        .padding()
                } else {
                    Image(systemName: "puzzlepiece.extension.fill")
                        .resizable()
                        .foregroundColor(Color.accentColor)
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: 130, alignment: .center)
                        .padding()
                }

                Text("\(puzzle.name)")
                    .bold()
                    .font(.body)

                if puzzle.rating != .none {
                    GroupBox {
                        RatingsView(rating: Binding(get: {
                            puzzle.rating
                        }, set: { new in
                            puzzle.rating = new
                        }))
                    }
                    .padding()
                }

                if puzzle.difficulty != .none {
                    Text("Difficulty: \(puzzle.difficulty.rawValue)")
                        .font(.subheadline)
                }
            }
            .clipShape(Capsule())
            .padding(.horizontal)

            GroupBox {
                VStack {
                    HStack(spacing: 0) {
                        Text("Status: ")
                            .font(.subheadline)

                        Spacer()

                        Text("\(puzzle.status.rawValue)")
                            .font(.subheadline)
                            .bold()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    HStack(spacing: 0) {
                        Text("Brand: ")
                            .font(.subheadline)

                        Spacer()

                        Text("IamABrand.inc")
                            .font(.subheadline)
                            .bold()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    HStack(spacing: 0) {
                        Text("Completed: ")
                            .font(.subheadline)

                        Spacer()

                        Text(puzzle.completionDate, style: .date)
                            .font(.subheadline)
                            .bold()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    if let name =  puzzle.estimatedTimeSpent.toName() {
                        HStack(spacing: 0) {
                            Text("Time Spent: ")
                                .font(.subheadline)

                            Spacer()

                            Text(name)
                                .font(.subheadline)
                                .bold()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    }

                    if let pieces = puzzle.pieces {
                        HStack(spacing: 0) {
                            Text("Pieces: ")
                                .font(.subheadline)

                            Spacer()

                            Text("\(pieces)")
                                .font(.subheadline)
                                .bold()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                        if let minutes = puzzle.estimatedTimeSpent.toMin() {
                            HStack(spacing: 0) {
                                Text("Pieces per min (ppm):")
                                    .font(.subheadline)

                                Spacer()

                                Text("\(pieces / minutes)")
                                    .font(.subheadline)
                                    .bold()

                                Text(" (ppm)")
                                    .font(.subheadline)
                                    .bold()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

//// MARK: - Previews
//struct PuzzleDetail_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            PuzzleDetail(ps: .init(), puzzle: .constant(.fixture()))
//        }
//    }
//}
