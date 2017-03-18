//
//  CLFaceDetectionViewController.h
//
//  Created by caesar on 26/02/14.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CLCaptureDevicePosition) {
    CLCaptureDevicePositionBack                = 1,
    CLCaptureDevicePositionFront               = 2
} NS_AVAILABLE(10_7, 4_0);


// Keys for customize the pickerView behavior
extern NSString *const CLTotalDetectCountDownSecond;    //Total length of waiting period for face detection - Default: 10
extern NSString *const CLFaceDetectionSquareImageName;  //Image name for the face detection square image    - Default: CameraSquare
extern NSString *const CLFaceDetectionTimes;            //Continually detecting face times, this will be helpful to make sure the people are not shaking his head by purpose in order to give u a not-clear image       - Default: 5
extern NSString *const CLCameraPosition;                //Choose which camera you want to use, CLCaptureDevicePositionBack or CLCaptureDevicePositionFront  -Default: CLCaptureDevicePositionFront

@protocol CLFaceDetectionImagePickerDelegate <NSObject>
-(void)CLFaceDetectionImagePickerDidDismiss: (NSData *)data blnSuccess:(BOOL)blnSuccess;
@optional
-(NSDictionary *)faceDetectionBehaviorAttributes;       //Optional Function, Set the FaceDetectionPlugin behavior attributes by using above keys



@end




@interface CLFaceDetectionImagePickerViewController : UIViewController

@property (nonatomic, weak) id<CLFaceDetectionImagePickerDelegate> delegate;
@end
