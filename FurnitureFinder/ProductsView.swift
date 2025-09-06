//
//  ResultsView.swift
//  FurnitureFinder
//
//  Created by Daniel Shin on 7/25/25.
//

import SwiftUI
import UIKit

struct CaptionResponse: Decodable {
    struct Result: Decodable {
        let filename: String
        let caption: String
    }
    let results: [Result]
}

struct SearchItem: Identifiable, Codable {
    let id = UUID()
    let title: String
    let link: String
    let thumbnail: String
    
    // only decode title/link/thumbnail from your JSON
    private enum CodingKeys: String, CodingKey {
        case title, link, thumbnail
    }
}

struct ProductsView: View {
    let items: [SearchItem]
    let dismiss: () -> Void
    
    var body: some View {
        NavigationView {
            List(items) { item in
                HStack(alignment: .top, spacing: 12) {
                    // iOS 15+ AsyncImage
                    AsyncImage(url: URL(string: item.thumbnail)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 60, height: 60)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .cornerRadius(4)
                        case .failure:
                            Color.gray
                                .frame(width: 60, height: 60)
                        @unknown default: EmptyView()
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.headline)
                        // tappable link
                        if let url = URL(string: item.link) {
                            Link("View on Amazon", destination: url)
                                .font(.subheadline)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("Products")
            .navigationBarItems(trailing:
                                    Button("Done") { dismiss() }
            )
        }
    }
}
