//
//  UIImageFromCVMat.m
//  TrackLight
//
//  Created by HANSHAOWEN on 16/11/8.
//  Copyright © 2016年 HANSHAOWEN. All rights reserved.
//

#import "CamShift.h"

@implementation CamShiftDemo

-(id)init
{
    trackObject = 0;
    hsize = 16;
    hranges[0] = 0;
    hranges[1] = 180;
    phranges = hranges;
    //phranges[1] = 180;
    vmin = 10;
    vmax = 256;
    smin = 30;
    backprojMode = NO;
    selectObject = NO;
    return self;
}

- (void)panDetect:(UIPanGestureRecognizer *)gestureRecognizer
{
    
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan){
        NSLog(@"panDetect UIGestureRecognizerStateBegan");
        CGPoint point = [gestureRecognizer locationInView:gestureRecognizer.view];
        NSLog(@" x, y: %f , %f", point.x, point.y);
    }
    /*else if([gestureRecognizer state] == UIGestureRecognizerStateChanged) {
     NSLog(@"panDetect UIGestureRecognizerStateChanged");
     
     }*/
    else if([gestureRecognizer state] == UIGestureRecognizerStateCancelled
            ||[gestureRecognizer state] == UIGestureRecognizerStateEnded
            ||[gestureRecognizer state] == UIGestureRecognizerStateFailed){
        NSLog(@"panDetect UIGestureRecognizerStateEnded");
        
        CGPoint point = [gestureRecognizer locationInView:gestureRecognizer.view];
        NSLog(@"x, y: %f , %f", point.x, point.y);
    }
}

-(void)gestureCallBack:(UIPanGestureRecognizer *)gestureRecognizer
{
    CGPoint point = [gestureRecognizer locationInView:gestureRecognizer.view];
    if(selectObject)
    {
        selection.x = MIN(point.x,origin.x);
        selection.y = MIN(point.y, origin.y);
        selection.width = std::abs(point.x-origin.x);
        selection.height = std::abs(point.y - origin.y);
        
        selection &= cv::Rect(0,0,image.cols,image.rows);
    }
    
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) // 第一次触控按下
    {
        origin = cv::Point(point.x,point.y);
        selection = cv::Rect(point.x,point.y,0,0);
        selectObject = true;
    }
    else if([gestureRecognizer state] == UIGestureRecognizerStateCancelled
            ||[gestureRecognizer state] == UIGestureRecognizerStateEnded
            ||[gestureRecognizer state] == UIGestureRecognizerStateFailed)
    {
        selectObject = false;
        if(selection.width>0 && selection.height>0)
            trackObject = -1;
    }
    
}

-(void)getSelection:(cv::Rect)selectArea
{
    selection = selectArea;
    selectObject = false;
    if(selection.width>0 && selection.height>0)
        trackObject = -1;
}

-(void)processMain:(cv::Mat&)frame
{
    // copy frame to image
    //frame.copyTo(image);
    
    cvtColor(frame, image, CV_RGBA2RGB);
    
    //NSLog(@"size :%i ,%i",image.cols,image.rows);
    // tramsform rgb to hsv
    cvtColor(image, hsv, CV_BGR2HSV);
    
    if (trackObject)
    {
        int _vmin = vmin;
        int _vmax = vmax;
        // 掩模板 只处理像素值为H：0～180，S：smin～256，V：vmin～vmax之间部分
        //cvInRangeS(&(hsv), cvScalar(0, smin, MIN(_vmin,_vmax),0), cvScalar(180, 256, MAX(_vmin, _vmax),0), &(mask));
        
        // inRange函数的功能是检查输入每个元素大小是否在2个给定数值之间 可以有多通道 mask保存0通道的最小值 也就是h分量
        // 这里利用了hsv的3个通道 比较h，0～180，s，smin～256，v，min（vmin～vmax） 如果3个通道都在对应的范围内
        // 则mask对应的那个点的值全为1（0xff），否则为0（0x00）
        inRange(hsv, Scalar(0,smin,MIN(_vmin,_vmax)), Scalar(180,256,MAX(_vmin,_vmax)), mask);
        
        int ch[] = {0,0};
        
        // hue初始化为与hsv大小深度一样的矩阵 色调的度量是用角度表示的 红绿蓝之间相差120度 反色相差180度
        hue.create(hsv.size(), hsv.depth());
        
        // 将hsv第一个通道（也就是色调）的数复制到hue中 0索引数组
        mixChannels(&hsv,1,&hue,1,ch,1);
        
        // 如果需要跟踪的物体还没有进行属性提取，则进行选取框内的图像属性提取
        // 鼠标选择区域松开后 该函数内部又将其赋值1
        if (trackObject<0)
        {
            // 此处的构造函数roi用的是Mat hue的矩阵头，且roi的数据指针指向hue，即公用相同的数据 selection为其感兴趣的区域
            // maskroi同理
            Mat roi(hue,selection), maskroi(mask,selection);
            
            //calcHist()函数
            //第1个参数为输入矩阵序列
            //第2个参数表示输入的矩阵数目
            //第3个参数表述将被计算直方图维数通道的列表
            //第4个参数表示可选的掩码函数
            //第5个参数表示输出直方图
            //第6个参数表示直方图的维数
            //第7个参数表示每一维直方图数组的大小
            //第8个参数为每一维直方图bin的边界
            calcHist(&roi, 1, 0, maskroi, hist, 1, &hsize, &phranges);
            
            //将hist矩阵归一化到0~255
            normalize(hist, hist, 0, 255,CV_MINMAX);
            
            trackWindow = selection;
            
            // 重新设回不选中状态
            trackObject = 1;
            
        }
        
        //计算hue图像0通道的hist直方图的反向投影 并存入backproject
        calcBackProject(&hue, 1, 0, hist, backproject, &phranges);
        backproject &= mask;
        
        //NSLog(@"trackWindow size :%i ,%i",trackWindow.width,trackWindow.height);
        //NSLog(@"selection size :%i ,%i",selection.width,selection.height);
        
        RotatedRect trackBox = CamShift(
                                        backproject,
                                        trackWindow,
                                        TermCriteria(CV_TERMCRIT_EPS|CV_TERMCRIT_ITER,10,1)
                                        );
        
        if(trackWindow.area()<=1)
        {
            /*
             NSLog(@"trackWindow.area()<=1!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
             int cols = backproject.cols,rows = backproject.rows,r = (MIN(cols,rows)+5)/6;
             NSLog(@"r:%i",r);
             NSLog(@"backproject size :%i ,%i",backproject.cols,backproject.rows);
             NSLog(@"trackWindow.area()<=1!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
             NSLog(@"Rect:%i %i %i %i:",trackWindow.x-r,trackWindow.x-r,trackWindow.x-r,trackWindow.x-r);
             trackWindow = cv::Rect(
             trackWindow.x-r,
             trackWindow.y-r,
             trackWindow.x+r,
             trackWindow.y+r
             )&
             cv::Rect(0,0,cols,rows);
             */
            trackObject = 0;
        }
        
        if (backprojMode) // 转换显示方式 将backproj显示出来
        {
            cvtColor(backproject, image, CV_GRAY2BGR);
        }
        ellipse(image, trackBox, Scalar(0,0,255), 3, CV_AA);
        
    }
    
    /*
     // 如果正处于选择物体 画出选择区域
     if (selectObject && selection.width>0 && selection.height>0)
     {
     Mat roi(image,selection);
     bitwise_not(roi, roi);// bitwise_not为将每一位bit取反
     }
    */
    
    cvtColor(image, frame, CV_RGB2RGBA);
    frame = image;
}
@synthesize trackObject;
@end
