#import <Foundation/Foundation.h>

@import UIKit;
@import AVFoundation;

@interface DDYCameraManager : NSObject

/** 视屏格式 默认 AVFileTypeMPEG4 */
@property (nonatomic, strong) AVFileType videoType;
/** 拍照回调 */
@property (nonatomic, copy) void (^takeFinishBlock)(UIImage *image);
/** 录制回调 */
@property (nonatomic, copy) void (^recordFinishBlock)(NSURL *videoURL);
/** 光强检测 */
@property (nonatomic, copy) void (^brightnessValueBlock)(CGFloat brightnessValue);
/** 会话质量 默认AVCaptureSessionPresetHigh */
@property (nonatomic, copy) NSString *sessionPreset;
/** coreImage滤镜名称 例如@"CIPhotoEffectMono" */
@property (nonatomic, copy) NSString *filterName;

/** 初始化 */
+ (instancetype)ddy_CameraWithContainerView:(UIView *)view;

/** 开启捕捉会话 */
- (void)ddy_StartCaptureSession;

/** 停止捕捉会话 */
- (void)ddy_StopCaptureSession;

/** 切换摄像头 */
- (void)ddy_ToggleCamera;

/** 设置闪光灯模式 */
- (void)ddy_SetFlashMode:(AVCaptureFlashMode)flashMode;

/** 手电筒补光模式 */
- (void)ddy_SetTorchMode:(AVCaptureTorchMode)torchMode;

/** 聚焦/曝光 */
- (void)ddy_FocusAtPoint:(CGPoint)point;

/** 拍照 */
- (void)ddy_TakePhotos;

/** 播放系统拍照声 */
- (void)ddy_palySystemTakePhotoSound;

/** 开始录制视频 */
- (void)ddy_StartRecorder;

/** 结束录制视频 */
- (void)ddy_StopRecorder;

/** 录制重置 */
- (void)ddy_ResetRecorder;

/** 光感系数 */
- (void)ddy_ISO:(BOOL)isMAX;

@end
