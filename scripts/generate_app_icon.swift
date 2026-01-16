#!/usr/bin/env swift

import Foundation
import AppKit
import CoreGraphics

// Create a 1024x1024 app icon with Re:Meet branding
let size = 1024

// Create bitmap context directly to control exact pixel dimensions
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    print("Failed to create graphics context")
    exit(1)
}

// Define gradient colors (purple theme)
let colors = [
    CGColor(red: 108/255, green: 92/255, blue: 231/255, alpha: 1.0),   // #6C5CE7
    CGColor(red: 162/255, green: 155/255, blue: 254/255, alpha: 1.0)   // #A29BFE
] as CFArray

let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0])!

// Draw gradient from top-left to bottom-right
context.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: CGFloat(size)),
    end: CGPoint(x: CGFloat(size), y: 0),
    options: []
)

// Draw "R" letter in white
let fontSize: CGFloat = 600
let font = CTFontCreateWithName("Helvetica-Bold" as CFString, fontSize, nil)

let attributes: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: CGColor(red: 1, green: 1, blue: 1, alpha: 1)
]

let text = "R"
let attributedString = NSAttributedString(string: text, attributes: attributes)
let line = CTLineCreateWithAttributedString(attributedString)
let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)

// Center the text
let x = (CGFloat(size) - bounds.width) / 2 - bounds.origin.x
let y = (CGFloat(size) - bounds.height) / 2 - bounds.origin.y

context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
context.textPosition = CGPoint(x: x, y: y)
CTLineDraw(line, context)

// Get the image
guard let cgImage = context.makeImage() else {
    print("Failed to create image")
    exit(1)
}

// Save as PNG
let outputPath = FileManager.default.currentDirectoryPath + "/ios/ReMeet/ReMeet/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
let url = URL(fileURLWithPath: outputPath)

guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypePNG, 1, nil) else {
    print("Failed to create image destination")
    exit(1)
}

CGImageDestinationAddImage(destination, cgImage, nil)

if CGImageDestinationFinalize(destination) {
    print("App icon generated successfully at: \(outputPath)")
} else {
    print("Failed to save image")
    exit(1)
}
