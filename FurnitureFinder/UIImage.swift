//
//  UIImage.swift
//  FurnitureFinder
//
//  Created by Daniel Shin on 7/25/25.
//

import Foundation
import PhotosUI

extension UIImage {
    func toCVPixelBuffer() -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let width = Int(size.width)
        let height = Int(size.height)
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         kCVPixelFormatType_32ARGB,
                                         attrs,
                                         &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        let pxData = CVPixelBufferGetBaseAddress(buffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pxData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                      space: rgbColorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
            return nil
        }
        context.draw(cgImage!, in: CGRect(x: 0, y: 0, width: width, height: height))
        CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
        return buffer
    }
    
    func resize(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: CGPoint.zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return resizedImage
    }
    //
    func alpha(at point: CGPoint, in displaySize: CGSize) -> CGFloat {
      guard let cg = cgImage else { return 0 }
      // map point to pixel space
      let x = Int((point.x / displaySize.width ) * CGFloat(cg.width ))
      let y = Int((point.y / displaySize.height) * CGFloat(cg.height))
      guard
        x >= 0, x < cg.width,
        y >= 0, y < cg.height,
        let data = cg.dataProvider?.data,
        let ptr = CFDataGetBytePtr(data)
      else { return 0 }

      let bytesPerRow   = cg.bytesPerRow
      let bytesPerPixel = cg.bitsPerPixel / 8
      let offset        = y * bytesPerRow + x * bytesPerPixel
      let alphaByte     = ptr[offset + (bytesPerPixel - 1)]
      return CGFloat(alphaByte) / 255.0
    }
}
