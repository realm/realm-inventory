////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////


// Some methods (PDF resizing) based on work orignally implemented in Objective-C by Erica Sadun

import UIKit
import Foundation

extension UIImage {
    
    func AspectScaleFit( sourceSize : CGSize,  destRect : CGRect) -> CGFloat  {
        let destSize = destRect.size
        let  scaleW = destSize.width / sourceSize.width
        let scaleH = destSize.height / sourceSize.height
        return fmin(scaleW, scaleH)
    }
    
    
    func RectAroundCenter(center : CGPoint, size : CGSize) -> CGRect  {
        let halfWidth = size.width / 2.0
        let halfHeight = size.height / 2.0
        
        return CGRect(x: center.x - halfWidth, y: center.y - halfHeight, width: size.width, height: size.height) //was: CGRectMake(center.x - halfWidth, center.y - halfHeight, size.width, size.height)
    }
    
    
    func  RectByFittingRect(sourceRect : CGRect, destinationRect : CGRect) -> CGRect {
        let aspect = AspectScaleFit(sourceSize: sourceRect.size, destRect: destinationRect)
        let targetSize = CGSize(width: sourceRect.size.width * aspect, height: sourceRect.size.height * aspect)  // was: CGSizeMake(sourceRect.size.width * aspect, sourceRect.size.height * aspect)
        let center =  CGPoint(x: destinationRect.midX, y: destinationRect.midY)      // was: CGPointMake(destinationRect.midX, destinationRect.midY)
        return RectAroundCenter(center: center, size: targetSize)
    }
    
    func DrawPDFPageInRect(pageRef : CGPDFPage,  destinationRect : CGRect) {
        let context = UIGraphicsGetCurrentContext()
        if context == nil  {
            NSLog("Error: No context to draw to")
            return
        }
        
        context!.saveGState()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        // Flip the context to Quartz space
        var transform = CGAffineTransform.identity
        transform = transform.scaledBy(x: 1.0, y: -1.0)
        transform = transform.translatedBy(x: 0.0, y: -image!.size.height)
        context!.concatenate(transform);
        
        // Flip the rect, which remains in UIKit space
        let d = destinationRect.applying(transform)
        
        // Calculate a rectangle to draw to
        let pageRect = pageRef.getBoxRect(CGPDFBox.cropBox)
        let drawingAspect = AspectScaleFit(sourceSize: pageRect.size, destRect: d)
        let drawingRect = RectByFittingRect(sourceRect: pageRect, destinationRect: d)
        
        // Adjust the context
        context!.translateBy(x: drawingRect.origin.x, y: drawingRect.origin.y)
        context!.scaleBy(x: drawingAspect, y: drawingAspect)
        
        // Draw the page
        context!.drawPDFPage(pageRef)
        context!.restoreGState()
    }
    
    
    func ImageFromPDFFile(pdfPath : NSString, targetSize : CGSize ) -> UIImage?
    {
        let filePath = NSURL(fileURLWithPath:pdfPath as String)
        let pdfRef = CGPDFDocument(filePath)
        if pdfRef == nil {
            NSLog("Error loading PDF")
            return nil
        }
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0)
        let pageRef = pdfRef!.page(at: 1)!
        let targetRect = CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)      // was CGRectMake(0, 0, targetSize.width, targetSize.height)
        DrawPDFPageInRect(pageRef: pageRef, destinationRect: targetRect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    
    func GetPDFFileAspect(pdfPath : NSString) -> CGFloat {
        let filePath = NSURL(fileURLWithPath:pdfPath as String)
        
        let pdfRef = CGPDFDocument(filePath)
        if pdfRef == nil  {
            NSLog("Error loading PDF")
            return 0.0
        }
        
        let pageRef = pdfRef!.page(at: 1)
        let pageRect = pageRef!.getBoxRect(CGPDFBox.cropBox)
        return pageRect.size.width / pageRect.size.height
    }
    
    
    
    func ImageFromPDFFileWithWidth(pdfPath : NSString, targetWidth : CGFloat) -> UIImage? {
        let aspect = GetPDFFileAspect(pdfPath: pdfPath)
        if aspect == 0.0 {
            return nil
        }
        return ImageFromPDFFile(pdfPath: pdfPath, targetSize:CGSize(width:targetWidth, height: targetWidth / aspect))       // was: CGSizeMake(targetWidth, targetWidth / aspect))
    }
    
    
    func ImageFromPDFFileWithHeight(pdfPath : NSString, targetHeight : CGFloat) -> UIImage? {
        let aspect = GetPDFFileAspect(pdfPath: pdfPath)
        if aspect == 0.0 {
            return nil
        }
        return ImageFromPDFFile(pdfPath: pdfPath, targetSize: CGSize(width:targetHeight * aspect, height:targetHeight ))    // was:CGSizeMake(targetHeight * aspect, targetHeight))
    }
    
    
    
    func imageWithTint(tintColor : UIColor) -> UIImage? {
        // Begin drawing
        let aRect = CGRect(x:0.0, y: 0.0, width: self.size.width, height: self.size.height)// wasCGRectMake(0.0, 0.0, self.size.width, self.size.height)
        
        // Compute mask flipping image
        UIGraphicsBeginImageContextWithOptions( aRect.size, false/*opaque?*/, self.scale)
        let c0 = UIGraphicsGetCurrentContext()
        
        // draw image
        c0!.translateBy(x: 0, y: aRect.size.height)
        c0!.scaleBy(x: 1.0, y: -1.0)
        self.draw(in: aRect)
        
        let alphaMask = c0!.makeImage()
        UIGraphicsEndImageContext()
        UIGraphicsBeginImageContextWithOptions( aRect.size, false/*opaque?*/, self.scale)
        
        // Get the graphic context
        let c = UIGraphicsGetCurrentContext()
        
        // Draw the image
        self.draw(in: aRect)
        
        // Mask
        c!.clip(to: aRect, mask: alphaMask!)
        
        // Set the fill color space
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        c!.setFillColorSpace(colorSpace)
        
        // Set the fill color
        c!.setFillColor(tintColor.cgColor)
        UIRectFillUsingBlendMode(aRect, CGBlendMode.normal)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        
        return img;
    }
    
    // Makes a colorized copy of this image
    // Colorization rules:
    //    Alpha is preserved
    //    White & Black source pixels are preserved (!)
    //    in-between colors are blended with the given tintColor (50% gray = 100% tint color)
    func hollowImageWithTint(tintColor : UIColor) -> UIImage? {
        // Begin drawing
        let aRect = CGRect(x: 0.0, y: 0.0, width: self.size.width, height: self.size.height);        // CGRectMake(0.0, 0.0, self.size.width, self.size.height);
        
        // Compute mask flipping image
        UIGraphicsBeginImageContextWithOptions( aRect.size, false/*opaque?*/, self.scale)
        let c0 = UIGraphicsGetCurrentContext()
        
        // draw image
        c0!.translateBy(x: 0, y: aRect.size.height)
        c0!.scaleBy(x: 1.0, y: -1.0)
        
        
        
        //--------------
        // draw black background to preserve color of transparent pixels
        c0!.setBlendMode(CGBlendMode.normal)
        UIColor.black.setFill()
        c0!.fill(aRect)
        
        // draw original image
        c0!.setBlendMode(CGBlendMode.normal)
        c0!.draw(self.cgImage!, in: aRect)      // was: CGContextDrawImage(c0!, aRect, self.cgImage!)
        
        // tint image (loosing alpha) - the luminosity of the original image is preserved
        c0!.setBlendMode(CGBlendMode.color)
        tintColor.setFill()
        c0!.fill(aRect)
        
        // mask by alpha values of original image
        c0!.setBlendMode(CGBlendMode.destinationIn)
        c0!.draw(self.cgImage!, in: aRect)      // was:  CGContextDrawImage(c0!, aRect, self.cgImage!)
        //---------
        
        
        
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        
        return img;
    }
    
    
    
    func scaleToSize(size:CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        self.draw(in: CGRect(x:0, y:0, width:size.width, height:size.height)) // Draw the scaled image in the current context
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext() // Create a new image from current context
        UIGraphicsEndImageContext() // Pop the current context from the stack
        return scaledImage;         // Return our new scaled image
    }
    
    
    
    // returns a an image sized to fit within a rectangle of the given size (preserving aspect ratio)
    // as a side-benefit, any exif orientation is flattened & applied
    func normalizedImageWithMaxiumSize( maximumSize : CGFloat) -> UIImage  {
        // how big should the dest image be?
        let srcSize = self.size
        var destSize : CGSize
        // don't scale the src image up, either!
        
        if srcSize.height > srcSize.width {
            // portrait
            
            // don't *enlarge* the source image
            var maxHeight = maximumSize
            if maxHeight > srcSize.height {
                maxHeight = srcSize.height
            }
            
            destSize = CGSize(width: maxHeight *  srcSize.width / srcSize.height, height: maxHeight )
        } else {
            // landscape orientation (width constrained)
            
            // don't *enlarge* the source image
            var maxWidth = maximumSize
            if maxWidth > srcSize.width {
                maxWidth = srcSize.width
            }
            
            destSize = CGSize(width: maxWidth, height: maxWidth * srcSize.height/srcSize.width )
        }
        
        // draw into the destination image
        UIGraphicsBeginImageContextWithOptions( destSize, true/*opaque?*/, self.scale)
        //let gc = UIGraphicsGetCurrentContext()
        self.draw(in: CGRect(x: 0, y: 0, width: destSize.width, height: destSize.height))
        
        // get the dest image out
        let destImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        return destImage!
    }
    
    func resizeImage(targetSize: CGSize) -> UIImage {
        let size = self.size
        
        let widthRatio  = targetSize.width  / self.size.width
        let heightRatio = targetSize.height / self.size.height
        
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width:size.width * heightRatio, height:size.height * heightRatio)
        } else {
            newSize = CGSize(width:size.width * widthRatio,  height:size.height * widthRatio)
        }
        
        let rect = CGRect(x:0, y:0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
