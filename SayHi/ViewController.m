//
//  ViewController.m
//  SayHi
//
//  Created by 王靖凯 on 2018/2/10.
//  Copyright © 2018年 王靖凯. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}

- (IBAction)sayHi1:(NSButton *)sender {
    NSAlert *alert    = NSAlert.new;
    alert.messageText = @"hi!";
    alert.alertStyle  = NSAlertStyleInformational;
    [alert runModal];
}

- (IBAction)sayHi:(NSButton *)sender {
    NSAlert *alert    = NSAlert.new;
    alert.messageText = getHi();
    alert.alertStyle  = NSAlertStyleInformational;
    [alert runModal];
}

NSString *getHi() {
    return @"hi!";
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end
