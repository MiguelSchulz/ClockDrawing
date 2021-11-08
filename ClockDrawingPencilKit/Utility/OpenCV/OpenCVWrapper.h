//
//  OpenCVWrapper.h
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 31.10.21.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject

+ (NSString *) openCVVersionString;
+ (UIImage *) testDetectImg: (UIImage *) image;

@end

NS_ASSUME_NONNULL_END
