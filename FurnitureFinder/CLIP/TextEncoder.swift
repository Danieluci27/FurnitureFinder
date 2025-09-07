//
//  TextEncoder.swift
//  FurnitureFinder
//
//  Created by Daniel Shin on 8/11/25.
//

import Foundation
import CoreML
import UIKit

enum TextEncoderError : Error {
    case computeTextEncodingError
}


///  A model for encoding text
public struct TextEncoder {

    var tokenizer: Tokenizer
    var model: MLModel
    
    public init(
         configuration config: MLModelConfiguration = .init()
    ) throws {
        guard let modelURL = Bundle.main.url(forResource: "TextEncoder_mobileCLIP_s2", withExtension: "mlmodelc") else {
            fatalError("Model not found in bundle")
        }
        guard let vocabURL = Bundle.main.url(forResource: "vocab", withExtension: "json") else {
            fatalError("Vocab not found in bundle")
        }
        guard let mergesURL = Bundle.main.url(forResource: "merges", withExtension: "txt") else {
            fatalError("Merges not found in bundle")
        }
        // Text tokenizer and encoder
        let tokenizer = try Tokenizer(mergesAt: mergesURL, vocabularyAt: vocabURL)
        let textEncoderModel = try! MLModel(contentsOf: modelURL, configuration: config)
        
        self.tokenizer = tokenizer
        self.model = textEncoderModel
    }
    
    public func computeTextEmbedding(prompt: String) throws -> MLShapedArray<Float32> {
        let promptEmbedding = try self.encode(prompt)
        return promptEmbedding
    }
    
    private func encode(_ text: String) throws -> MLShapedArray<Float32> {

        // Get models expected input length
        let inputLength = inputShape.last!

        // Tokenize, padding to the expected length
        var (tokens, ids) = tokenizer.tokenize(input: text, minCount: inputLength)

        // Truncate if necessary
        if ids.count > inputLength {
            tokens = tokens.dropLast(tokens.count - inputLength)
            ids = ids.dropLast(ids.count - inputLength)
            let truncated = tokenizer.decode(tokens: tokens)
            print("Needed to truncate input '\(text)' to '\(truncated)'")
        }

        // Use the model to generate the embedding
        return try encode(ids: ids)
    }

    /// Prediction queue
    let queue = DispatchQueue(label: "textencoder.predict")

    func encode(ids: [Int]) throws -> MLShapedArray<Float32> {
        let inputName = inputDescription.name
        let inputShape = inputShape

        let floatIds = ids.map { Float32($0) }
        let inputArray = MLShapedArray<Float32>(scalars: floatIds, shape: inputShape)
        let inputFeatures = try! MLDictionaryFeatureProvider(
            dictionary: [inputName: MLMultiArray(inputArray)])

        let result = try queue.sync { try model.prediction(from: inputFeatures) }
        let embeddingFeature = result.featureValue(for: "text_embeddings")
        return MLShapedArray<Float32>(converting: embeddingFeature!.multiArrayValue!)
    }

    var inputDescription: MLFeatureDescription {
        model.modelDescription.inputDescriptionsByName.first!.value
    }

    var inputShape: [Int] {
        inputDescription.multiArrayConstraint!.shape.map { $0.intValue }
    }

}
