//
//  MusicCenterManager.h
//  FanweApp
//
//  Created by 岳克奎 on 16/12/16.
//  Copyright © 2016年 xfg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MusicSuperPlayer.h"
#import "MusicDataManager.h"
@class LrcShowView;
@interface MusicCenterManager : NSObject<QAVAudioDataDelegate>//QAVAudioDataDelegate 互动SDK混音代理
//micdealBuffer 麦克风数据地址
{
    char*                 _micdealBuffer;
}
//C++播放器控制中心
@property(nonatomic,strong)MusicSuperPlayer *superPlayer;
//音乐数据处理中心
@property(nonatomic,strong)MusicDataManager *musicDataManager;
#pragma mark ------------------------------------life cycle -----------------------------------------------------
+ (MusicCenterManager *)shareManager;

#pragma mark  ----------------------------------- 音 乐 控制 逻辑层 部 分（Logic） -----------------------------------

#pragma mark - music  play 音乐 播放（L）
/**
 * @brief: 超级播放器播放
 *
 * @use  : 使用前提 采样率+路径
 */
-(void)superPlayerPlayOfSamplerateNum:(int)samplerateNum
                     musicFilePathStr:(NSString *)musicFilePathStr;

#pragma mark - music  stop or resume 音乐暂停和恢复播放 （C）
/**
 * @brief: 音乐暂停和恢复播放
 *
 * @return: YES开始播放  NO：播放暂停或没法播放
 *
 *@use： btn控制播放
 */
-(BOOL)superPlayerStopOrResumePlay;

#pragma mark- music play resume 音乐播放器 暂停（单一功能）（L）
/**
 * @brief: 音乐播放 暂停（单一功能）
 *
 * @return: YES:代表暂停操作成功 NO:代表操作失败
 *
 * @use: 只是单独需要 暂停
 */
-(BOOL)superPlayerStopPlayingByMusicCneterManager;

#pragma mark- music play resume 音乐播放器恢复 （单一功能）（L）
/**
 * @brief: 音乐播放暂停后恢复播放
 *
 * @return: YES:代表暂停操作成功 NO:代表操作失败
 *
 * @use: 只是单独 音乐播放器恢复
 */
-(BOOL)superPlayerResumePlayingByMusicCneterManager;

#pragma mark  -----------------------------------  音 乐 UI层 部 分 （UI）-----------------------------------
#pragma mark -选择音乐界面的加载（UI）
/**
 * @brief: 选择音乐界面的加载
 *
 * @use:选择音乐btn执行
 */
-(void)showMuisChoseVCOnSuperVC:(UIViewController *)superViewController
                    inSuperView:(UIView *)superView
                          frame:(CGRect)frame
                     completion:(void(^)(BOOL finished))block;

#pragma mark - music  加载歌词（LRC）（Data）
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
                       complete:(void(^)(BOOL finished,NSMutableArray *lrcModelMArray,NSMutableArray *lrcPointTimeStrArray))block;
#pragma mark - 音乐 歌词 逐字 显示的view（UI）（LRC）
/**
 * @brief:音乐 歌词 逐字 显示的view（UI）
 *
 * discussion: 1.代码为啥写在这里，还是想通过 音乐控制中心去完成 各个模块的交互
 *             2。lrcView 看成已经集成UI，我们只需要通过音乐控制中心去调度加载就ok！
 *             3.只是集成 2行（上下行）模式
 *
 * @use:VC或view需要显示 两行Lrc
 */
//-(LrcShowView *)showLrcViewInSuperView:(UIView *)superView
//                               ofFrame:(CGRect)cgFrame
//                  musicLRCofLRCDataStr:(NSString *)musicLRCofLRCDataStr
//                          musicNameStr:(NSString *)musicNameStr
//                        musicSingerStr:(NSString *)musicSingerStr;
-(void)showMusicSuperPlayerUIViewControllerOnSuperViewController:(UIViewController *)superViewController
                                                           frame:(CGRect)frame
                                            musicLRCofLRCDataStr:(NSString *)musicLRCofLRCDataStr
                                                    musicNameStr:(NSString *)musicNameStr
                                                  musicSingerStr:(NSString *)musicSingerStr;
#pragma mark - YunMusic ---------------------------------  云 音乐 部分 --------------------------------
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
#pragma mark -Yun player  player
-(void)showYunMusicPlayerUIViewControllerOnSuperViewController:(UIViewController *)superViewController
                                                   inSuperView:(UIView *)superView
                              musicPlayerUIViewControllerFrame:(CGRect)musicPlayerUIViewControllerFrame
                                                      complete:(void(^)(BOOL finished,
                                                                        YunMusicPlayVC *yunMusicViewController))block;









@end
