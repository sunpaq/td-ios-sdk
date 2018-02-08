//
//  AppDelegate.m
//  TreasureDataExample
//
//  Created by Mitsunori Komatsu on 7/13/16.
//  Copyright © 2016 Treasure Data. All rights reserved.
//

#import "AppDelegate.h"
#import "TreasureData.h"
#import "TDConfiguration.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [TreasureData disableLogging];
    // [TreasureData initializeApiEndpoint:@"https://in.ybi.idcfcloud.net"];

    TDConfiguration *configuration = [TDConfiguration new];

    configuration.encryptionKey = @"hello world";
    
    configuration.endpoint = @"https://in.treasuredata.com";
    configuration.apiKey = @"your_api_key";

    configuration.defaultDatabase = @"huy";
    configuration.defaultTable = @"mobile";
    configuration.autoAppendUniqId = true;
    configuration.autoAppendRecordUUID = true;
    configuration.autoAppendModelInformation = true;
    configuration.autoAppendAppInformation = true;
    configuration.autoAppendLocaleInformation = true;
    configuration.serverTimestampColumn = @"server_upload_time";
    configuration.autoCaptureLifecycleEvents = true;
    
    [TreasureData config:configuration];
    
    
    
//    [TreasureData initializeEncryptionKey:@"hello world"];
//    [TreasureData initializeWithApiKey:@"your_api_key"];
//    [[TreasureData sharedInstance] setDefaultDatabase:@"testdb"];
//    [[TreasureData sharedInstance] enableAutoAppendUniqId];
//    [[TreasureData sharedInstance] enableAutoAppendRecordUUID];
//    [[TreasureData sharedInstance] enableAutoAppendModelInformation];
//    [[TreasureData sharedInstance] enableAutoAppendAppInformation];
//    [[TreasureData sharedInstance] enableAutoAppendLocaleInformation];
//    // [[TreasureData sharedInstance] disableRetryUploading];
//    [[TreasureData sharedInstance] enableServerSideUploadTimestamp: @"server_upload_time"];
    
//    if ([[TreasureData sharedInstance] isFirstRun]) {
//        [[TreasureData sharedInstance] addEventWithCallback:@{ @"event": @"installed" }
//                                                   database:@"testdb"
//                                                      table:@"demotbl"
//                                                  onSuccess:^(){
//                                                      [[TreasureData sharedInstance] uploadEventsWithCallback:^() {
//                                                          [[TreasureData sharedInstance] clearFirstRun];
//                                                      }
//                                                                                                      onError:^(NSString* errorCode, NSString* message) {
//                                                                                                          NSLog(@"uploadEvents: error. errorCode=%@, message=%@", errorCode, message);
//                                                                                                      }
//                                                       ];
//                                                  }
//                                                    onError:^(NSString* errorCode, NSString* message) {
//                                                        // NSLog(@"addEvent: error. errorCode=%@, message=%@", errorCode, message);
//                                                    }];
//    }
    
    [[TreasureData sharedInstance] setDelegate:self];
    
    [TreasureData startSession];
    
    [self registerNotification];
    
    return YES;
}

- (void)didSentEvent:(NSDictionary *)data
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
    NSString *strJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    [self displayNotification:strJson];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    completionHandler(UNNotificationPresentationOptionAlert);
}

- (void)registerNotification
{
    UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:UNAuthorizationOptionSound + UNAuthorizationOptionAlert completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (error != nil) {
            @throw [NSException exceptionWithName:@"Unable to register for notifications" reason:@"Who know" userInfo:nil];
        } else {
            NSLog(@"Complete registering for notifications");
        }
    }];
    
    UNNotificationCategory* generalCategory = [UNNotificationCategory
                                               categoryWithIdentifier:@"GENERAL"
                                               actions:@[]
                                               intentIdentifiers:@[]
                                               options:UNNotificationCategoryOptionCustomDismissAction];
    
    [center setNotificationCategories:[NSSet setWithObjects:generalCategory, nil]];

    [center setDelegate:self];
}

- (void)displayNotification:(NSString *) text
{
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = @"TD Event Captured";
    content.body = text;
    
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval: 1 repeats:NO];
    
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"TDSampleRequest" content:content trigger:trigger];
    
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            @throw [NSException exceptionWithName:@"Unable to register for notifications" reason:@"Who know" userInfo:nil];
        } else {
            NSLog(@"Sent a notification successfully");
        }
    }];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Event Details"
                                                        message:notification.alertBody
                                                       delegate:self cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // [[TreasureData sharedInstance] endSession:@"demotbl"];
    NSLog(@"session_id = %@ before calling `endSession`", [TreasureData getSessionId]);
    [TreasureData endSession];
    NSLog(@"session_id = %@ after calling `endSession`", [TreasureData getSessionId]);
    
    UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{}];
    [[TreasureData sharedInstance] uploadEventsWithCallback:^() {
        [application endBackgroundTask:bgTask];
    }
                                                    onError:^(NSString *code, NSString *msg) {
                                                        [application endBackgroundTask:bgTask];
                                                    }
     ];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    // [[TreasureData sharedInstance] startSession:@"demotbl"];
    NSLog(@"session_id = %@ before calling `startSession`", [TreasureData getSessionId]);
//    [TreasureData startSession];
    NSLog(@"session_id = %@ after calling `startSession`", [TreasureData getSessionId]);
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
