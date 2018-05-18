//
//  ViewController.m
//  XYFShareTool
//
//  Created by Mac on 2018/5/14.
//  Copyright © 2018年 Mac. All rights reserved.
//

#import "ViewController.h"
#import "ShareTool.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

/// 点击弹出分享面板
- (IBAction)clickShare {
    [[ShareTool sharedInstance] popShareBoardWithShareURLString:@"www.baidu.com" shareTitle:@"分享标题" shareDes:@"分享描述" previewImageURLString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1526388730096&di=09991bb0804120d579038f167c2f263e&imgtype=0&src=http%3A%2F%2Fimg5.duitang.com%2Fuploads%2Fitem%2F201502%2F23%2F20150223104319_KhVsH.thumb.700_0.jpeg"];
}

@end
