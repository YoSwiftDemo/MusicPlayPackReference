//
//  MusicCenterManager.m
//  FanweApp
//
//  Created by 岳克奎 on 16/12/16.
//  Copyright © 2016年 xfg. All rights reserved.
//

#import "MusicCenterManager.h"

@implementation MusicCenterManager
#pragma mark -------------------------------------life cycle -------------------------------------
#pragma mark - 音乐控制中  单利
/**
 * @brief: 音乐控制中 单利
 *
 * @discussion:我的想法是，用单利管理，这样能够通过C++的player对应的控制器来控制。播放，暂停。如果不这样，需要频繁的
 */
static MusicCenterManager *signleton = nil;
+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        signleton = [super allocWithZone:zone];
    });
    return signleton;
}
+ (MusicCenterManager *)shareManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        signleton = [[self alloc] init];
    });
    return signleton;
}
+ (id)copyWithZone:(struct _NSZone *)zone
{
    return signleton;
}

+ (id)mutableCopyWithZone:(struct _NSZone *)zone
{
    return signleton;
}
#pragma mark  ----------------------------------- 音 乐 控制 逻辑层 部 分（Logic） -----------------------------------

#pragma mark - music  play  音乐播放（L）（Public）
/**
 * @brief: 超级播放器播放
 *
 * @prama: samplerateNum 采样率
 * @prama: musicFilePathStr  音乐路径Str（不完整，需要再处理下）
 *
 * @Step: 启动音乐播放器
 * @Step：通过设置SDK混音代理，实现代理方法，将相应的内存里的数据 不断传入SDK混音方法里
 * @Step： AVAudioSession  输出设置
 * @Step: AVAudioSession   播放
 * @use  : 使用前提 采样率+路径
 */
-(void)superPlayerPlayOfSamplerateNum:(int)samplerateNum musicFilePathStr:(NSString *)musicFilePathStr{
    if(!musicFilePathStr){
        return;
    }
    [self.superPlayer musicSuperPlayerPlayWithMudicPathStr:[self searchFullFilePathOfMusicFilePathStr:musicFilePathStr]
                                                samplerate:samplerateNum];
    [self copyMusicPlayDataToSDKHD];
    // 必须加输出
   [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryMultiRoute error:nil];//多种输入输出，例如可以耳机、USB设备同时播放
    //iOS 10下 音乐播放必须需要加
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                           error:nil];
}
#pragma mark - 音乐路径处理（L）
/**
 * @brief: 音乐路径处理,获取完整的音乐文件地址str
 *
 */
-(NSString*)searchFullFilePathOfMusicFilePathStr:(NSString *)musicFilePathStr
{
    NSString *str = [NSString stringWithFormat:@"/Documents/%@/%@",@"music",musicFilePathStr];
    if (str && ![str isEqualToString:@""]) {
        return [NSHomeDirectory() stringByAppendingString:str];
    }
    return NSHomeDirectory();
}
#pragma mark - music player stop or resume 音乐暂停和恢复播放(L)（Public）
/**
 * @brief: 音乐暂停和恢复播放
 *
 * @return: YES开始播放  NO：播放暂停或没法播放
 *
 * @discussion：1.音乐的 播放与暂停，在音乐播放功能VC上，自由切换 暂停 恢复播放
 *             2.因为内部实现对音乐播放状态的判断，所以这个方法比较爽
 *             3.方法的具体实现在 音乐控制器下的音乐播放器调C++方法来实现
 *
 *@use：音乐播放功能VC上btn控制播放，其他需要暂停或恢复播放
 */
-(BOOL)superPlayerStopOrResumePlay{
    if(self.superPlayer){
      return  [self.superPlayer musicSuperPlayerStopOrPlay];
    }
    return NO;
}
#pragma mark - music player stop 音乐播放 暂停(L)（Public）
/**
 * @brief: 音乐播放 暂停
 *
 * @discussion: 暂停单独写个
 *
 * @use：只是单独 调暂停
 *
 */
-(BOOL)superPlayerStopPlayingByMusicCneterManager{
    if(self.superPlayer){
        return  [self.superPlayer superPlayerStopPlaying];
    }
    return NO;
}
#pragma mark - music player resume 音乐播放 恢复 播放(L)（Public）
/**
 * @brief: 音乐播放 恢复 播放
 *
 * @discussion: 恢复 播放 单独写个
 *
 * @use：只是单独 调恢复
 *
 */
-(BOOL)superPlayerResumePlayingByMusicCneterManager{
    if(self.superPlayer){
        return  [self.superPlayer superPlayerResumePlaying];
    }
    return NO;
}
#pragma mark - 音乐混音代理处理（SDK Deleagte ）
/**
 * @brief:音乐混音（互动需要混音）（SDK Deleagte Method）
 *
 *
 * @discussion: 音乐混音 需要将数据混入某些SDKSDK，这个操作，应该放在对应的播放器VC里面。所以写在播放之后面就ok。恢复播放等需不需要加？？？有待测试？？？？？
 *
 */
-(void)copyMusicPlayDataToSDKHD{
    //麦克风 上传内存的数据  内存对齐处理
    if ( posix_memalign((void **)&_micdealBuffer, 16, 4096 + 128) != 0 )
    {
        NSLog( @"posix_memalign mem" );
        return;
    }
    //腾讯音频透传....
    QAVAudioCtrl *hdAudioCtrl= [[ILiveSDK getInstance] getAVContext].audioCtrl;
    //设置代理
    [hdAudioCtrl setAudioDataEventDelegate:self];
    //打开扬声器
    //[[[ILiveSDK getInstance] getAVContext].audioCtrl enableSpeaker:YES];
    //注册音频数据类型的回调 要注册监听的音频数据源类型，具体参考QAVAudioDataSourceType
    //1.麦克风预处理
    [hdAudioCtrl registerAudioDataCallback:QAVAudioDataSource_VoiceDispose];//麦克风预处理
    //2. 发送混音输入
    [hdAudioCtrl registerAudioDataCallback:QAVAudioDataSource_MixToSend];//发送混音输入（必须，不然不能混音）
    // 音频帧描述。
    struct QAVAudioFrameDesc musicFrameDesc;
    //频道 单双
    musicFrameDesc.ChannelNum = 2;
    //采样率  默认44100
    musicFrameDesc.SampleRate = MUSIC_SAMPLERATE;
    //节拍
    musicFrameDesc.Bits = 16;
    //设置音频格式参数   QAVAudioDataSource_MixToSend->发送混音输入
    [hdAudioCtrl setAudioDataFormat:QAVAudioDataSource_MixToSend
                               desc:musicFrameDesc];
    //走麦克风通道
    // [[[ILiveSDK getInstance] getAVContext].audioCtrl enableLoopBack:YES];

}
#pragma mark - 音乐混音数据保存（SDK Deleagte Method）
/**
 *  @brief:主要用于保存直播中的音频数据 （SDK Deleagte Method）
 *
 *  @use：?
 */
-(QAVResult) audioDataComes:(QAVAudioFrame *)audioFrame
                       type:(QAVAudioDataSourceType)type{
    return QAV_OK;
}
#pragma mark - 音乐混音（SDK Deleagte Method）
/**
 *  @brief:混音输入（Mic和Speaker）的主要回调 （SDK Deleagte Method）
 *
 *  @use： 音乐 混音
 */
- (QAVResult)audioDataShouInput:(QAVAudioFrame *)audioFrame
                           type:(QAVAudioDataSourceType)type
{
  

    NSUInteger      tcneeds = audioFrame.buffer.length;
    NSInteger       samplerate = audioFrame.desc.SampleRate;
    //audioDataShouInput need more size buffer
    if( tcneeds > 3840 )
    {
        return QAV_OK;
    }
    if( samplerate  == 0 )
    {
        return QAV_OK;
    }
    int needsize = 0;//根据这边的大小,计算那边的
    int mysapmes = MUSIC_SAMPLERATE;
    if( mysapmes == 0 )
    {
        return QAV_OK;
    }
    //convert sampels needsize
    needsize = (tcneeds / (float)samplerate) * mysapmes;
    if( needsize > 4096 )
    {
        return QAV_OK;
    }
    needsize =(int) audioFrame.buffer.length;
    // 调缓冲数据
    int copyed  = [self.superPlayer copyOutBuffer: _micdealBuffer buffersize:needsize];
    if( copyed  )
    {
        //混音
        memcpy( (void *) [audioFrame.buffer bytes] ,  _micdealBuffer , copyed);
    }
    return QAV_OK;
}
#pragma mark - 音乐混音变声（SDK Deleagte Method）
/**
 *  @brief:主要用作作变声处理（SDK Deleagte Method）
 *
 *  @use：?
 */
- (QAVResult)audioDataDispose:(QAVAudioFrame *)audioFrame type:(QAVAudioDataSourceType)type
{
    return QAV_OK;
}
#pragma mark  ----------------------------------- 音 乐 UI层 部 分 -----------------------------------

#pragma mark -选择音乐界面的加载 (UI)（Public）
/**
 * @brief: 选择音乐界面的加载
 *
 * @prama: superViewController  为 FWLiveServiceController
 * @prama: superView
 * @prama: frame
 * @prama: block
 *
 *
 * @use:音乐选择界面加载
 */
-(void)showMuisChoseVCOnSuperVC:(UIViewController *)superViewController
                    inSuperView:(UIView *)superView
                          frame:(CGRect)frame
                     completion:(void(^)(BOOL finished))block{
    //创建音乐选择VC
    choseMuiscVC *choseMuiscViewController = [[choseMuiscVC alloc]initWithNibName:@"choseMuiscVC"
                                                                           bundle:nil];
    //frame
    choseMuiscViewController.view.frame = frame;
    //加载到VC上
    if (superViewController) {
        [superViewController addChildViewController:choseMuiscViewController];
    };
    //加载到View上
    if (superView) {
        [superViewController.view addSubview:choseMuiscViewController.view];
        [superViewController.view bringSubviewToFront:choseMuiscViewController.view];
    }
    NSLog(@"dhsddfsjkdksfkjfsdfk=========== %@",NSStringFromCGRect(choseMuiscViewController.view.frame));
    //动画弹出
    choseMuiscViewController.view.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1);
    //x和y的最终值为1
    [UIView animateWithDuration:1.0
                     animations:^{
                         choseMuiscViewController.view.layer.transform = CATransform3DMakeScale(1, 1, 1);
                         
                     }
                     completion:^(BOOL finished) {
                         //动画完成
                         if (block) {
                             block(finished);
                         }
                     }];
    //如果选择了音乐 block把modle传走
    __weak choseMuiscVC *weak_choseMuiscVC = choseMuiscViewController;
    choseMuiscViewController.mitblock = ^(musiceModel* chosemusic ){
        
        //加载音乐界面
        // 2.0 音乐 测试(yue)
        
        // 管理中心
        MusicCenterManager *musicCenterManager = [MusicCenterManager shareManager];
        

        //加载播放器功能UIVC
        [musicCenterManager showMusicSuperPlayerUIViewControllerOnSuperViewController:superViewController
                                                                                frame:CGRectMake(0,SUPER_PLAYER_UIVC_FRAME_Y, SCREEN_WIDTH, SUPER_PLAYER_UIVC_FRAME_HEIGHT)
                                                                 musicLRCofLRCDataStr:chosemusic.mLrc_content
                                                                         musicNameStr:chosemusic.mAudio_name
                                                                       musicSingerStr:chosemusic.mArtist_name];
        [musicCenterManager superPlayerPlayOfSamplerateNum:44100
                                          musicFilePathStr:chosemusic.mFilePath];
        //音乐选择界面移除
        [weak_choseMuiscVC removeFromParentViewController];
        [weak_choseMuiscVC.view removeFromSuperview];
    };
}
#pragma mark - music  加载歌词(UI)
/**
 * @ brief:加载歌词
 *
 * @prama : lrcDataStr  歌词
 * @prama : mDic 歌词 名信息
 * @prama : block      finished   lrcModelMArray  相当于我么你的歌词数据源
 *
 * @ use  : 把歌词给管理中心，管理中心自动调给数据层解析数据，然后把数据 返回给对应的对象
 */
-(void)showMusicLRCofLRCDataStr:(NSString *)lrcDataStr
                   musicNameStr:(NSString *)musicNameStr
                 musicSingerStr:(NSString *)musicSingerStr
                       complete:(void(^)(BOOL finished,
                                         NSMutableArray *lrcModelMArray,
                                         NSMutableArray *lrcPointTimeStrArray))block{
    // 数据层处理了数据生成 lrcmode返回给控制中心     
    [[MusicDataManager shareManager] analysisLrcStrOfMusicLRCDataStr:lrcDataStr
                                          musicNameStr:musicNameStr
                                        musicSingerStr:musicSingerStr
                                             complete:^(BOOL finished,
                                                        NSMutableArray *lrcModelMArray,
                                                        NSMutableArray *lrcPointTimeStrArray) {
                                                 if (block) {
                                                     block(finished,
                                                           lrcModelMArray,
                                                           lrcPointTimeStrArray);
                                                 }
       
    }];

}
#pragma mark - 音乐 歌词 逐字 显示的view（UI）
/**
 * @brief:音乐 歌词 逐字 显示的view（UI）
 *
 * discussion: 1.代码为啥写在这里，还是想通过 音乐控制中心去完成 各个模块的交互??????????
 *             2。lrcView 看成已经集成UI，我们只需要通过音乐控制中心去调度加载就ok！
 *             3.只是集成 2行（上下行）模式
 *
 * @return     用return比blcok好写吧  以为每次选择歌曲后，我们需要重新加载歌词和歌曲。当lrcView存在，也就没必要再创建
 *
 * @use:VC或view需要显示 两行Lrc
 */
-(void)showMusicSuperPlayerUIViewControllerOnSuperViewController:(UIViewController *)superViewController
                                                           frame:(CGRect)frame
                                            musicLRCofLRCDataStr:(NSString *)musicLRCofLRCDataStr
                                                    musicNameStr:(NSString *)musicNameStr
                                                  musicSingerStr:(NSString *)musicSingerStr{
    
    //判断是否存在
//    MusicSuperPlayerVC *musicPlayerUIVC;
    for(UIViewController *oneViewController in superViewController.childViewControllers){
        if ([oneViewController isKindOfClass:[MusicSuperPlayerVC class]]) {
            [oneViewController removeFromParentViewController];
            [oneViewController.view removeFromSuperview];
            
        }
    }
//    //如果不存在
//    if (!musicPlayerUIVC) {
        //创建 音乐播放器UIVC
    MusicSuperPlayerVC *musicPlayerUIVC= [[MusicSuperPlayerVC  alloc]initWithNibName:@"MusicSuperPlayerVC"
                                                              bundle:nil];

  
    //liveServiceController
    musicPlayerUIVC.liveServiceController = (FWLiveServiceController *)superViewController;
    //将 音乐播放器UIVC 作为子Vc 加到 直播间 && 置于最前面
    [superViewController addChildViewController:musicPlayerUIVC];
    [superViewController.view addSubview:musicPlayerUIVC.view];
    [superViewController.view bringSubviewToFront:musicPlayerUIVC.view];
    //fram
    musicPlayerUIVC.view.frame = frame;
    
    // 将数据加载给lrcView 方法： 控制中心-->将歌词穿进去
     __weak typeof(self)weak_Self = self;
    __weak MusicSuperPlayerVC *weak_musicPlayerUIVC = musicPlayerUIVC;
    [weak_Self showMusicLRCofLRCDataStr:musicLRCofLRCDataStr
                           musicNameStr:musicNameStr
                         musicSingerStr:musicSingerStr
                               complete:^(BOOL finished,
                                          NSMutableArray *lrcModelMArray,
                                          NSMutableArray *lrcPointTimeStrArray) {
                                   //歌词处理完毕 得到数据  将处理好的数据 传给lrcView，等待歌词开启的时候使用
                                   weak_musicPlayerUIVC.lrcView.lrcUpLab.text = [NSString stringWithFormat:@"歌曲:%@ 演唱:%@",musicNameStr,musicSingerStr];
                                   NSLog(@"qewewq ==========为全文======%@",weak_musicPlayerUIVC.lrcView.lrcUpLab.text);
                                   weak_musicPlayerUIVC.lrcView.lrcDowmLab.text =@"   ";
                                   weak_musicPlayerUIVC.lrcView.lrcModelMArray = lrcModelMArray;
                                   weak_musicPlayerUIVC.lrcView.lrcTimePointMArray = lrcPointTimeStrArray;
                               }];
    // 歌曲当前的最新基本信息--->C++代理 --->播放器管理器-->音乐管理中心-->UI层
    weak_Self.superPlayer.musicSuperPlayerInfoBlock =^(CGFloat musicTotalTime,
                                                       CGFloat musicCurrentTime,
                                                       CGFloat MusicPersent){
        //UI层 lrcshowView 要随着C++播放器的播放器数据更新，老更新自个的UI数据
        [ weak_musicPlayerUIVC.lrcView setCurrentTime:musicCurrentTime
                                       musicTotalTime:musicTotalTime
                                              present:MusicPersent];
    };
    
}
#pragma mark - YunMusic ---------------------------------  云 音乐 部分 ---------------------------------------------
#pragma mark -public  methods

#pragma mark -public  methods --------------------------云 音乐 公有方法区域  ------------------------------
/**
 *  云 音乐 部分
 *
 * @discussion: 1.云其实基本与 重构的互动音乐 基本相似。重构时候我尽可能降低耦合性，为了借用互动UI层+管理层等重构云音乐。暂时以修改为主吧
 *
 * @Step：LRC  LRC view沿用LrcShowView xib动态桥接过去
 * @Step： 歌词数据  把歌词 给  上面《 music  加载歌词  》这个方法
 *
 */


#pragma mark -Yun playerVC
//#pragma mark -Yun player  player
///**
// *  @brief:云 音乐 部分
// *
// *
// * @discussion: 原本应该是。+方法调运播放器UI的创建。但是让他们再绕道走这里，为的是以后，加载播放器UIVC无非就是传父视图+音乐model 也没啥了。
// *
// */
//-(void)showYunMusicPlayerUIViewControllerOnSuperViewController:(UIViewController *)superViewController
//                                                   inSuperView:(UIView *)superView
//                              musicPlayerUIViewControllerFrame:(CGRect)musicPlayerUIViewControllerFrame
//                                                      complete:(void(^)(BOOL finished,
//                                                                       YunMusicPlayVC *yunMusicViewController))block{
//    
//    
//    
//
//    if(block){
//        block(YES,music_VC);
//    }
//}











#pragma mark ------------------------------------------ set/get  ----------------------------------------
// superPlager  C++播放器管理中心
-(MusicSuperPlayer *)superPlayer{
    if (!_superPlayer) {
        _superPlayer = [MusicSuperPlayer shareManager];
    }
    return _superPlayer;
}
//musicDataManager 数据层管理中心
-(MusicDataManager *)musicDataManager{
    if (!_musicDataManager) {
        _musicDataManager = [MusicDataManager shareManager];
    }
    return _musicDataManager;
}
@end
