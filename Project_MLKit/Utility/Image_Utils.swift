//
//  Image_Utils.swift
//  Project_MLKit
//
//  Created by iOS Development on 6/21/18.
//  Copyright © 2018 Genisys. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation


func pixelValues(fromCGImage imageRef: CGImage?) -> [UInt8]?
{
    var width = 0
    var height = 0
    var pixelValues: [UInt8]?
    
    if let imageRef = imageRef {
        width = imageRef.width
        height = imageRef.height
        let bitsPerComponent = imageRef.bitsPerComponent
        let bytesPerRow = imageRef.bytesPerRow
        let totalBytes = height * bytesPerRow
        let bitmapInfo = imageRef.bitmapInfo
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var intensities = [UInt8](repeating: 0, count: totalBytes)
        
        let contextRef = CGContext(data: &intensities,
                                   width: width,
                                   height: height,
                                   bitsPerComponent: bitsPerComponent,
                                   bytesPerRow: bytesPerRow,
                                   space: colorSpace,
                                   bitmapInfo: bitmapInfo.rawValue)
        contextRef?.draw(imageRef, in: CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height)))
        
        pixelValues = intensities
    }
    
    return pixelValues
}

func compareImages(image1: UIImage, image2: UIImage) -> Double? {
    guard let data1 = pixelValues(fromCGImage: image1.cgImage),
        let data2 = pixelValues(fromCGImage: image2.cgImage),
        data1.count == data2.count else {
            return nil
    }
    
    let width = Double(image1.size.width)
    let height = Double(image1.size.height)
    let _zip = zip(data1, data2).enumerated()
    return _zip.reduce(0.0) {
            $1.offset % 4 == 3 ? $0 : $0 + abs(Double($1.element.0) - Double($1.element.1))
        } * 100 / (width * height * 3.0) / 255.0
    
}



func convertToUImage(from CIImage:CIImage) -> UIImage{
    let context:CIContext = CIContext.init(options: nil)
    let cgImage:CGImage = context.createCGImage(CIImage, from: CIImage.extent)!
    let image:UIImage = UIImage.init(cgImage: cgImage)
    return image
}


func imageFromSampleBuffer(sampleBuffer : CMSampleBuffer) -> UIImage{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    
    let  imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer!, CVPixelBufferLockFlags.readOnly);
    
    
    // Get the number of bytes per row for the pixel buffer
    let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer!);
    
    // Get the number of bytes per row for the pixel buffer
    let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer!);
    // Get the pixel buffer width and height
    let width = CVPixelBufferGetWidth(imageBuffer!);
    let height = CVPixelBufferGetHeight(imageBuffer!);
    
    // Create a device-dependent RGB color space
    let colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue
    bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
    //let bitmapInfo: UInt32 = CGBitmapInfo.alphaInfoMask.rawValue
    let context = CGContext.init(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
    // Create a Quartz image from the pixel data in the bitmap graphics context
    let quartzImage = context?.makeImage();
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer!, CVPixelBufferLockFlags.readOnly);
    
    // Create an image object from the Quartz image
    let image = UIImage.init(cgImage: quartzImage!);
    
    return (image);
}
