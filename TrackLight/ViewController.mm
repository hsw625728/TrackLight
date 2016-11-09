//
//  ViewController.m
//  TrackLight
//
//  Created by HANSHAOWEN on 16/11/8.
//  Copyright © 2016年 HANSHAOWEN. All rights reserved.
//

#import "ViewController.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc/types_c.h>
#import <opencv2/videoio/cap_ios.h>
#import <opencv2/imgcodecs/ios.h>

@interface ViewController ()<CvVideoCameraDelegate>
{
    cv::Mat cvImage;
    cv::CascadeClassifier faceDetector;
}
@property (strong, nonatomic)  UIImageView *imageView;
@property (nonatomic,strong) CvVideoCamera *videoCamera;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.imageView = [[UIImageView alloc]initWithFrame:self.view.frame];
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:self.imageView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
    self.videoCamera.defaultFPS = 30;
    
    [self.view addSubview:self.imageView];
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(10, 50, 100, 100)];
    [btn addTarget:self action:@selector(start) forControlEvents:UIControlEventTouchUpInside];
    [btn setBackgroundColor:[UIColor redColor]];
    [self.view addSubview:btn];
}

- (void)start{
    [self.videoCamera start];
}

- (void)processImage:(cv::Mat &)image
{
    cv::Mat gray;
    // 将图像转换为灰度显示
    cv::cvtColor(image, gray, CV_RGBA2GRAY);
    // 应用高斯滤波器去除小的边缘
    cv::GaussianBlur(gray, gray, cv::Size(5,5), 1.2,1.2);
    //计算与画布边缘
    cv::Mat edges;
    cv::Canny(gray, edges, 0, 50);
    //使用白色填充
    image.setTo(cv::Scalar::all(255));
    // 修改边缘颜色
    image.setTo(cv::Scalar(0,128,255,255),edges);
    // 将Mat转换为Xcode的UIImageView显示
    self.imageView.image = MatToUIImage(image);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
