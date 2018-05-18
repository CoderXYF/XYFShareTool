//
//  ShareTool.m
//  NewProjects
//
//  Created by Mac on 2018/5/12.
//  Copyright © 2018年 DSOperation. All rights reserved.
//

#import "ShareTool.h"
#import <WXApi.h>
#import <TencentOpenAPI/QQApiInterface.h>
#import <TencentOpenAPI/TencentOAuth.h>
#import <UIView+YYAdd.h>
#import <UIButton+SGImagePosition.h>
#import <LCProgressHUD.h>
#import <UIImageView+WebCache.h>

#define ScreenWidth CGRectGetWidth([UIScreen mainScreen].bounds)
#define ScreenHeight CGRectGetHeight([UIScreen mainScreen].bounds)

@interface ShareTool() {
    TencentOAuth *_tencentOAuth;
    UIImageView *_tempImageView;
}
/// 背景蒙版
@property (weak, nonatomic) UIControl *bgControl;
/// 分享链接
@property (nonatomic, strong) NSString *shareURLString;
/// 分享标题
@property (nonatomic, strong) NSString *shareTitle;
/// 分享描述
@property (nonatomic, strong) NSString *shareDes;
/// 预览图链接
@property (nonatomic, strong) NSString *previewImageURLString;

@end

@implementation ShareTool

//01 提供一个全局的静态变量(对外界隐藏)
static ShareTool *_instance;

//02 重写alloc方法,保证永远只分配一次存储空间
// alloc - > allocWithZone(分配存储空间)
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    //只执行一次+线程安全
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

- (instancetype)init {
    if (self = [super init]) {
        //只执行一次+线程安全
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            self->_tencentOAuth = [[TencentOAuth alloc] initWithAppId:@"your QQ AppID" andDelegate:nil];
        });
    }
    return self;
}

//03 提供类方法
+ (instancetype)sharedInstance {
    return [[self alloc] init];
}

//04 重写copy
- (id)copyWithZone:(NSZone *)zone {
    return _instance;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return _instance;
}

#pragma mark - Share

/// 弹出分享面板
- (void)popShareBoardWithShareURLString:(NSString *)shareURLString shareTitle:(NSString *)shareTitle shareDes:(NSString *)shareDes previewImageURLString:(NSString *)previewImageURLString {
    self.shareURLString = shareURLString;
    self.shareTitle = shareTitle;
    self.shareDes = shareDes;
    self.previewImageURLString = previewImageURLString;
    if (self.bgControl) {
        [self.bgControl removeFromSuperview];
    }
    // 背景蒙版
    UIControl *bgControl = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    bgControl.backgroundColor = [UIColor colorWithRed:0.f green:0.f blue:0.f alpha:0.4];
    [bgControl addTarget:self action:@selector(bgControlClick:) forControlEvents:UIControlEventTouchUpInside];
    [[UIApplication sharedApplication].keyWindow addSubview:bgControl];
    self.bgControl = bgControl;
    // 分享面板
    UIView *shareView = [[UIView alloc] initWithFrame:CGRectMake(0, ScreenHeight, ScreenWidth, 176)];
    shareView.backgroundColor = [UIColor whiteColor];
    [bgControl addSubview:shareView];
    // 分享至Label
    UILabel *shareToLabel = [[UILabel alloc] init];
    shareToLabel.text = @"分享至";
    shareToLabel.font = [UIFont systemFontOfSize:15];
    shareToLabel.textColor = [UIColor blackColor];
    [shareView addSubview:shareToLabel];
    [shareToLabel sizeToFit];
    shareToLabel.centerX = ScreenWidth * 0.5;
    shareToLabel.top = 15;
    // 取消按钮
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [cancelButton sizeToFit];
    cancelButton.right = ScreenWidth - 15;
    cancelButton.centerY = shareToLabel.centerY;
    [cancelButton addTarget:self action:@selector(cancelButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [shareView addSubview:cancelButton];
    // 标题数组
    NSArray *titleArray = @[@"QQ", @"QQ空间", @"微信", @"朋友圈"];
    // 分享按钮
    // 创建九宫格按钮
    // 按钮的宽度
    CGFloat buttonW = 80;
    // 按钮的高度
    CGFloat buttonH = 120;
    // 总列数
    NSInteger maxCols = 4;
    for (NSInteger i = 0; i < 4; i++) {
        // 获取按钮父控件的索引
        NSUInteger index = i;
        /********************** 求X *****************/
        // 求出列号
        NSUInteger col = index % maxCols;
        
        // 求出水平方向的间距
        CGFloat xSpace = (ScreenWidth - maxCols * buttonW) / (maxCols + 1);
        // 求出按钮的X
        CGFloat buttonX = xSpace + col * (buttonW + xSpace);
        
        /********************** 求Y *****************/
        // 求出按钮的Y
        CGFloat buttonY = 35;
        // 选项按钮
        UIButton *optionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        optionButton.frame = CGRectMake(buttonX, buttonY, buttonW, buttonH);
        [optionButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"share_icon_%zd", i]] forState:UIControlStateNormal];
        [optionButton setTitle:titleArray[i] forState:UIControlStateNormal];
        [optionButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        optionButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [optionButton SG_imagePositionStyle:SGImagePositionStyleTop spacing:5];
        optionButton.tag = i;
        [optionButton addTarget:self action:@selector(optionButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [shareView addSubview:optionButton];
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        shareView.top = ScreenHeight - shareView.height;
    }];
}

/// 点击背景蒙版
- (void)bgControlClick:(UIControl *)bgControl {
    [bgControl removeFromSuperview];
}

/// 取消按钮点击
- (void)cancelButtonClick {
    [self.bgControl removeFromSuperview];
}

/// 分享按钮点击
- (void)optionButtonClick:(UIButton *)button {
    // 调起分享（微信/QQ）
    [self shareActionWithButton:button];
    // 隐藏分享面板
    [self cancelButtonClick];
}

/// 过滤字符串
- (NSString *)isString:(id)str {
    NSString *string = [NSString stringWithFormat:@"%@", str];
    if (!string || [string isEqualToString:@"(null)"] || [string isEqualToString:@"<null>"]) {
        return @"";
    } else {
        return string;
    }
}

/// 调起分享（微信/QQ）
- (void)shareActionWithButton:(UIButton *)button {
    [LCProgressHUD showLoading:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [LCProgressHUD hide];
    });
    if (button.tag == 0 || button.tag == 1) { // QQ/QQ空间
        QQApiNewsObject *newsObj = [QQApiNewsObject
                                    objectWithURL:[NSURL URLWithString:[self isString:self.shareURLString]]
                                    title:self.shareTitle
                                    description:self.shareDes
                                    previewImageURL:[NSURL URLWithString:[self isString:self.previewImageURLString]]];
        SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:newsObj];
        if (button.tag == 0) { // QQ好友
            //将内容分享到qq
            QQApiSendResultCode sent = [QQApiInterface sendReq:req];
            if (sent == EQQAPISENDSUCESS) {
                //                        [LCProgressHUD hide];
            } else {
                switch (sent) {
                    case EQQAPIQQNOTINSTALLED:
                        [LCProgressHUD showFailure:@"未安装手Q"];
                        break;
                    case EQQAPIQQNOTSUPPORTAPI:
                        [LCProgressHUD showFailure:@"手Q API接口不支持"];
                        break;
                    case EQQAPIMESSAGETYPEINVALID:
                        [LCProgressHUD showFailure:@"发送参数错误"];
                        break;
                    case EQQAPIMESSAGECONTENTNULL:
                        [LCProgressHUD showFailure:@"发送参数错误"];
                        break;
                    case EQQAPIMESSAGECONTENTINVALID:
                        [LCProgressHUD showFailure:@"发送参数错误"];
                        break;
                    case EQQAPIAPPNOTREGISTED:
                        [LCProgressHUD showFailure:@"App未注册"];
                        break;
                    case EQQAPIAPPSHAREASYNC:
                        //                                [LCProgressHUD showFailure:@"异步分享错误"];
                        break;
                    case EQQAPIQQNOTSUPPORTAPI_WITH_ERRORSHOW:
                        [LCProgressHUD showFailure:@"API不支持"];
                        break;
                    case EQQAPIMESSAGEARKCONTENTNULL:
                        [LCProgressHUD showFailure:@"ark内容为空"];
                        break;
                    case EQQAPISENDFAILD:
                        [LCProgressHUD showFailure:@"发送失败"];
                        break;
                    case EQQAPISHAREDESTUNKNOWN:
                        [LCProgressHUD showFailure:@"未指定分享到QQ或TIM"];
                        break;
                    case EQQAPITIMSENDFAILD:
                        [LCProgressHUD showFailure:@"发送失败"];
                        break;
                    case EQQAPITIMNOTINSTALLED:
                        [LCProgressHUD showFailure:@"TIM未安装"];
                        break;
                    case EQQAPITIMNOTSUPPORTAPI:
                        [LCProgressHUD showFailure:@"TIM api不支持"];
                        break;
                    case EQQAPIQZONENOTSUPPORTTEXT:
                        [LCProgressHUD showFailure:@"QQ空间分享不支持QQApiTextObject"];
                        break;
                    case EQQAPIQZONENOTSUPPORTIMAGE:
                        [LCProgressHUD showFailure:@"QQ空间分享不支持QQApiImageObject"];
                        break;
                    case EQQAPIVERSIONNEEDUPDATE:
                        [LCProgressHUD showFailure:@"当前QQ版本太低"];
                        break;
                    case ETIMAPIVERSIONNEEDUPDATE:
                        [LCProgressHUD showFailure:@"当前TIM版本太低"];
                        break;
                        
                    default:
                        [LCProgressHUD showFailure:@"未知错误"];
                        break;
                }
            }
        } else if (button.tag == 1) { // QQ空间
            //将内容分享到qzone
            QQApiSendResultCode sent = [QQApiInterface SendReqToQZone:req];
            if (sent == EQQAPISENDSUCESS) {
                //                        [LCProgressHUD hide];
            } else {
                switch (sent) {
                    case EQQAPIQQNOTINSTALLED:
                        [LCProgressHUD showFailure:@"未安装手Q"];
                        break;
                    case EQQAPIQQNOTSUPPORTAPI:
                        [LCProgressHUD showFailure:@"手Q API接口不支持"];
                        break;
                    case EQQAPIMESSAGETYPEINVALID:
                        [LCProgressHUD showFailure:@"发送参数错误"];
                        break;
                    case EQQAPIMESSAGECONTENTNULL:
                        [LCProgressHUD showFailure:@"发送参数错误"];
                        break;
                    case EQQAPIMESSAGECONTENTINVALID:
                        [LCProgressHUD showFailure:@"发送参数错误"];
                        break;
                    case EQQAPIAPPNOTREGISTED:
                        [LCProgressHUD showFailure:@"App未注册"];
                        break;
                    case EQQAPIAPPSHAREASYNC:
                        //                                [LCProgressHUD showFailure:@"异步分享错误"];
                        break;
                    case EQQAPIQQNOTSUPPORTAPI_WITH_ERRORSHOW:
                        [LCProgressHUD showFailure:@"API不支持"];
                        break;
                    case EQQAPIMESSAGEARKCONTENTNULL:
                        [LCProgressHUD showFailure:@"ark内容为空"];
                        break;
                    case EQQAPISENDFAILD:
                        [LCProgressHUD showFailure:@"发送失败"];
                        break;
                    case EQQAPISHAREDESTUNKNOWN:
                        [LCProgressHUD showFailure:@"未指定分享到QQ或TIM"];
                        break;
                    case EQQAPITIMSENDFAILD:
                        [LCProgressHUD showFailure:@"发送失败"];
                        break;
                    case EQQAPITIMNOTINSTALLED:
                        [LCProgressHUD showFailure:@"TIM未安装"];
                        break;
                    case EQQAPITIMNOTSUPPORTAPI:
                        [LCProgressHUD showFailure:@"TIM api不支持"];
                        break;
                    case EQQAPIQZONENOTSUPPORTTEXT:
                        [LCProgressHUD showFailure:@"QQ空间分享不支持QQApiTextObject"];
                        break;
                    case EQQAPIQZONENOTSUPPORTIMAGE:
                        [LCProgressHUD showFailure:@"QQ空间分享不支持QQApiImageObject"];
                        break;
                    case EQQAPIVERSIONNEEDUPDATE:
                        [LCProgressHUD showFailure:@"当前QQ版本太低"];
                        break;
                    case ETIMAPIVERSIONNEEDUPDATE:
                        [LCProgressHUD showFailure:@"当前TIM版本太低"];
                        break;
                        
                    default:
                        [LCProgressHUD showFailure:@"未知错误"];
                        break;
                }
            }
        }
    } else { // 微信/朋友圈
        if (![WXApi isWXAppInstalled]) {
            [LCProgressHUD showMessage:@"未安装微信或App未注册"];
            return;
        }
        if (![WXApi isWXAppSupportApi]) {
            [LCProgressHUD showMessage:@"微信版本不支持"];
            return;
        }
        _tempImageView = [[UIImageView alloc] init];
        [_tempImageView sd_setImageWithURL:[NSURL URLWithString:[self isString:self.previewImageURLString]] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) { // 获取到图片
            WXMediaMessage *message = [WXMediaMessage message];
            message.title = self.shareTitle;
            message.description = self.shareDes;
            [message setThumbImage:[UIImage imageWithData:[self imageWithImage:image scaledToSize:CGSizeMake(300, 300)]]];
            
            WXWebpageObject *webpageObject = [WXWebpageObject object];
            webpageObject.webpageUrl = self.shareURLString;
            message.mediaObject = webpageObject;
            
            SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
            req.bText = NO;
            req.message = message;
            if (button.tag == 2) { // 微信会话
                req.scene = WXSceneSession;
            } else if (button.tag == 3) { // 微信朋友圈
                req.scene = WXSceneTimeline;
            }
            [WXApi sendReq:req];
            [LCProgressHUD hide];
        }];
    }
}

// 获取code,调启后台进行登录
- (void)onResp:(BaseResp *)resp {
    if ([resp isKindOfClass:[SendMessageToWXResp class]]) { // 分享
        SendMessageToWXResp *sender = (SendMessageToWXResp *)resp;
        if (sender.errCode == WXSuccess) {
            [LCProgressHUD showSuccess:@"分享成功"];
        } else {
            //            [LCProgressHUD showFailure:[NSString stringWithFormat:@"错误码：%d，%@", sender.errCode, sender.errStr]];
            NSString *errorString = nil;
            switch (sender.errCode) {
                case WXErrCodeCommon:
                    errorString = @"分享失败";
                    break;
                case WXErrCodeUserCancel:
                    errorString = @"分享取消";
                    break;
                case WXErrCodeSentFail:
                    errorString = @"发送失败";
                    break;
                case WXErrCodeAuthDeny:
                    errorString = @"授权失败";
                    break;
                case WXErrCodeUnsupport:
                    errorString = @"微信不支持";
                    break;
                    
                default:
                    errorString = @"分享失败";
                    break;
            }
            [LCProgressHUD showFailure:errorString];
        }
    }
}

/// iOS 解决微信分享点击无反应（完美解决微信分享32K图片限制问题）
- (NSData *)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize;
{
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return UIImageJPEGRepresentation(newImage, 0.8);
}

@end
