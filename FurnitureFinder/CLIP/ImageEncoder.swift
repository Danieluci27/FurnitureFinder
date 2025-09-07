//
//  ImageEncoder.swift
//  FurnitureFinder
//
//  Created by Daniel Shin on 8/11/25.
//

import Foundation
import CoreML
import UIKit

public struct ImgEncoder {
    var model: MLModel
    
    init(configuration config: MLModelConfiguration = .init()
    ) throws {
        let urls = Bundle.main.urls(forResourcesWithExtension: "mlmodelc", subdirectory: nil) ?? []
        print("Found models in bundle:", urls.map(\.lastPathComponent))
        
        guard let url = Bundle.main.url(forResource: "ImageEncoder_mobileCLIP_s2", withExtension: "mlmodelc") else {
            fatalError("Model not found in bundle")
        }
        let imgEncoderModel = try! MLModel(contentsOf: url, configuration: config)
        self.model = imgEncoderModel
    }
    
    public func computeImgEmbedding(img: UIImage) throws -> MLShapedArray<Float32> {
        let imgEmbedding = try self.encode(image: img)
        return imgEmbedding
    }
    
    let queue = DispatchQueue(label: "imgencoder.predict")
    
    private func encode(image: UIImage) throws -> MLShapedArray<Float32> {
        do {
            guard let resizedImage = image.resize(size:CGSize(width: 256, height: 256)) else {
                throw ImageEncodingError.resizeError
            }
            
            guard let buffer = resizedImage.toCVPixelBuffer() else {
                throw ImageEncodingError.bufferConversionError
            }
            
            guard let inputFeatures = try? MLDictionaryFeatureProvider(dictionary: ["colorImage": buffer]) else {
                throw ImageEncodingError.featureProviderError
            }
            
            let result = try queue.sync { try model.prediction(from: inputFeatures) }
            guard let embeddingFeature = result.featureValue(for: "embOutput"),
                  let multiArray = embeddingFeature.multiArrayValue else {
                throw ImageEncodingError.predictionError
            }
            
            return MLShapedArray<Float32>(converting: multiArray)
        } catch {
            print("Error in encoding: \(error)")
            throw error
        }
    }
}

enum ImageEncodingError: Error {
    case resizeError
    case bufferConversionError
    case featureProviderError
    case predictionError
}
