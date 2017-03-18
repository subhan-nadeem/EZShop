//
//  CLFaceDetectionImagePickerViewController.m
//  DeputyKiosk
//
//  Created by caesar on 26/02/14.
//  Copyright (c) 2014 Caesar. All rights reserved.
//

#import "CLFaceDetectionImagePickerViewController.h"

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <AssertMacros.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "UIImage+CL.h"

#define TOTAL_TIMES_COUNT_DOWN 4    //This is initial waiting time when the imagePicker is firstly opened.

//Attribute Keys
NSString *const CLTotalDetectCountDownSecond = @"CLTotalDetectCountDownSecond";
NSString *const CLFaceDetectionSquareImageName = @"CLFaceDetectionSquareImageName";
NSString *const CLFaceDetectionTimes = @"CLFaceDetectionTimes";
NSString *const CLCameraPosition = @"CLCameraPosition";

//Default Values
static NSInteger const CLTotalDetectCountDownSecondDefault = 10;
static NSInteger const CLFaceDetectionTimesDefault = 5;
static NSString* const CLFaceDetectionSquareImageNameDefault = @"CameraSquare";
static NSInteger const CLCameraPositionDefault = AVCaptureDevicePositionFront;

@interface CLFaceDetectionImagePickerViewController ()<UIGestureRecognizerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic) NSInteger totalCountDownWaitingSecond;
@property (nonatomic) NSInteger totalFaceDetectionTimes;
@property (nonatomic) NSInteger cameraPosition;
@property (nonatomic, strong) NSString *faceDetectionSquareImageName;


@property (weak, nonatomic) IBOutlet UIView *preView;

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic) dispatch_queue_t videoDataOutputQueue;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) CIDetector *faceDetector;
@property (nonatomic, strong) UIImage *square;
@property (nonatomic) double timesDetectFace;
@property (nonatomic) double timesCountDown;

@property (nonatomic, strong) NSTimer *timerNoFaceDetect;
@property (nonatomic, strong) NSNumber *blnDisableAutoFaceDetection;

- (void)setupAVCapture;
- (void)teardownAVCapture;
- (void)drawFaceBoxesForFeatures:(NSArray *)features
      forVideoBox:(CGRect)videoBox
      orientation:(UIDeviceOrientation)orientation;
@end

@implementation CLFaceDetectionImagePickerViewController

- (id) init
{
    return [[UIStoryboard storyboardWithName:@"CLFaceDetectionImagePicker" bundle:nil] instantiateViewControllerWithIdentifier:@"CLFaceDetectionImagePickerViewController"];
}

-(void)setDelegate:(id<CLFaceDetectionImagePickerDelegate>)delegate
{
    _delegate = delegate;
    [self applyCustomDefaults];
}

-(void)applyCustomDefaults
{
    NSDictionary *attributes;
    
    if ([self.delegate respondsToSelector:@selector(faceDetectionBehaviorAttributes)]) {
        attributes = [self.delegate faceDetectionBehaviorAttributes];
    }
    
    self.totalCountDownWaitingSecond = attributes[CLTotalDetectCountDownSecond] ? [attributes[CLTotalDetectCountDownSecond] integerValue] : CLTotalDetectCountDownSecondDefault;

    self.square = [UIImage imageNamed: attributes[CLFaceDetectionSquareImageName] ? attributes[CLFaceDetectionSquareImageName] : CLFaceDetectionSquareImageNameDefault];
    
    self.cameraPosition = attributes[CLCameraPosition] ? [attributes[CLCameraPosition] integerValue ]: CLCameraPositionDefault;
    
    self.totalFaceDetectionTimes = attributes[CLFaceDetectionTimes] ? [attributes[CLFaceDetectionTimes] integerValue] : CLFaceDetectionTimesDefault;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
	[self setupAVCapture];
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}
-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self teardownAVCapture];
	self.faceDetector = nil;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(UIImage *)square
{
    if(!_square){
        _square = [UIImage imageNamed:CLFaceDetectionSquareImageNameDefault];
    }
    return _square;
}
-(CIDetector *)faceDetector
{
    if(!_faceDetector){
        NSDictionary *detectorOptions = [[NSDictionary alloc] initWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, nil];
        _faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
    }
    return _faceDetector;
}

- (void)setupAVCapture
{
    self.timesDetectFace = 0;
    self.timesCountDown = TOTAL_TIMES_COUNT_DOWN;
	NSError *error = nil;
	
	self.session = [[AVCaptureSession alloc] init];
    [self.session setSessionPreset:AVCaptureSessionPreset640x480];       //Do not set too high, otherwise face detection will be slow.
    
    // Select a video device, make an input
	AVCaptureDevice *device;
	
    AVCaptureDevicePosition desiredPosition = self.cameraPosition;
	
    // find the front facing camera
	for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
		if ([d position] == desiredPosition) {
			device = d;
			break;
		}
	}
    // fall back to the default camera.
    if( nil == device )
    {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:404 userInfo:@{@"message": @"No camera found."}];
    }
    
    // get the input device
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
    
    
	if( !error ) {
        
        // add the input to the session
        if ( [self.session canAddInput:deviceInput] ){
            [self.session addInput:deviceInput];
        }
        
        // Make a still image output
        self.stillImageOutput = [AVCaptureStillImageOutput new];
//        [stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:AVCaptureStillImageIsCapturingStillImageContext];
        if ( [self.session canAddOutput:self.stillImageOutput] )
            [self.session addOutput:self.stillImageOutput];
        
        // Make a video data output
        self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        
        // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
        NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
                                           [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        [self.videoDataOutput setVideoSettings:rgbOutputSettings];
        [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES]; // discard if the data output queue is blocked
        
        // create a serial dispatch queue used for the sample buffer delegate
        // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
        // see the header doc for setSampleBufferDelegate:queue: for more information
        self.videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
        
        [self.videoDataOutput setSampleBufferDelegate:self queue:self.videoDataOutputQueue];
        
        if ( [self.session canAddOutput:self.videoDataOutput] ){
            [self.session addOutput:self.videoDataOutput];
        }
        
        // get the output for doing face detection.
        [[self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
        
        
        self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        self.previewLayer.backgroundColor = [[UIColor blackColor] CGColor];
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        
        if([self adjustOutputOrientation]  == NO){
            __weak typeof(self) weakSelf = self;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self dismissViewControllerAnimated:YES completion:^{
                    
                    [self throwError:@"It seems your camera orientation is not set properly. Please make sure your iPad is in landscape position and try again." title:nil];
                    
                    [weakSelf.delegate CLFaceDetectionImagePickerDidDismiss: nil blnSuccess:NO];
                    
                }];
            });
            
            return;
        }
        
        CALayer *rootLayer = [self.preView layer];
        [rootLayer setMasksToBounds:YES];
        [self.previewLayer setFrame:[rootLayer bounds]];
        [rootLayer addSublayer:self.previewLayer];
        [self.session startRunning];
        
        self.timerNoFaceDetect = [NSTimer scheduledTimerWithTimeInterval:self.totalCountDownWaitingSecond target:self selector:@selector(noFaceDetected) userInfo:nil repeats:NO];
        
        
    }
	if (error) {
        [self throwError:[error localizedDescription]
                   title:[NSString stringWithFormat:@"Please make sure your front camera is allowed to be accessed. \nYou can check it in Settings. \nFailed with errorCode %d", (int)[error code]]];
		[self teardownAVCapture];
	}
}

// clean up capture setup
- (void)teardownAVCapture
{
    for(AVCaptureInput *input in self.session.inputs){
        [self.session removeInput:input];
    }
    for(AVCaptureOutput *output in self.session.outputs){
        [self.session removeOutput:output];
    }
    [self.session stopRunning];
	self.videoDataOutput = nil;
    self.videoDataOutputQueue = nil;
	[self.previewLayer removeFromSuperlayer];
	self.previewLayer = nil;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    
    
	// get the image
	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
	CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer
                                                      options:(__bridge NSDictionary *)attachments];
	if (attachments) {
		CFRelease(attachments);
    }
    
    // make sure your device orientation is not locked.
	UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    if(!self.blnDisableAutoFaceDetection.intValue){
        NSDictionary *imageOptions = nil;
        
        imageOptions = [NSDictionary dictionaryWithObject:[self exifOrientation:curDeviceOrientation]
                                                   forKey:CIDetectorImageOrientation];
        
        NSArray *features = [self.faceDetector featuresInImage:ciImage
                                                       options:imageOptions];
        
        if(!features.count){
            self.timesDetectFace = 0;
            return;
        }
        
        if(self.timesDetectFace > self.totalFaceDetectionTimes){
            return;
        }
        
        self.timesDetectFace++;
        
        // get the clean aperture
        // the clean aperture is a rectangle that defines the portion of the encoded pixel dimensions
        // that represents image data valid for display.
        CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
        CGRect clap = CMVideoFormatDescriptionGetCleanAperture(fdesc, false /*originIsTopLeft == false*/);
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self drawFaceBoxesForFeatures:features forVideoBox:clap orientation:curDeviceOrientation];
        });

    }else{
        if(self.timesCountDown < 0) return;
        
        self.timesCountDown -= 0.03;
        CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
        CGRect clap = CMVideoFormatDescriptionGetCleanAperture(fdesc, false /*originIsTopLeft == false*/);
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self drawCountDownforVideoBox:clap orientation:curDeviceOrientation];
        });
    }
	   
    if(self.timesDetectFace >= self.totalFaceDetectionTimes ||  self.timesCountDown <= 0){
        [self.timerNoFaceDetect invalidate];
        CIContext *temporaryContext = [CIContext contextWithOptions:nil];
        CGImageRef videoImage = [temporaryContext
                                 createCGImage:ciImage
                                 fromRect:CGRectMake(0, 0,
                                                     CVPixelBufferGetWidth(pixelBuffer),
                                                     CVPixelBufferGetHeight(pixelBuffer))];

        UIImage *picture = [[UIImage imageWithCGImage:videoImage] imageRotatedWithDeviceOrientation:YES];
        
        NSData *compressedData = UIImageJPEGRepresentation(picture, 1.0);
        
        [self doCloseCaptureAndDelegateClientWithData:compressedData];
    }
}

// utility routing used during image capture to set up capture orientation
- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
	AVCaptureVideoOrientation result = AVCaptureVideoOrientationLandscapeLeft;
	if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
		result = AVCaptureVideoOrientationLandscapeRight;
	else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
		result = AVCaptureVideoOrientationLandscapeLeft;
   
	return result;
}
-(BOOL)shouldAutorotate
{
    return [self adjustOutputOrientation];
}
-(BOOL)adjustOutputOrientation
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    if(orientation != UIDeviceOrientationLandscapeLeft && orientation != UIDeviceOrientationLandscapeRight){
        return NO;
    }
    
    [self.previewLayer.connection setVideoOrientation:[self avOrientationForDeviceOrientation:orientation]];
    return YES;
}
- (NSNumber *) exifOrientation: (UIDeviceOrientation) orientation
{
	int exifOrientation;
    /* kCGImagePropertyOrientation values
     The intended display orientation of the image. If present, this key is a CFNumber value with the same value as defined
     by the TIFF and EXIF specifications -- see enumeration of integer constants.
     The value specified where the origin (0,0) of the image is located. If not present, a value of 1 is assumed.
     
     used when calling featuresInImage: options: The value for this key is an integer NSNumber from 1..8 as found in kCGImagePropertyOrientation.
     If present, the detection will be done based on that orientation but the coordinates in the returned features will still be based on those of the image. */
    
	enum {
		PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
		PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			= 2, //   2  =  0th row is at the top, and 0th column is on the right.
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.
		PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.
		PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.
		PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.
		PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.
	};
	
	switch (orientation) {
		case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
			exifOrientation = PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM;
			break;
		case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
//			if (self.isUsingFrontFacingCamera)
            exifOrientation =  PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
//			else
//				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			break;
		case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
//			if (self.isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
//			else
//				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			break;
		case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
		default:
			exifOrientation = PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP;
			break;
	}
    return [NSNumber numberWithInt:exifOrientation];
}

-(void)doCloseCaptureAndDelegateClientWithData: (NSData *)data
{
    __weak typeof(self) weakSelf = self;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self dismissViewControllerAnimated:YES completion:^{
            if(!data){
                [self throwError:@"Sorry, we cannot detect your face." title:nil];
            }
            [weakSelf.delegate CLFaceDetectionImagePickerDidDismiss: data blnSuccess:(data)?YES:NO];
            
        }];
    });
}
-(void)noFaceDetected
{
    [self doCloseCaptureAndDelegateClientWithData:nil];
}


// find where the video box is positioned within the preview layer based on the video size and gravity
+ (CGRect)videoPreviewBoxForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize
{
    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
    CGFloat viewRatio = frameSize.width / frameSize.height;
    
    CGSize size = CGSizeZero;
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        if (viewRatio > apertureRatio) {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (viewRatio > apertureRatio) {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        } else {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
        size.width = frameSize.width;
        size.height = frameSize.height;
    }
	
	CGRect videoBox;
	videoBox.size = size;
	if (size.width < frameSize.width)
		videoBox.origin.x = (frameSize.width - size.width) / 2;
	else
		videoBox.origin.x = (size.width - frameSize.width) / 2;
	
	if ( size.height < frameSize.height )
		videoBox.origin.y = (frameSize.height - size.height) / 2;
	else
		videoBox.origin.y = (size.height - frameSize.height) / 2;
    
	return videoBox;
}

-(void)drawCountDownforVideoBox:(CGRect)clap orientation:(UIDeviceOrientation)orientation
{
    NSArray *sublayers = [NSArray arrayWithArray:[self.previewLayer sublayers]];
	NSInteger sublayersCount = [sublayers count], currentSublayer = 0;
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	
	// hide all the CountDownLayer layers
	for ( CATextLayer *layer in sublayers ) {
		if ( [[layer name] isEqualToString:@"CountDownLayer"] )
			[layer setHidden:YES];
	}
    
    CGSize parentFrameSize = [self.preView frame].size;
    CATextLayer *featureLayer = nil;
    
    // re-use an existing layer if possible
    while ( !featureLayer && (currentSublayer < sublayersCount) ) {
        CATextLayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
        if ( [[currentLayer name] isEqualToString:@"CountDownLayer"] ) {
            featureLayer = currentLayer;
            [currentLayer setHidden:NO];
        }
    }
    
    // create a new one if necessary
    if ( !featureLayer ) {
        featureLayer = [CATextLayer new];
//        [featureLayer setContents:(id)[self.square CGImage]];
        [featureLayer setFont:@"Helvetica-Bold"];
        [featureLayer setFontSize:90];
        [featureLayer setAlignmentMode:kCAAlignmentCenter];
        [featureLayer setForegroundColor:[[UIColor whiteColor] CGColor]];
        [featureLayer setName:@"CountDownLayer"];
        [self.previewLayer addSublayer:featureLayer];
    }
    
    int countDown = @(self.timesCountDown).intValue;
    NSString *strCountDown = (countDown > 0)?[NSString stringWithFormat:@"%d", countDown]:@"Smile";
    [featureLayer setString: strCountDown];
    [featureLayer setFrame:CGRectMake( (parentFrameSize.width-300)/2, (parentFrameSize.height-300)/2, 300, 300)];
    
    
	
	[CATransaction commit];
}

// called asynchronously as the capture output is capturing sample buffers, this method asks the face detector (if on)
// to detect features and for each draw the red square in a layer and set appropriate orientation
- (void)drawFaceBoxesForFeatures:(NSArray *)features forVideoBox:(CGRect)clap orientation:(UIDeviceOrientation)orientation
{
	NSArray *sublayers = [NSArray arrayWithArray:[self.previewLayer sublayers]];
	NSInteger sublayersCount = [sublayers count], currentSublayer = 0;
	NSInteger featuresCount = [features count], currentFeature = 0;
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	
	// hide all the face layers
	for ( CALayer *layer in sublayers ) {
		if ( [[layer name] isEqualToString:@"FaceLayer"] )
			[layer setHidden:YES];
	}
	
	if ( featuresCount == 0) {
		[CATransaction commit];
		return; // early bail.
	}
    
	CGSize parentFrameSize = [self.preView frame].size;
	NSString *gravity = [self.previewLayer videoGravity];
	CGRect previewBox = [CLFaceDetectionImagePickerViewController videoPreviewBoxForGravity:gravity
                                                                 frameSize:parentFrameSize
                                                              apertureSize:clap.size];
	
	for ( CIFaceFeature *ff in features ) {
		CGRect faceRect = [ff bounds];
		// scale coordinates so they fit in the preview box, which may be scaled
		CGFloat widthScaleBy = previewBox.size.width / clap.size.width;
		CGFloat heightScaleBy = previewBox.size.height / clap.size.height;
		faceRect.origin.x *= widthScaleBy;
		faceRect.origin.y *= heightScaleBy;
        
        faceRect = CGRectOffset(faceRect, previewBox.origin.x, previewBox.origin.y);
		
		CALayer *featureLayer = nil;
		
		// re-use an existing layer if possible
		while ( !featureLayer && (currentSublayer < sublayersCount) ) {
			CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
			if ( [[currentLayer name] isEqualToString:@"FaceLayer"] ) {
				featureLayer = currentLayer;
				[currentLayer setHidden:NO];
			}
		}
		
		// create a new one if necessary
		if ( !featureLayer ) {
			featureLayer = [CALayer new];
			[featureLayer setContents:(id)[self.square CGImage]];
			[featureLayer setName:@"FaceLayer"];
			[self.previewLayer addSublayer:featureLayer];
		}
		[featureLayer setFrame:faceRect];
		currentFeature++;
	}
	
	[CATransaction commit];
}


//Throw Error
-(void) throwError:(NSString *)error title:(NSString *)title
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: title
                                                        message:error
                                                       delegate:nil
                                              cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil];
    [alertView show];
}

@end
