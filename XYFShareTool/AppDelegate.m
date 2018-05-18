//
//  AppDelegate.m
//  XYFShareTool
//
//  Created by Mac on 2018/5/14.
//  Copyright © 2018年 Mac. All rights reserved.
//

#import "AppDelegate.h"
#import <WXApi.h>
#import <TencentOpenAPI/TencentOAuth.h>
#import <TencentOpenAPI/QQApiInterface.h>
#import <LCProgressHUD.h>
#import "ShareTool.h"

@interface AppDelegate () <QQApiInterfaceDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [WXApi registerApp:@"your wechat AppID" enableMTA:YES];
    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    NSString *string = [url absoluteString];
    if ([string hasPrefix:@"wx"]){  // 微信
        return [WXApi handleOpenURL:url delegate:[ShareTool sharedInstance]];
    } else { // QQ
        [QQApiInterface handleOpenURL:url delegate:self];
        return [TencentOAuth HandleOpenURL:url];
    }
}

#pragma mark - QQApiInterfaceDelegate

/**
 处理来至QQ的请求
 */
- (void)onReq:(QQBaseReq *)req {
    NSLog(@" ----req %@",req);
}

/**
 处理来至QQ的响应
 */
- (void)onResp:(QQBaseResp *)resp {
    NSLog(@" ----resp %@",resp);
    
    // SendMessageToQQResp应答帮助类
    if ([resp.class isSubclassOfClass: [SendMessageToQQResp class]]) {  // QQ分享回应
        SendMessageToQQResp *msg = (SendMessageToQQResp *)resp;
        NSLog(@"code %@  errorDescription %@  infoType %@",resp.result,resp.errorDescription,resp.extendInfo);
        if (msg.result.integerValue == 0) {
            [LCProgressHUD showSuccess:@"分享成功"];
        } else {
            if (msg.result.integerValue == -4) {
                [LCProgressHUD showFailure:@"分享取消"];
            } else {
                [LCProgressHUD showFailure:@"分享失败"];
            }
        }
    }
}

/**
 处理QQ在线状态的回调
 */
- (void)isOnlineResponse:(NSDictionary *)response{
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
