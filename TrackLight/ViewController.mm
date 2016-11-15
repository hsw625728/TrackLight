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
    else
    {
        
        static IplImage *frame = NULL, *frame1 = NULL, *frame1_1C = NULL, *frame2_1C = NULL, *eig_image = NULL, *temp_image = NULL, *pyramid1 = NULL, *pyramid2 = NULL;
        /* Go to the frame we want. Important if multiple frames are queried in
         * the loop which they of course are for optical flow. Note that the very
         * first call to this is actually not needed. (Because the correct position
         * is set outsite the for() loop.)
         */
        //cv::cvSetCaptureProperty( input_video, CV_CAP_PROP_POS_FRAMES, current_frame );
        /* Get the next frame of the video.
         * IMPORTANT! cvQueryFrame() always returns a pointer to the _same_
         * memory location. So successive calls:
         * frame1 = cvQueryFrame();
         * frame2 = cvQueryFrame();
         * frame3 = cvQueryFrame();
         * will result in (frame1 == frame2 && frame2 == frame3) being true.
         * The solution is to make a copy of the cvQueryFrame() output.
         */
        //类型转换
        //frame = cvQueryFrame( input_video );
        cv::Mat image1;
        IplImage* image2;
        image2 = cvCreateImage(cvSize(image1.cols,image1.rows),8,3);
        IplImage ipltemp=image1;
        cvCopy(&ipltemp,image2);
        if (frame == NULL)
        {
            /* Why did we get a NULL frame? We shouldn't be at the end. */
            fprintf(stderr, "Error: Hmm. The end came sooner than we thought.\n");
            return -1;
        }
        
        /* Allocate another image if not already allocated.
         * Image has ONE challenge of color (ie: monochrome) with 8-bit "color" depth.
         * This is the image format OpenCV algorithms actually operate on (mostly).
         */
        allocateOnDemand( &frame1_1C, frame_size, IPL_DEPTH_8U, 1 );
        
        /* Convert whatever the AVI image format is into OpenCV's preferred format.
         * AND flip the image vertically. Flip is a shameless hack. OpenCV reads
         * in AVIs upside-down by default. (No comment :-))
         */
        cvConvertImage(frame, frame1_1C, CV_CVTIMG_FLIP);
        
        /* We'll make a full color backup of this frame so that we can draw on it.
         * (It's not the best idea to draw on the static memory space of cvQueryFrame().)
         */
        allocateOnDemand( &frame1, frame_size, IPL_DEPTH_8U, 3 );
        cvConvertImage(frame, frame1, CV_CVTIMG_FLIP);
        
        /* Get the second frame of video. Sample principles as the first. */
        frame = cvQueryFrame( input_video );
        if (frame == NULL)
        {
            fprintf(stderr, "Error: Hmm. The end came sooner than we thought.\n");
            return -1;
        }
        allocateOnDemand( &frame2_1C, frame_size, IPL_DEPTH_8U, 1 );
        cvConvertImage(frame, frame2_1C, CV_CVTIMG_FLIP);
        
        /* Shi and Tomasi Feature Tracking! */
        /* Preparation: Allocate the necessary storage. */
        allocateOnDemand( &eig_image, frame_size, IPL_DEPTH_32F, 1 );
        allocateOnDemand( &temp_image, frame_size, IPL_DEPTH_32F, 1 );
        
        /* Preparation: This array will contain the features found in frame 1. */
        CvPoint2D32f frame1_features[400];
        
        
        /* Preparation: BEFORE the function call this variable is the array size
         * (or the maximum number of features to find). AFTER the function call
         * this variable is the number of features actually found.
         */
        int number_of_features;
        
        /* I'm hardcoding this at 400. But you should make this a #define so that you can
         * change the number of features you use for an accuracy/speed tradeoff analysis.
         */
        number_of_features = 400;
        
        /* Actually run the Shi and Tomasi algorithm!!
         * "frame1_1C" is the input image.
         * "eig_image" and "temp_image" are just workspace for the algorithm.
         * The first ".01" specifies the minimum quality of the features (based on the
         eigenvalues).
         * The second ".01" specifies the minimum Euclidean distance between features.
         * "NULL" means use the entire input image. You could point to a part of the
         image.
         * WHEN THE ALGORITHM RETURNS:
         * "frame1_features" will contain the feature points.
         * "number_of_features" will be set to a value <= 400 indicating the number of
         feature points found.
         */
        cvGoodFeaturesToTrack(frame1_1C, eig_image, temp_image, frame1_features, &number_of_features, .01, .01, NULL);
        
        /* Pyramidal Lucas Kanade Optical Flow! */
        /* This array will contain the locations of the points from frame 1 in frame 2. */
        CvPoint2D32f frame2_features[400];
        
        /* The i-th element of this array will be non-zero if and only if the i-th feature of
         * frame 1 was found in frame 2.
         */
        char optical_flow_found_feature[400];
        
        /* The i-th element of this array is the error in the optical flow for the i-th feature
         * of frame1 as found in frame 2. If the i-th feature was not found (see the array above)
         * I think the i-th entry in this array is undefined.
         */
        float optical_flow_feature_error[400];
        
        /* This is the window size to use to avoid the aperture problem (see slide "Optical Flow: Overview"). */
        CvSize optical_flow_window = cvSize(3,3);
        
        /* This termination criteria tells the algorithm to stop when it has either done 20 iterations or when
         * epsilon is better than .3. You can play with these parameters for speed vs. accuracy but these values
         * work pretty well in many situations.
         */
        CvTermCriteria optical_flow_termination_criteria = cvTermCriteria( CV_TERMCRIT_ITER | CV_TERMCRIT_EPS, 20, .3 );
        
        /* This is some workspace for the algorithm.
         * (The algorithm actually carves the image into pyramids of different resolutions.)
         */
        allocateOnDemand( &pyramid1, frame_size, IPL_DEPTH_8U, 1 );
        allocateOnDemand( &pyramid2, frame_size, IPL_DEPTH_8U, 1 );
        
        /* Actually run Pyramidal Lucas Kanade Optical Flow!!
         * "frame1_1C" is the first frame with the known features.
         * "frame2_1C" is the second frame where we want to find the first frame's features.
         * "pyramid1" and "pyramid2" are workspace for the algorithm.
         * "frame1_features" are the features from the first frame.
         * "frame2_features" is the (outputted) locations of those features in the second frame.
         * "number_of_features" is the number of features in the frame1_features array.
         * "optical_flow_window" is the size of the window to use to avoid the aperture problem.
         * "5" is the maximum number of pyramids to use. 0 would be just one level.
         * "optical_flow_found_feature" is as described above (non-zero iff feature found by the flow).
         * "optical_flow_feature_error" is as described above (error in the flow for this feature).
         * "optical_flow_termination_criteria" is as described above (how long the algorithm should look).
         * "0" means disable enhancements. (For example, the second aray isn't preinitialized with guesses.)
         */
        cvCalcOpticalFlowPyrLK(frame1_1C, frame2_1C, pyramid1, pyramid2, frame1_features,
                               frame2_features, number_of_features, optical_flow_window, 5,
                               optical_flow_found_feature, optical_flow_feature_error,
                               optical_flow_termination_criteria, 0 );
        
        /* For fun (and debugging :)), let's draw the flow field. */
        for(int i = 0; i < number_of_features; i++)
        {
            /* If Pyramidal Lucas Kanade didn't really find the feature, skip it. */
            if ( optical_flow_found_feature[i] == 0 ) continue;
            int line_thickness; line_thickness = 1;
            /* CV_RGB(red, green, blue) is the red, green, and blue components
             * of the color you want, each out of 255.
             */
            CvScalar line_color; line_color = CV_RGB(255,0,0);
            /* Let's make the flow field look nice with arrows. */
            /* The arrows will be a bit too short for a nice visualization because of the
             high framerate
             * (ie: there's not much motion between the frames). So let's lengthen them
             by a factor of 3.
             */
            CvPoint p,q;
            p.x = (int) frame1_features[i].x;
            p.y = (int) frame1_features[i].y;
            q.x = (int) frame2_features[i].x;
            q.y = (int) frame2_features[i].y;
            double angle; angle = atan2( (double) p.y - q.y, (double) p.x - q.x );
            double hypotenuse; hypotenuse = sqrt( square(p.y - q.y) + square(p.x - q.x) );
            /* Here we lengthen the arrow by a factor of three. */
            q.x = (int) (p.x - 3 * hypotenuse * cos(angle));
            q.y = (int) (p.y - 3 * hypotenuse * sin(angle));
            /* Now we draw the main line of the arrow. */
            /* "frame1" is the frame to draw on.
             * "p" is the point where the line begins.
             * "q" is the point where the line stops.
             * "CV_AA" means antialiased drawing.
             * "0" means no fractional bits in the center cooridinate or radius.
             */
            cvLine( frame1, p, q, line_color, line_thickness, CV_AA, 0 );
            /* Now draw the tips of the arrow. I do some scaling so that the
             * tips look proportional to the main line of the arrow.
             */
            p.x = (int) (q.x + 9 * cos(angle + pi / 4));
            p.y = (int) (q.y + 9 * sin(angle + pi / 4));
            cvLine( frame1, p, q, line_color, line_thickness, CV_AA, 0 );
            p.x = (int) (q.x + 9 * cos(angle - pi / 4));
            p.y = (int) (q.y + 9 * sin(angle - pi / 4));
            cvLine( frame1, p, q, line_color, line_thickness, CV_AA, 0 );
        }
        /* Now display the image we drew on. Recall that "Optical Flow" is the name of
         * the window we created above.
         */
        cvShowImage("Optical Flow", frame1);
        /* And wait for the user to press a key (so the user has time to look at the
         image).
         * If the argument is 0 then it waits forever otherwise it waits that number of
         milliseconds.
         * The return value is the key the user pressed.
         */
        int key_pressed;
        key_pressed = cvWaitKey(0);
        /* If the users pushes "b" or "B" go back one frame.
         * Otherwise go forward one frame.
         */
        if (key_pressed == 'b' || key_pressed == 'B') current_frame--;
        else current_frame++;
        /* Don't run past the front/end of the AVI. */
        if (current_frame < 0) current_frame = 0;
        if (current_frame >= number_of_frames - 1) current_frame = number_of_frames - 2;
    }
}

- (void) CamShiftDetect:(UIImage *)capPic  {
    NSAutoreleasePool * pool = [[NSAutoreleasePoolalloc]init];
    IplImage *image =0, *hsv =
    0, *hue =0, *mask =
    0, *backproject =0, *histimg =
    0;
    CvHistogram *hist =0;
    int backproject_mode =0;
    int track_object =0;
    int select_object =0;
    CvConnectedComp track_comp;
    CvRect selection;
    CvRect track_window;
    CvBox2D track_box;
    int hdims =16;
    float hranges_arr[] = {0,180};
    float* hranges = hranges_arr;
    int vmin =90, vmax =256, smin =90;
    //if(imageView.image) {
    cvSetErrMode(CV_ErrModeParent);
    
    /* allocate all the buffers */
    IplImage* frame =0;
    frame = [selfCreateIplImageFromUIImage:capPic];
    //NSLog(@"%d  %d" , cvGetSize(frame).width, cvGetSize(frame).height);
    image =cvCreateImage(cvGetSize(frame),8,3
                         );
    image->origin = frame->origin;
    hsv =cvCreateImage(cvGetSize(frame),8,3
                       );
    hue =cvCreateImage(cvGetSize(frame),8,1
                       );
    mask =cvCreateImage(cvGetSize(frame),8,1
                        );
    backproject =cvCreateImage(cvGetSize(frame),8,1
                               );
    hist =cvCreateHist(1, &hdims,CV_HIST_ARRAY, &hranges,1
                       );
    histimg =cvCreateImage(cvSize(360,480),8,3
                           );
    cvZero( histimg );
    
    NSString *path = [[NSBundlemainBundle]pathForResource:@"target12"ofType:@"jpg"];
    IplImage *tempimage = [selfCreateIplImageFromUIImage:[UIImageimageWithContentsOfFile:path]];
    cvCvtColor( tempimage, hsv,CV_BGR2HSV );
    int _vmin = vmin, _vmax = vmax;
    
    cvInRangeS( hsv,cvScalar(0,smin,MIN(_vmin,_vmax),0),
               cvScalar(180,256,MAX(_vmin,_vmax),0),
               mask );
    cvSplit( hsv, hue,0,
            0, 0 );
    
    selection.x =1;
    selection.y =1;
    selection.width =360-1;
    selection.height=480-1;
    
    cvSetImageROI( hue, selection );
    cvSetImageROI( mask, selection );
    cvCalcHist( &hue, hist,0, mask );
    
    float max_val =0.f;
    
    cvGetMinMaxHistValue( hist,0, &max_val,
                         0,0 );
    cvConvertScale( hist->bins, hist->bins, max_val ?255.
                   / max_val : 0.,0 );
    cvResetImageROI( hue );
    cvResetImageROI( mask );
    track_window = selection;
    track_object =1;
    
    
    cvZero( histimg );
    int bin_w = histimg->width / hdims;
    for(int i =0; i < hdims; i++ )
    {
        int val =cvRound(cvGetReal1D(hist->bins,i)*histimg->height/255
                         );
        CvScalar color =hsv2rgb(i*180.f/hdims);
        cvRectangle( histimg,cvPoint(i*bin_w,histimg->height),
                    cvPoint((i+1)*bin_w,histimg->height - val),
                    color, -1,8,0 );
    }
    
    cvReleaseImage(&tempimage);
    cvCopy( frame, image,0 );
    cvCvtColor( image, hsv,CV_BGR2HSV );
    if( track_object )
    {
        int _vmin = vmin, _vmax = vmax;
        
        cvInRangeS( hsv,cvScalar(0,smin,MIN(_vmin,_vmax),0),
                   cvScalar(180,256,MAX(_vmin,_vmax),0),
                   mask );
        cvSplit( hsv, hue,0,
                0, 0 );
        
        cvCalcBackProject( &hue, backproject, hist );
        cvAnd( backproject, mask, backproject,0 );
        
        cvCamShift( backproject, track_window,cvTermCriteria(CV_TERMCRIT_EPS
                                                             | CV_TERMCRIT_ITER,
                                                             10, 1 ),&track_comp, &track_box );
        track_window = track_comp.rect;
        
        if( backproject_mode )
            cvCvtColor( backproject, image,CV_GRAY2BGR );
        if( image->origin )
            track_box.angle = -track_box.angle;
        cvEllipseBox( image, track_box,CV_RGB(255,0,0),3,CV_AA,
                     0 );
        // Create canvas to show the results
        CGImageRef imageRef =imageView.image.CGImage;
        CGColorSpaceRef colorSpace =CGColorSpaceCreateDeviceRGB();
        CGContextRef contextRef =CGBitmapContextCreate(NULL,imageView.image.size.width,imageView.image.size.height,
                                                       8,imageView.image.size.width
                                                       *4,
                                                       colorSpace,kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault);
        CGContextDrawImage(contextRef,CGRectMake(0,0,
                                                 imageView.image.size.width,imageView.image.size.height),
                           imageRef);
        
        CGContextSetLineWidth(contextRef,4);
        CGContextSetRGBStrokeColor(contextRef,0.0,
                                   0.0, 1.0,0.5);
        // Draw results on the iamge
        
        NSLog(@" %d \n %d\n %d \n %d",track_window.x,track_window.y,track_window.width,track_window.height);
        NSLog(@"box %@",NSStringFromCGRect(CGRectMake(track_box.center.x,track_box.center.y,track_box.size.width,track_box.size.height)));
        [selfperformSelectorInBackground:@selector(draw1:)withObject:NSStringFromCGRect(CGRectMake(360-track_box.center.y,track_box.center.x,track_box.size.width,track_box.size.height))];
    }
    
    if( select_object && selection.width >0 && selection.height
       >0 )
    {
        cvSetImageROI( image, selection );
        cvXorS( image,cvScalarAll(255), image,0
               );
        cvResetImageROI( image );
    }
    [selfhideProgressIndicator];
    [poolrelease];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
