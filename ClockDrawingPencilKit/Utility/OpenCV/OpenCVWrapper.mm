//
//  OpenCVWrapper.m
//  ClockDrawingPencilKit
//
//  Created by Miguel Schulz on 31.10.21.
//

#import "OpenCVWrapper.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <Foundation/Foundation.h>

@implementation OpenCVWrapper

+ (NSString *)openCVVersionString {
    return [NSString stringWithFormat:@"OpenCV Version %s",  CV_VERSION];
}

// DEPRECATED
+ (UIImage *)testDetectImg: (UIImage *) image {
    
    cv::Mat opencvImage;
    UIImageToMat(image, opencvImage, true);
    
    cv::Mat median;
    cv::medianBlur(opencvImage, median, 3);

    cv::Mat gray;
    cv::cvtColor(median, gray, cv::COLOR_RGB2GRAY);  //or use COLOR_BGR2GRAY

    cv::Mat denoise;
    cv::fastNlMeansDenoising(gray, denoise, 30.0, 7, 21);
    
    std::vector<std::vector<cv::Point> > contours;
    cv::Mat contourOutput = denoise.clone();
    cv::findContours( contourOutput, contours, cv::RETR_LIST, cv::CHAIN_APPROX_NONE );

    int largest_area=0;
    int largest_contour_index=0;
    // iterate through each contour.
    for( int i = 0; i< contours.size(); i++ )
    {
        //  Find the area of contour
        double a=contourArea( contours[i],false);
        if(a>largest_area){
            largest_area=a;std::cout<<i<<" area  "<<a<<std::endl;
            // Store the index of largest contour
            largest_contour_index=i;

        }
    }

    cv::Mat contourImage(denoise.size(), CV_8UC3, cv::Scalar(0,0,0));
    cv::Scalar color;
    color = cv::Scalar(255, 0, 0);

    cv::drawContours(contourImage, contours, largest_contour_index, color);

    
    
    UIImage *binImg = MatToUIImage(contourImage);
    return binImg;
    
}

@end
