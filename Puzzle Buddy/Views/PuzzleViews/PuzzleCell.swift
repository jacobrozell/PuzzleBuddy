//
//  PuzzleCell.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/31/22.
//

import SwiftUI

// MARK: - PuzzleCell
struct PuzzleCell: View {
    @ObservedObject var ps: PuzzleStore
    @Binding var puzzle: Puzzle

    var body: some View {
        NavigationLink {
            PuzzleDetail(ps: ps, puzzle: $puzzle)
        } label: {
            PuzzleCellView(puzzle: $puzzle)
                .padding(4)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: PuzzleCellView
private struct PuzzleCellView: View {
    @State private var expanded: Bool = false
    @Binding var puzzle: Puzzle

    var body: some View {
        VStack(alignment: .center) {
            VStack {
                HStack {
                    if let image = puzzle.image {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: 75, height: 75, alignment: .center)
                            .aspectRatio(contentMode: .fill)
                            .clipShape(Circle())
                    }

                    Text(puzzle.name)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.leading)

                    Spacer()
                    
                    if puzzle.rating != .none {
                        GroupBox {
                            RatingsView(rating: Binding(get: {
                                puzzle.rating
                            }, set: { new in
                                puzzle.rating = new
                            }))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
            .padding(.vertical)

            Group {
                if expanded {
                    GroupBox {
                        VStack {
                            if let pieces = puzzle.pieces {
                                HStack {
                                    Text("Total Pieces:")
                                        .bold()
                                    
                                    Spacer()
                                    
                                    Text("\(pieces)")
                                }
                            }
                            
                            if let time = puzzle.estimatedTimeSpent {
                                HStack {
                                    Text("Time Spent:")
                                        .bold()
                                    
                                    Spacer()
                                    
                                    Text(time.toName())
                                }
                            }
                            
                            HStack {
                                Text("Completed:")
                                    .bold()
                                
                                Spacer()
                                
                                Text(puzzle.completionDate, style: .date)
                                    .lineLimit(0)
                            }
                            
                            HStack {
                                Text("Difficulty:")
                                    .bold()
                                
                                Spacer()
                                
                                Text(puzzle.difficulty == .none ? "N/A" : puzzle.difficulty.rawValue)
                                    .lineLimit(0)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding()
                }
            }
            .animation(.easeInOut, value: expanded)
        }
        .overlay(alignment: .bottomTrailing) {
            Text(expanded ? "↑" : "↓")
                .foregroundColor(.white)
                .animation(.spring(), value: expanded)
                .onTapGesture {
                    expanded.toggle()
                }
                .padding(4)
                .background(Color.accentColor)
                .clipShape(Circle())
        }
    }
}

// MARK: - Previews
struct PuzzleCellPreview: PreviewProvider {
    static var previews: some View {
        VStack {
            PuzzleCell(ps: .init(), puzzle: .constant(.fixture()))
            PuzzleCell(ps: .init(), puzzle: .constant(.fixture()))
        }
    }
}
