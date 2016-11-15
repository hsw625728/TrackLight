//
//  UIImageFromCVMat.h
//  TrackLight
//
//  Created by HANSHAOWEN on 16/11/8.
//  Copyright © 2016年 HANSHAOWEN. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <opencv2/videoio/cap_ios.h>
using namespace cv;
@interface CamShiftDemo : NSObject
{
    Mat image;
    Mat hsv;
    Mat hue;
    Mat mask;
    Mat backproject;
    Mat histimg;
    Mat hist;
    
    cv::Point origin;
    cv::Rect selection;
    cv::Rect trackWindow;
    int trackObject;
    int hsize;
    float hranges[2];
    const float* phranges;
    int vmin;
    int vmax;
    int smin;
    BOOL backprojMode;
    BOOL selectObject;
}
-(void)processMain:(cv::Mat&)indata;
-(void)panDetect:(UIPanGestureRecognizer *)gestureRecognizer;
-(void)gestureCallBack:(UIPanGestureRecognizer *)gestureRecognizer;
-(void)getSelection:(cv::Rect)selectArea;
@property int trackObject;
@end

