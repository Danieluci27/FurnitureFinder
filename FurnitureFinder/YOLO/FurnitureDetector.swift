//
//  FurnitureDetector.swift
//  FurnitureFinder
//
//  Created by Daniel Shin on 9/5/25.
//

import CoreML
import CoreImage
import SwiftUI

enum DetectionError: Error {
    case PredictionError
    case InvalidPredictionResultError
}

struct Detection {
    var cls: Int
    var rect: CGRect
}

let CONFIDENCE_THRESHOLD: Double = 0.7
let IOU_THRESHOLD: Double = 0.6
let NUM_CLASS: Int = 80
let INPUT_SIZE: CGSize = CGSize(width: 416, height: 416)

class FurnitureDetector: ObservableObject {
    var model: YOLOv3Int8LUT
    var detectionResults: YOLOv3Int8LUTOutput?
    
    init (configuration config: MLModelConfiguration = .init())
    throws {
        self.model = try YOLOv3Int8LUT(configuration: config)
        print("Model ready.")
    }
    
    func predict(img: UIImage) throws {
        guard
            let inputImg = img.resize(size: INPUT_SIZE),
            let buf    = inputImg.toCVPixelBuffer(),
            let yolo   = try? YOLOv3Int8LUT(configuration: .init()),
            let result = try? yolo.prediction(image: buf,
                                              iouThreshold: IOU_THRESHOLD,
                                              confidenceThreshold: CONFIDENCE_THRESHOLD) else {
            throw DetectionError.PredictionError
        }
        self.detectionResults = result
    }
    
    func processDetectionResults() throws -> [Detection] {
        guard let result = self.detectionResults else {
            throw DetectionError.InvalidPredictionResultError
        }
        let coords = result.coordinates
        let confs = result.confidence
        let detsFromCoords = coords.shape.count > 0 ? coords.shape[0].intValue : 0
        let detsFromConfs  = confs.shape.count > 0 ? confs.shape[0].intValue : 0
        let numDetections  = max(0, min(detsFromCoords, detsFromConfs))
        let numClasses     = confs.shape.count > 1 ? confs.shape[1].intValue : NUM_CLASS
        var detections: [Detection] = []
        for det in 0..<numDetections {
            let best = (0..<numClasses).reduce((cls: -1, conf: Float(CONFIDENCE_THRESHOLD))) { acc, cls in
                print("Detection: ", det)
                print("cls: ", cls)
                let c = confs[[det as NSNumber, cls as NSNumber]].floatValue
                return c > acc.conf ? (cls, c) : acc
            }
            if (best.cls >= 0) {
                let cx    = coords[[det as NSNumber, 0]].doubleValue
                let cy    = coords[[det as NSNumber, 1]].doubleValue
                let w     = coords[[det as NSNumber, 2]].doubleValue
                let h     = coords[[det as NSNumber, 3]].doubleValue
                let rect  = CGRect(x: cx - w/2, y: cy - h/2, width: w, height: h)
                print(best.cls)
                detections.append(Detection(cls: best.cls, rect: rect))
            }
        }
        return detections
    }
}
