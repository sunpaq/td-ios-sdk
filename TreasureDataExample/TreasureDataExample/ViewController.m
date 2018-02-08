//
//  ViewController.m
//  TreasureDataExample
//
//  Created by Mitsunori Komatsu on 7/13/16.
//  Copyright © 2016 Treasure Data. All rights reserved.
//

#import "ViewController.h"
#import "TreasureData-iOS-SDK/TreasureData.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.addEventBtn.layer.borderWidth = 1.0f;
    self.addEventBtn.layer.borderColor = [self.view.tintColor CGColor];
    self.addEventBtn.layer.cornerRadius = 10;
    self.uploadEventsBtn.layer.borderWidth = 1.0f;
    self.uploadEventsBtn.layer.borderColor = [self.view.tintColor CGColor];
    self.uploadEventsBtn.layer.cornerRadius = 10;

    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)addEvent:(id)sender {
    [[TreasureData sharedInstance]
     addEventWithCallback:@{
                            @"event": @"User",
                            @"name": @"komamitsu",
                            @"age": @99
                            }
     table:@"mobile"
     onSuccess:^(){
         NSLog(@"addEvent: success");
     }
     onError:^(NSString* errorCode, NSString* message) {
         NSLog(@"addEvent: error. errorCode=%@, message=%@", errorCode, message);
     }
     ];
}

- (IBAction)uploadEvents:(id)sender {
    [[TreasureData sharedInstance] uploadEventsWithCallback:^(){
        NSLog(@"uploadEvents: success");
    } onError:^(NSString* errorCode, NSString* message) {
        NSLog(@"uploadEvents: error. errorCode=%@, message=%@", errorCode, message);
    }];
}
@end
