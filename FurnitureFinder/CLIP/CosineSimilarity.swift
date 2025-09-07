//
//  SearchModel.swift
//  FurnitureFinder
//
//  Created by Daniel Shin on 8/17/25.
//

import Foundation
import CoreML
import Accelerate


func cosine_similarity(A: MLShapedArray<Float32>, B: MLShapedArray<Float32>) -> Float {
    let magnitude = vDSP.sumOfSquares(A.scalars).squareRoot() * vDSP.sumOfSquares(B.scalars).squareRoot()
    let dotarray = vDSP.dot(A.scalars, B.scalars)
    return  dotarray / magnitude
}

