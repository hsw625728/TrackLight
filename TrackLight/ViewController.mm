//
//  ViewController.m
//  TrackLight
//
//  Created by HANSHAOWEN on 16/11/8.
//  Copyright © 2016年 HANSHAOWEN. All rights reserved.
//

#import "ViewController.h"
#import "CamShift.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc/types_c.h>
#import <opencv2/videoio/cap_ios.h>
#import <opencv2/imgcodecs/ios.h>

#import <opencv2/core/core.hpp>
//#import <opencv2/nonfree/nonfree.hpp>

@interface ViewController ()<CvVideoCameraDelegate>
{
    cv::Mat cvImage;
    cv::CascadeClassifier faceDetector;
}
@property (strong, nonatomic)  UIImageView *imageView;
@property (nonatomic,strong) CvVideoCamera *videoCamera;

@end

@implementation ViewController
int bian1 = 0;
@synthesize videoCamera;
CamShiftDemo* camshift;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //[self.imageView setImage:[UIImage imageNamed:@"tk.jpg"]];
    self.imageView = [[UIImageView alloc]initWithFrame:self.view.frame];
    [self.view addSubview:self.imageView];
    
    camshift = [[CamShiftDemo alloc] init];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:camshift action:@selector(gestureCallBack:)];
    [panGesture setMaximumNumberOfTouches:1];
    //给imageView添加点击事件
    //[self.imageView addGestureRecognizer:panGesture];
    [self.view addGestureRecognizer:panGesture];
    
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:self.imageView];
    self.videoCamera.delegate = self;
    //前置后置摄像头
    //self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetPhoto;//AVCaptureSessionPreset640x480;
    
    //self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.grayscaleMode = NO;
    
    //启动摄像头、关闭摄像头
    UIButton *btnStart = [[UIButton alloc]initWithFrame:CGRectMake(10, 50, 100, 50)];
    [btnStart addTarget:self action:@selector(startCamera) forControlEvents:UIControlEventTouchUpInside];
    [btnStart setBackgroundColor:[UIColor redColor]];
    [btnStart setTitle:@"启动" forState:UIControlStateNormal];
    [self.view addSubview:btnStart];
    
    UIButton *btnStop = [[UIButton alloc]initWithFrame:CGRectMake(120, 50, 100, 50)];
    [btnStop addTarget:self action:@selector(stopCamera) forControlEvents:UIControlEventTouchUpInside];
    [btnStop setBackgroundColor:[UIColor blueColor]];
    [btnStop setTitle:@"关闭" forState:UIControlStateNormal];
    [self.view addSubview:btnStop];
    
    UIButton *btnB = [[UIButton alloc]initWithFrame:CGRectMake(230, 50, 100, 50)];
    [btnB addTarget:self action:@selector(bianyuan) forControlEvents:UIControlEventTouchUpInside];
    [btnB setBackgroundColor:[UIColor blackColor]];
    [btnB setTitle:@"边缘检测" forState:UIControlStateNormal];
    [self.view addSubview:btnB];
    
    
    // Do any additional setup after loading the view, typically from a nib.
    /*
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
    */
}
-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (self.videoCamera.running)
    {
        [videoCamera stop];
    }
}
//#ifdef __cpluscplus
/*
-(void)processImage:(cv::Mat&)image
{
    
    [camshift processMain:image];
    self.imageView.image = MatToUIImage(image);
}
 */
//#endif

-(IBAction)startCamera/*:(id)sender*/
{
    if(![videoCamera running]){
        [videoCamera start];
    }
}

-(IBAction)stopCamera/*:(id)sender*/
{
    if(/*isMatching &&*/ [videoCamera running]){
        [videoCamera stop];
    }
}

-(IBAction)bianyuan/*:(id)sender*/
{
    if (bian1)
    {
        bian1 = 0;
    }
    else{
        bian1 = 1;
    }
}



- (void)processImage:(cv::Mat &)image
{
    if (bian1)
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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
