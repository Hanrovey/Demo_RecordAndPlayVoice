//
//  ViewController.m
//  Demo_RecordAndPlayVoice
//
//  Created by Ihefe_Hanrovey on 2016/11/3.
//  Copyright © 2016年 Ihefe_Hanrovey. All rights reserved.
//

#import "ViewController.h"
#import "CXHRecordView.h"


@interface ViewController ()

@property (nonatomic, strong) CXHRecordView *recordView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.recordView = [CXHRecordView recordView];
    self.recordView.backgroundColor = [UIColor lightGrayColor];
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    self.recordView.frame = CGRectMake(50, 100, width - 2 * 50, 300);
    [self.view addSubview:self.recordView];
    
}

@end
