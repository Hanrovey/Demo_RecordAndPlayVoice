//
//  CXHRecordView.m
//  Demo_RecordAndPlayVoice
//
//  Created by Ihefe_Hanrovey on 2016/11/3.
//  Copyright © 2016年 Ihefe_Hanrovey. All rights reserved.
//

#import "CXHRecordView.h"
#import "CXHRecordTool.h"
#import "AFNetworking.h"
#import "STKAudioPlayer.h"
#import "SampleQueueId.h"

@interface CXHRecordView () <CXHRecordToolDelegate>

/** 播放工具 */
@property (nonatomic, strong) STKAudioPlayer* audioPlayer;

/** 录音工具 */
@property (nonatomic, strong) CXHRecordTool *recordTool;

/** 录音时的图片 */
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

/** 录音按钮 */
@property (weak, nonatomic) IBOutlet UIButton *recordBtn;

/** 播放按钮 */
@property (weak, nonatomic) IBOutlet UIButton *playBtn;

@property(nonatomic, strong) NSString *urlPlay;
@end

@implementation CXHRecordView

+ (instancetype)recordView {
    
    CXHRecordView *recordView = [[[NSBundle mainBundle] loadNibNamed:@"CXHRecordView" owner:nil options:nil] lastObject];
    
    recordView.recordTool = [CXHRecordTool sharedRecordTool];
    // 初始化监听事件
    [recordView setup];
    
    return recordView;
}

- (STKAudioPlayer *)audioPlayer
{
    if (!_audioPlayer)
    {
        _audioPlayer = [[STKAudioPlayer alloc] initWithOptions:(STKAudioPlayerOptions){ .flushQueueOnSeek = YES, .enableVolumeMixer = NO, .equalizerBandFrequencies = {50, 100, 200, 400, 800, 1600, 2600, 16000} }];
        _audioPlayer.meteringEnabled = YES;
        _audioPlayer.volume = 1;
    }
    return _audioPlayer;
}

- (void)setup {
    
    self.recordBtn.layer.cornerRadius = 10;
    self.playBtn.layer.cornerRadius = 10;
    
    [self.recordBtn setTitle:@"按住 说话" forState:UIControlStateNormal];
    [self.recordBtn setTitle:@"松开 结束" forState:UIControlStateHighlighted];
    
    
    self.recordTool.delegate = self;
    // 录音按钮
    [self.recordBtn addTarget:self action:@selector(recordBtnDidTouchDown:) forControlEvents:UIControlEventTouchDown];
    [self.recordBtn addTarget:self action:@selector(recordBtnDidTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [self.recordBtn addTarget:self action:@selector(recordBtnDidTouchDragExit:) forControlEvents:UIControlEventTouchDragExit];
    
    // 播放按钮
    [self.playBtn addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - 录音按钮事件
// 按下
- (void)recordBtnDidTouchDown:(UIButton *)recordBtn {
    [self.recordTool startRecording];
}

// 点击
- (void)recordBtnDidTouchUpInside:(UIButton *)recordBtn {
    double currentTime = self.recordTool.recorder.currentTime;
    NSLog(@"%lf", currentTime);
    if (currentTime < 2) {
        
        self.imageView.image = [UIImage imageNamed:@"mic_0"];
        [self alertWithMessage:@"说话时间太短"];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            [self.recordTool stopRecording];
            [self.recordTool destructionRecordingFile];
        });
    } else {
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            [self.recordTool stopRecording];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = [UIImage imageNamed:@"mic_0"];
            });
        });
        // 已成功录音
        NSLog(@"已成功录音,录音文件地址---%@",self.recordTool.recorder.url.absoluteString);
        
        //        NSString *string = self.recordTool.recorder.url.absoluteString;
        //        NSString *urlString = [string substringFromIndex:7];
        //        NSURL *fileUrl = [NSURL URLWithString:urlString];
        //
        //        NSURL *mp3Url = [self transformCAFToMP3:fileUrl];
        
        
        
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html",@"image/jpeg", nil];
        NSMutableDictionary *para = [NSMutableDictionary dictionary];
        para[@"action"] = @"999";
        para[@"appkey"] = @"e768833709b928e9f9ab3880d57abeb6";
        para[@"uid"] = @"56dfcb079c9e41987ac5272c";
        para[@"device_type"] = @"ios";
        para[@"video"] = @"xxxxx.mp3";
        [manager POST:@"http://push.hjourney.cn/api.php?c=Index2" parameters:para constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            //              application/octer-stream   audio/mpeg video/mp4   application/octet-stream
            
            //            NSLog(@"mp3url--------   %@",mp3Url);
            [formData appendPartWithFileURL:self.recordTool.recorder.url name:@"video" fileName:@"xxx.mp3" mimeType:@"application/octet-stream" error:nil];
            
        } progress:^(NSProgress * _Nonnull uploadProgress) {
            
            float progress = 1.0 * uploadProgress.completedUnitCount / uploadProgress.totalUnitCount;
            NSLog(@"上传进度-----   %f",progress);
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            NSLog(@"上传成功 %@",responseObject);
            
            NSDictionary *dic = (NSDictionary *)responseObject;
            NSDictionary *dict = dic[@"data"];
            NSString *url = dict[@"url"];
            
            NSLog(@"打印 url  --- %@",url);
            [[NSUserDefaults standardUserDefaults] setObject:url forKey:@"url"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"上传失败 %@",error);
        }];
    }
}


- (IBAction)playHttpClick:(UIButton *)sender
{
    [self playHttp:nil];
}

- (IBAction)playLocalClick:(id)sender
{
    [self playLocal:nil];
}



#pragma mark - 播放http
- (void)playHttp:(NSString *)urlString
{
    //    NSURL *url = [NSURL URLWithString:@"http://www.hjourney.cn/onemq/Uploads/Attach/2016-11-03/14781584937kbn0K.mp3"];
    
    NSString *str = [[NSUserDefaults standardUserDefaults] objectForKey:@"url"];
    NSURL *url = [NSURL URLWithString:str];
    
    STKDataSource *dataSource = [STKAudioPlayer dataSourceFromURL:url];
    
    [self.audioPlayer setDataSource:dataSource withQueueItemId:[[SampleQueueId alloc] initWithUrl:url andCount:0]];
}

- (void)playLocal:(NSString *)urlString
{
    NSString* path = [[NSBundle mainBundle] pathForResource:@"11" ofType:@"mp3"];
    NSURL* url = [NSURL fileURLWithPath:path];
    
    STKDataSource* dataSource = [STKAudioPlayer dataSourceFromURL:url];
    
    [self.audioPlayer setDataSource:dataSource withQueueItemId:[[SampleQueueId alloc] initWithUrl:url andCount:0]];
}

// 手指从按钮上移除
- (void)recordBtnDidTouchDragExit:(UIButton *)recordBtn {
    self.imageView.image = [UIImage imageNamed:@"mic_0"];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        [self.recordTool stopRecording];
        [self.recordTool destructionRecordingFile];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self alertWithMessage:@"已取消录音"];
        });
    });
    
}

#pragma mark - 弹窗提示
- (void)alertWithMessage:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:message delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil];
    [alert show];
}

#pragma mark - 播放录音
- (void)play {
    [self.recordTool playRecordingFile];
}

- (void)dealloc {
    
    if ([self.recordTool.recorder isRecording]) [self.recordTool stopPlaying];
    
    if ([self.recordTool.player isPlaying]) [self.recordTool stopRecording];
    
}

#pragma mark - CXHRecordToolDelegate
- (void)recordTool:(CXHRecordTool *)recordTool didstartRecoring:(int)no {
    
    NSString *imageName = [NSString stringWithFormat:@"mic_%d", no];
    self.imageView.image = [UIImage imageNamed:imageName];
}

@end
