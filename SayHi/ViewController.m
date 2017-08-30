//
//  ViewController.m
//  SayHi
//
//  Created by 王靖凯 on 2017/8/29.
//  Copyright © 2017年 王靖凯. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (NSString *)hi {
    return @"hi!";
}

- (IBAction)sayHi:(NSButton *)sender {
    NSAlert *alert = [NSAlert.alloc init];
    alert.messageText = [self hi];
    alert.alertStyle = NSAlertStyleInformational;
    [alert runModal];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
