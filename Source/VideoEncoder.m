//
//  VideoEncoder.m
//  GyGoIntegrationApp
//
//  Created by Sagi Rorlich on 02/11/2017.
//  Copyright © 2017 Visualead. All rights reserved.
//

#import "VideoEncoder.h"
#import <AVKit/AVKit.h>

@implementation VideoEncoder

+ (UIImage*)rotateUIImage:(UIImage*)image {
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,image.size.width, image.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(90 * M_PI / 180);
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    
    // Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    
    //   // Rotate the image context
    CGContextRotateCTM(bitmap, 90 * M_PI / 180);
    
    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-image.size.width / 2, -image.size.height / 2, image.size.width, image.size.height), [image CGImage]);
    
    UIImage *rotated = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return rotated;
}

+ (void)encodeFrames:(NSArray<NSString*>*)framesPaths outputPath:(NSString*)outputPath {
    
    NSError *error = nil;
    NSUInteger fps = 30;
    
    UIImage* firstFrame = [UIImage imageWithContentsOfFile:[framesPaths firstObject]];
    
    // ---------- Rotate frame ----------- //
    firstFrame = [VideoEncoder rotateUIImage:(firstFrame)];
    // ---------- Rotation ended ----------- //
    
    CGSize imageSize = CGSizeMake(CGImageGetWidth(firstFrame.CGImage),CGImageGetHeight(firstFrame.CGImage));
    imageSize.width = ((int)imageSize.width / 16) * 16;
    
    NSLog(@"-->framesPaths= %lu", (unsigned long)framesPaths.count);
//    for (NSString* path in imagePaths)
//    {
//        [imageArray addObject:[UIImage imageWithContentsOfFile:path]];
//        //NSLog(@"-->image path= %@", path);
//    }
    
    
    NSLog(@"Start building video from defined frames.");
    
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:
                                  [NSURL fileURLWithPath:outputPath] fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:imageSize.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:imageSize.height], AVVideoHeightKey,
                                   nil];
    
    AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput
                                            assetWriterInputWithMediaType:AVMediaTypeVideo
                                            outputSettings:videoSettings];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                                                     sourcePixelBufferAttributes:nil];
    
    NSParameterAssert(videoWriterInput);
    NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
    videoWriterInput.expectsMediaDataInRealTime = YES;
    [videoWriter addInput:videoWriterInput];
    
    //Start a session:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    CVPixelBufferRef buffer = NULL;
    
    //convert uiimage to CGImage.
    int frameCount = 0;
//    double numberOfSecondsPerFrame = 0.1;
//    double frameDuration = fps * numberOfSecondsPerFrame;
//    videoWriterInput.mediaTimeScale = 30000;

    //for(VideoFrame * frm in imageArray)
    NSLog(@"**************************************************");
    for(NSString* framePath in framesPaths)
    {
        UIImage* img = [UIImage imageWithContentsOfFile:framePath];
        // ---------- Rotate frame ----------- //
        img = [VideoEncoder rotateUIImage:(img)];
        // ---------- Rotation ended ----------- //
        buffer = [VideoEncoder pixelBufferFromCGImage:[img CGImage]];
        
        BOOL append_ok = NO;
        int j = 0;
        while (!append_ok && j < 30) {
            if (adaptor.assetWriterInput.readyForMoreMediaData)  {
                //print out status:
                NSLog(@"Processing video frame (%d,%lu)",frameCount,(unsigned long)[framesPaths count]);
                
                CMTime frameTime = CMTimeMake(frameCount * 600.0/fps, 600);

                append_ok = [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];
                if (!append_ok) {
                    NSError *error = videoWriter.error;
                    if (error != nil) {
                        NSLog(@"Unresolved error %@,%@.", error, [error userInfo]);
                    }
                }
            }
            else {
                printf("adaptor not ready %d, %d\n", frameCount, j);
                [NSThread sleepForTimeInterval:0.1];
            }
            j++;
        }
        if (!append_ok) {
            printf("error appending image %d times %d\n, with error.", frameCount, j);
        }
        CVPixelBufferRelease(buffer)
        frameCount++;
    }
    NSLog(@"**************************************************");
    
    //Finish the session:
    [videoWriterInput markAsFinished];
    [videoWriter finishWriting];
    NSLog(@"Write Ended");
        
    ///// THAT IS IT DONE... the final video file will be written here...
    NSLog(@"DONE.....outputFilePath--->%@", outputPath);
}


+ (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image {
    
    CGSize size = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
    size.width = ((int)size.width / 16) * 16;
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          size.width,
                                          size.height,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    if (status != kCVReturnSuccess){
        NSLog(@"Failed to create pixel buffer");
    }
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width,
                                                 size.height, 8, 4 * size.width, rgbColorSpace,
                                                 kCGImageAlphaPremultipliedFirst);
    //kCGImageAlphaNoneSkipFirst);
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

@end
