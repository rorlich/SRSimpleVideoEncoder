//
//  VideoEncoder.h
//  GyGoIntegrationApp
//
//  Created by Sagi Rorlich on 02/11/2017.
//  Copyright © 2017 Visualead. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoEncoder : NSObject

+(void)encodeFrames:(NSArray<NSString*>*)framesPaths outputPath:(NSString*)outputPath;
@end
