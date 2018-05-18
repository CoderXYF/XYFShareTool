//
//  ShareTool.h
//  NewProjects
//
//  Created by Mac on 2018/5/12.
//  Copyright © 2018年 DSOperation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WXApi.h>

@interface ShareTool : NSObject <WXApiDelegate>
/// 获取单例
+ (instancetype)sharedInstance;
/// 弹出分享面板
- (void)popShareBoardWithShareURLString:(NSString *)shareURLString shareTitle:(NSString *)shareTitle shareDes:(NSString *)shareDes previewImageURLString:(NSString *)previewImageURLString;

@end
