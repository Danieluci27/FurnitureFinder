//
//  MaskedImageView.swift
//  FurnitureFinder
//
//  Created by Daniel Shin on 7/25/25.
//

import SwiftUI

struct MaskedImageView: View {
  let baseImage: UIImage
  let masks: [Int: UIImage]
  let maskReady: Bool
  var onMaskTap: (Int) -> Void

  var body: some View {
    GeometryReader { geo in
      ZStack {
        Image(uiImage: baseImage)
          .resizable()
          .scaledToFill()
          .frame(width: geo.size.width, height: geo.size.height)
          .clipped()
          .overlay(
            Group {
                if maskReady {
                    ForEach(masks.keys.sorted(), id: \.self) { idx in
                        if let maskImage = masks[idx] {
                            Image(uiImage: maskImage)
                               .resizable()
                               .scaledToFill()
                               .frame(width: geo.size.width, height: geo.size.height)
                               .clipped()
                               .opacity(0.3)
                        }
                    }
                }
            }
                  )
      }
      // overlay an invisible tap recognizer that gives us the point
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onEnded { value in
            let pt = value.location
            for idx in masks.keys.sorted() {
                if let mask = masks[idx] {
                    if mask.alpha(at: pt, in: geo.size) > 0.1 {
                      onMaskTap(idx)
                      break
                    }
                }
            }
          }
        //similar items -> pick only one to save API cost.
      )
    }
  }
}
