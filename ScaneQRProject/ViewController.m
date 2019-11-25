//
//  ViewController.m
//  ScaneQRProject
//
//  Created by feiniao on 2019/11/25.
//  Copyright © 2019 com.oc.shy. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<AVCaptureMetadataOutputObjectsDelegate>

@property(nonatomic,strong)AVCaptureSession *mAVCaptureSession;
@property(nonatomic,strong)AVCaptureVideoPreviewLayer *mVideoPreviewLayer;
@property(nonatomic,strong)AVCaptureMetadataOutput *mCaptureMetadataOutput;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"扫描二维码";
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self initQRConfiguration];
    [self initView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.mAVCaptureSession startRunning];
}

- (void)initView
{
    //配置界面
    self.mVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.mAVCaptureSession];
    self.mVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.mVideoPreviewLayer.frame = [UIScreen mainScreen].bounds;
    [self.view.layer insertSublayer:self.mVideoPreviewLayer above:0];
    
    UIImage *borderImage = [UIImage imageNamed:@"pick_bg"];
    CGFloat borderImageWidth = borderImage.size.width;
    CGFloat borderImageHeight = borderImage.size.height;
    CGFloat borderPosX = (CGRectGetWidth(self.view.frame) - borderImageWidth)/2.0f;
    CGFloat borderPosY = (CGRectGetHeight(self.view.frame) - borderImageHeight)/2.0f;
    CGRect rect = CGRectMake(borderPosX, borderPosY, borderImageWidth, borderImageHeight);
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.view.frame];
    UIBezierPath *outPath = [UIBezierPath bezierPathWithRect:rect];
    [path appendPath:outPath.bezierPathByReversingPath];
    CAShapeLayer *shaperLayer = [CAShapeLayer layer];
    shaperLayer.path = path.CGPath;
    
    
    CALayer *backgroundLayer = [CALayer layer];
    backgroundLayer.frame = self.self.mVideoPreviewLayer.frame;
    backgroundLayer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2].CGColor;
    backgroundLayer.mask = shaperLayer;
    [self.mVideoPreviewLayer addSublayer:backgroundLayer];
    
    CALayer *borderImageLayer = [CALayer layer];
    borderImageLayer.frame = rect;
    borderImageLayer.contents = (id)borderImage.CGImage;
    [self.mVideoPreviewLayer addSublayer:borderImageLayer];
    
    UIImage *lineImage = [UIImage imageNamed:@"line"];
    CGFloat lineWidth = borderImage.size.width;
    CGFloat lineHeight = lineImage.size.height*lineWidth/lineImage.size.width;
    CALayer *lineLayer = [CALayer layer];
    lineLayer.frame = CGRectMake(0.0f, 0.0f, lineWidth, lineHeight);
    lineLayer.contents = (id)lineImage.CGImage;
    [borderImageLayer addSublayer:lineLayer];;
    
    CABasicAnimation *basicAnimation = [CABasicAnimation animation];
    basicAnimation.keyPath = @"position.y";
    basicAnimation.fromValue = @(0);
    basicAnimation.toValue = @(CGRectGetHeight(borderImageLayer.frame));
    basicAnimation.duration = 3.0f;
    basicAnimation.autoreverses = YES;
    basicAnimation.repeatCount = CGFLOAT_MAX;
    [lineLayer addAnimation:basicAnimation forKey:@"lineAnimation"];
    
    //(y,x,h,w)
    CGFloat scaneWidth = CGRectGetHeight(borderImageLayer.frame)/backgroundLayer.frame.size.height;
    CGFloat scaneHeight = CGRectGetWidth(borderImageLayer.frame)/backgroundLayer.frame.size.width;
    CGFloat scanePosX = CGRectGetMinY(borderImageLayer.frame)/backgroundLayer.frame.size.height;
    CGFloat scanePosY = CGRectGetMinX(borderImageLayer.frame)/backgroundLayer.frame.size.width;
    self.mCaptureMetadataOutput.rectOfInterest = CGRectMake(scanePosX, scanePosY, scaneWidth, scaneHeight);
}

- (void)initQRConfiguration
{
    NSError *error = nil;
    self.mAVCaptureSession = [[AVCaptureSession alloc]init];
    [self.mAVCaptureSession setSessionPreset:AVCaptureSessionPresetHigh];
    
    //配置输入设备
    AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *deviceinput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:&error];
    if ([self.mAVCaptureSession canAddInput:deviceinput])
    {
        [self.mAVCaptureSession addInput:deviceinput];
    }
    
    //配置输出设备
    self.mCaptureMetadataOutput = [[AVCaptureMetadataOutput alloc]init];
    if ([self.mAVCaptureSession canAddOutput:self.mCaptureMetadataOutput])
    {
        [self.mAVCaptureSession addOutput:self.mCaptureMetadataOutput];
    }
    
    
    [self.mCaptureMetadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    [self.mCaptureMetadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
}

#pragma mark AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    [self.mAVCaptureSession stopRunning];
    AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects.firstObject;
    NSString *content = metadataObject.stringValue;
    BOOL isURL = [self isUrlAddress:content];
    UIViewController *webVC = [[UIViewController alloc]init];
    webVC.view.backgroundColor = [UIColor whiteColor];
    webVC.title = @"扫描结果";
    if (isURL)
    {
        UIWebView *webView = [[UIWebView alloc]initWithFrame:self.view.frame];
        [webVC.view addSubview:webView];
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:content]];
        [webView loadRequest:urlRequest];
    }else
    {
        CGRect rect = CGRectMake(0.0f,100, CGRectGetWidth(self.view.frame), 100);
        UILabel *label = [[UILabel alloc]initWithFrame:rect];
        label.numberOfLines = 0;
        [webVC.view addSubview:label];
        label.text = content;
    }
    [self.navigationController pushViewController:webVC animated:YES];
    
}

- (BOOL)isUrlAddress:(NSString*)url
{
    NSString*reg =@"((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)";
    NSPredicate*urlPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", reg];
    
    return[urlPredicate evaluateWithObject:url];
    
}



@end
