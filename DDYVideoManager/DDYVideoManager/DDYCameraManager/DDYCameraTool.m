#import "DDYCameraTool.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation DDYCameraTool

#pragma mark 转码压缩
+ (void)ddy_CompressVideo:(NSURL *)videoURL presetName:(NSString *)presetName saveURL:(NSURL *)saveURL progress:(void (^)(CGFloat))progress complete:(void (^)(NSError *))complete {
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    NSArray *presetsArray = [AVAssetExportSession exportPresetsCompatibleWithAsset:videoAsset];
    
    void (^compress)(NSString *) = ^(NSString *effectPresetName) {
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:videoAsset presetName:effectPresetName];
        exportSession.shouldOptimizeForNetworkUse = YES;
        exportSession.outputURL = saveURL;
        NSArray *fileTypesArray = exportSession.supportedFileTypes;
        if ([fileTypesArray containsObject:AVFileTypeMPEG4]) {
            exportSession.outputFileType = AVFileTypeMPEG4;
        } else if (fileTypesArray.count > 0) {
            exportSession.outputFileType = [fileTypesArray objectAtIndex:0];
        }
        // 导出
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                    if (complete) complete(nil);
                } else if (exportSession.status == AVAssetExportSessionStatusFailed) {
                    if (complete) complete(exportSession.error);
                } else {
                    if (progress) progress(exportSession.progress);
                }
            });
        }];
    };
    
    if ([presetsArray containsObject:presetName]) {
        compress(presetName);
    } else if ([presetsArray containsObject:AVAssetExportPresetMediumQuality]) {
        compress(AVAssetExportPresetMediumQuality);
    }
}

#pragma mark 截取缩略图
+ (UIImage *)ddy_ThumbnailImageInVideo:(NSURL *)videoURL andTime:(CGFloat)time {
    AVURLAsset *videoAsset = [AVURLAsset assetWithURL:videoURL];
    AVAssetImageGenerator *imgGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:videoAsset];
    imgGenerator.appliesPreferredTrackTransform = YES;
    CMTime requestTime = CMTimeMakeWithSeconds(time, 600);
    CMTime actualTime;
    NSError *error;
    CGImageRef cgImage = [imgGenerator copyCGImageAtTime:requestTime actualTime:&actualTime error:&error];
    if (error) {
        return nil;
    }
    CMTimeShow(actualTime);
    UIImage *thumbnailImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return thumbnailImage;
}

#pragma mark 更改速度 [NSURL fileURLWithPath:videoPath]
- (void)ddy_VideoSpeed:(CGFloat)speed video:(NSURL *)videoURL progress:(void (^)(CGFloat))progress complete:(void (^)(NSError *))complete {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AVURLAsset *videoAsset = [AVURLAsset assetWithURL:videoURL];
        // 视频混合
        AVMutableComposition *composition = [AVMutableComposition composition];
        // 视频轨道
        AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        // 音频轨道
        AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        // 视频的方向
        CGAffineTransform videoTransform = [videoAsset tracksWithMediaType:AVMediaTypeVideo].lastObject.preferredTransform;
        if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) { // NSLog(@"垂直拍摄");
            videoTransform = CGAffineTransformMakeRotation(M_PI_2);
        }else if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) { // NSLog(@"倒立拍摄");
            videoTransform = CGAffineTransformMakeRotation(-M_PI_2);
        }else if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) { // NSLog(@"Home键右侧水平拍摄");
            videoTransform = CGAffineTransformMakeRotation(0);
        }else if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) { // NSLog(@"Home键左侧水平拍摄");
            videoTransform = CGAffineTransformMakeRotation(M_PI);
        }
        // 根据视频的方向同步视频轨道方向
        videoTrack.preferredTransform = videoTransform;
        videoTrack.naturalTimeScale = 600;
        CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake(videoAsset.duration.value, videoAsset.duration.timescale));
        // 插入视频轨道
        [videoTrack insertTimeRange:timeRange ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject] atTime:kCMTimeZero error:nil];
        // 插入音频轨道
        [audioTrack insertTimeRange:timeRange ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] firstObject] atTime:kCMTimeZero error:nil];
        // 适配视频速度比率   0.2:快速x5  4:慢速x4
        CGFloat scale = 1.0;
        if (speed >= 0.1 && speed <= 10.) {
            scale = speed;
        }
        // 根据速度比率调节音频和视频
        [videoTrack scaleTimeRange:timeRange toDuration:CMTimeMake(videoAsset.duration.value * scale , videoAsset.duration.timescale)];
        [audioTrack scaleTimeRange:timeRange toDuration:CMTimeMake(videoAsset.duration.value * scale, videoAsset.duration.timescale)];
        // 配置导出
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPreset1280x720];
        // 导出视频的临时保存路径
        NSString *newLastComponent = [NSString stringWithFormat:@"Export/%@", videoURL.absoluteString.lastPathComponent];
        NSString *orignalPath = [videoURL.absoluteString stringByDeletingLastPathComponent];
        NSString *exportPath = [orignalPath stringByAppendingPathComponent:newLastComponent];
        NSURL *exportURL = [NSURL fileURLWithPath:exportPath];
        
        // 导出视频的格式 .MOV
        exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        exportSession.outputURL = exportURL;
        exportSession.shouldOptimizeForNetworkUse = YES;
        
        // 导出视频
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                    if (complete) complete(nil);
                } else if (exportSession.status == AVAssetExportSessionStatusFailed) {
                    if (complete) complete(exportSession.error);
                } else {
                    if (progress) progress(exportSession.progress);
                }
            });
        }];
    });
}

   // 将导出的视频保存到相册
- (void)ddy_SaveVideoToAlbum:(NSURL *)videoURL complete:(void (^)(NSError *))complete {
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    if (![library videoAtPathIsCompatibleWithSavedPhotosAlbum:videoURL]) {
        complete(nil);
        return;
    }
    [library writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:^(NSURL *assetURL, NSError *error) {
        complete(error);
    }];
}

#pragma mark 添加背景音乐
+ (void)ddy_AddMusicInVideo:(NSURL *)videoPath music:(NSURL *)musicPath keepOrignalSound:(BOOL)isKeep complete:(void (^)(NSURL *))complete {
    
}

+ (void)ddy_AddWaterMarkInVideo:(NSURL *)videoPath waterMarkImage:(UIImage *)waterImage complete:(void (^)(NSURL *))complete {
    
}

+ (void)ddy_AddWaterMarkInVideo:(NSURL *)videoPath waterMarkString:(UIImage *)waterString complete:(void (^)(NSURL *))complete {
    
}

@end
