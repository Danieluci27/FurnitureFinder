//
//  response.swift
//  FurnitureFinder
//
//  Created by Daniel Shin on 7/20/25.
//

import Foundation
import UIKit

public struct Segment {
    let box: CGRect
    let score: Float
    let mask: UIImage
}

public struct _SegmentAnythingResult: Decodable {
    let box: [CGFloat]
    let score: Float
    let mask: String
}

struct AmazonSearchResponse: Decodable {
        let organicResults: [OrganicResult]
        
        enum CodingKeys: String, CodingKey {
            case organicResults = "organic_results"
        }
        struct OrganicResult: Decodable {
            let title: String
            let link: String
            let thumbnail: String
        }
}
