//
//  FurnitureFinderTests.swift
//  FurnitureFinderTests
//
//  Created by Daniel Shin on 6/23/25.
//

import XCTest
import CoreML
import Accelerate
@testable import FurnitureFinder

final class FurnitureFinderTests: XCTestCase {
    func testSegmentAnythingAPILatency() async throws {
            let testImage = UIImage(named: "sofa")!
            let testBox: [[CGFloat]] = [[0.1, 0.1, 0.5, 0.5]]

            let mask = await fetchMask(cropImage: testImage, boxArray: testBox)
            XCTAssertNotNil(mask)
    }
    
    func testYOLOPerformance() {
        let testImage = UIImage(named: "room")!
        let detector = try! FurnitureDetector()
        self.measure {
            do {
                try detector.predict(img: testImage)
                let results = (try? detector.processDetectionResults()) ?? []
                XCTAssertFalse(results.isEmpty, "No detections produced")
            } catch {
                XCTFail("YOLO prediction failed: \(error)")
            }
        }
    }
    
    func testAnalysisPerformanceTime() async throws {
        let ia = ImageAnalysis()
        guard let sampleImage = UIImage(named: "room") else {
            XCTFail("Sample image not found")
            return
        }

        self.measure {
            let expectation = XCTestExpectation(description: "analysis")
            Task {
                ia.runAnalysis(on: sampleImage)
                
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 15)
        }
    }
    
    func testAnalysisPerformance() async throws {
        let ia = ImageAnalysis()
        guard let sampleImage = UIImage(named: "room") else {
            XCTFail("Sample image not found")
            return
        }
        ia.runAnalysis(on: sampleImage)
        XCTAssertGreaterThan(ia.furnitureImages.count, 0, "No images were produced")
        XCTAssertGreaterThan(ia.furnitureCaptions.count, 0, "No images were produced")
        XCTAssertGreaterThan(ia.segmentationMasks.count, 0, "No images were produced")
    }
    
    
}
