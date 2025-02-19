//
// Copyright © 2020 Bunny Wong
// Created on 2020/2/23.
//

import UIKit
import CoreVideo
import Accelerate

class HackerEffectProcessor: AsciiEffectsProcessor {

    var charactersPerRow = 80

    var characterAspectRatio = CGFloat(FontResourceProvider.FiraCode.characterAspectRatio)

    var fontSize: CGFloat = 14.0

    var font: UIFont {
        return UIFont(name: FontResourceProvider.FiraCode.bold.rawValue, size: fontSize)!
    }

    var lineHeight: CGFloat {
        return fontSize
    }

    func processYCbCrBuffer(lumaBuffer: inout vImage_Buffer, chromaBuffer: inout vImage_Buffer) -> vImage_Error {
        return kvImageNoError
    }

    func processArgbBufferToAsciiArt(buffer sourceBuffer: inout vImage_Buffer) -> UIImage? {
        var grayscaledBuffer = vImage_Buffer()
        guard vImageBuffer_Init(&grayscaledBuffer, sourceBuffer.height, sourceBuffer.width, 8, vImage_Flags(kvImageNoFlags)) == kvImageNoError else {
            return nil
        }
        defer {
            free(grayscaledBuffer.data)
        }

        let coefficient = 1.0 / 3.0
        let divisor: Int32 = 0x1000
        let dDivisor = Double(divisor)
        var coefficientsMatrix = [
            Int16(coefficient * dDivisor),
            Int16(coefficient * dDivisor),
            Int16(coefficient * dDivisor),
            1
        ]

        // Apply a grayscale conversion
        guard vImageMatrixMultiply_ARGB8888ToPlanar8(&sourceBuffer,
                &grayscaledBuffer,
                &coefficientsMatrix,
                divisor,
                nil,
                0,
                vImage_Flags(kvImageNoFlags)) == kvImageNoError else {
            return nil
        }

        // Apply a histogram equalization
        guard vImageEqualization_Planar8(&grayscaledBuffer, &grayscaledBuffer, vImage_Flags(kvImageNoFlags)) == kvImageNoError else {
            return nil
        }

        let rowCount: Int = calculateRowCount(imageAspectRatio: CGFloat(sourceBuffer.width) / CGFloat(sourceBuffer.height))

        var scaledBuffer = vImage_Buffer()
        guard vImageBuffer_Init(&scaledBuffer, UInt(rowCount), UInt(charactersPerRow), 8, vImage_Flags(kvImageNoFlags)) == kvImageNoError else {
            return nil
        }
        defer {
            free(scaledBuffer.data)
        }

        guard vImageScale_Planar8(&grayscaledBuffer, &scaledBuffer, nil, vImage_Flags(kvImageNoFlags)) == kvImageNoError else {
            return nil
        }

        let dataPointer: UnsafeMutablePointer<UInt8> =
                scaledBuffer.data.bindMemory(to: UInt8.self, capacity: scaledBuffer.rowBytes * Int(scaledBuffer.height))

        let randomStringTemplate = "01"
        var asciiResult = ""
        for _ in 0..<rowCount {
            asciiResult.append(String((0..<charactersPerRow).map { _ in
                randomStringTemplate.randomElement()!
            }))
            asciiResult.append("\n")
        }

        let attributedResult = NSMutableAttributedString(string: asciiResult)
        for y in 0..<rowCount {
            for x in 0..<charactersPerRow {
                // Calculates brightness value
                let pixelBrightness = dataPointer[y * scaledBuffer.rowBytes + x]
                let relativeBrightness = Double(pixelBrightness) / 255.0
                attributedResult.addAttribute(NSAttributedString.Key.foregroundColor,
                        value: UIColor.green.withAlphaComponent(CGFloat(relativeBrightness)),
                        range: NSRange(location: (charactersPerRow + 1) * y + x, length: 1))
            }
        }

        return AsciiArtRendererInternal.renderAsciiArt(
                attributedString: attributedResult,
                font: font,
                lineHeight: lineHeight,
                background: UIColor.black,
                charactersPerRow: charactersPerRow,
                rows: rowCount,
                characterAspectRatio: characterAspectRatio)
    }

}
