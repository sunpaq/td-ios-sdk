Keen IO iOS SDK
===============

The Keen IO iOS client is designed to be simple to develop with, yet incredibly flexible. Our goal is to let you decide what events are important to you, use your own vocabulary to describe them, and decide when you want to send them to Keen IO.

While the name of this repo implies that this SDK is strictly for iOS, it can also be used in Mac OS applications by using the Cocoa version as outlined below. The code base is the same, but the build targets are different. :)

* [Installation](#installation) - How to install `KeenClient` in your application
* [Usage](#usage) - How to use `KeenClient`
	* [Add Events](#add-events) - How to add an event
	* [Global Properties](#global-properties) - How to set global properties
	* [Geo Location](#geo-location) - How to use Geo Location
	* [Upload to Keen](#upload-events-to-keen-io) - How to upload all previously saved events
	* [Add-ons](#add-ons) - How to use Keen's [Data Enrichment](https://keen.io/docs/data-collection/data-enrichment/#data-enrichment) features to enrich your data
	* [Debugging](#debugging) - How to debug your application using the SDK's built in logging
* [FAQs](#faqs)
* [Changelog](#changelog)
* [To Do](#to-do)
* [Questions & Support](#questions--support)
* [Contributing](#contributing)
* [API Documentation](https://keen.io/static/iOS-reference/index.html)

### Installation

Installing the client should be a breeze. If it's not, please let us know at [contact@keen.io](mailto:contact@keen.io)!

#### Universal Binary

Our recommended way of installing `KeenClient` is to use the universal binary we’ve created. We have binaries for both [Cocoa](http://keen.io/static/code/KeenClient-Cocoa.zip) and [iOS](http://keen.io/static/code/KeenClient.zip).

> While we think the universal binary makes things really easy, we love to be transparent. We love feedback, especially in the form of pull requests. :)

##### Download

* [Cocoa](http://keen.io/static/code/KeenClient-Cocoa.zip)
* [iOS](http://keen.io/static/code/KeenClient.zip)

##### Uncompress - Cocoa

Uncompress the archive. It should contain a folder called “KeenClient-Cocoa” with the following contents:

* libKeenClient-Cocoa.a
* KeenClient.h
* KeenProperties.h
* KIOEventStore.h

##### Add Files to XCode - Cocoa

Drag the "KeenClient-Cocoa" folder into your XCode project.

##### Uncompress - iOS

Uncompress the archive. It should contain a folder called “KeenClient” with the following contents:

* libKeenClient-Aggregate.a
* KeenClient.h
* KeenProperties.h
* KIOEventStore.h

##### Add Files to XCode - iOS

Drag the "KeenClient" folder into your XCode project.

#### CocoaPods

If you're using [CocoaPods](http://cocoapods.org/), add the following to your Podfile:

```
pod 'KeenClient'
```

Then run:

```
pod install
```

##### Build Settings

Make sure to add CoreLocation.framework to the "Link Binary with Libraries" section.

Also enable the "-ObjC" linker flag under "Other Linker Flags".

Voila!

### Usage

To use this client with the Keen IO API, you have to configure your Keen IO Project ID and its access keys (if you need an account, [sign up here](https://keen.io/) - it's free).

##### Register Your Project ID and Access Keys

Register the `KeenClient` shared client with your Project ID and access keys. The recommended place to do this is in one of your application delegates like so:

```objc
- (void)applicationDidBecomeActive:(UIApplication *)application
{
	[KeenClient sharedClientWithProjectId:@"your_project_id" andWriteKey:@"your_write_key" andReadKey:@"your_read_key"];
}
```

The write key is required to send events to Keen IO. The read key is required to do analysis on Keen IO.

`[KeenClient sharedClientWithProjectId: andWriteKey: andReadKey:]` does the registration. From now on, in your code, you can just reference the shared client by calling `objc [KeenClient sharedClient]`.

##### Add Events

Add events to track. Here’s a very basic example for an app that includes two tabs. We want to track when a tab is switched to.

```objc
- (void)viewWillAppear:(BOOL)animated
{
  	[super viewWillAppear:animated];

  	NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:@"first view", @"view_name", @"going to", @"action", nil];
  	[[KeenClient sharedClient] addEvent:event toEventCollection:@"tab_views" error:nil];
}
```

The idea is to first create an arbitrary dictionary of JSON-serializable values. We support:

```objc 
NSString, NSNumber, NSDate, NSDictionary, NSArray, and BOOL
```

> The JSON spec doesn’t include anything about date values. At Keen, we know dates are important to track. Keen sends dates back and forth through its API in ISO-8601 format. `KeenClient` handles this for you.

Keys must be alphanumeric, with the exception of the underscore (_) character, which can appear anywhere but the beginning of the string. For example, “view_name” is allowed, but “_view_name” is not.

Add as many events as you like. `KeenClient` will cache them on disk until you’re ready to send them.

`KeenClient` will automatically stamp every event you track with a timestamp. If you want to override the system value with your own, use the following example. Note that the “timestamp” key is set in the header properties dictionary.

```objc
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

   	NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:@"first view", @"view_name", @"going to", @"action", nil];
    NSDate *myDate = [NSDate date];
    KeenProperties *keenProperties = [[KeenProperties alloc] init];
   	keenProperties.timestamp = myDate;
    [[KeenClient sharedClient] addEvent:event
           	         withKeenProperties:keenProperties
       	              toEventCollection:@"tab_views"
   	                              error:nil];
}
```

##### Global Properties

Now you might be thinking, “Okay, that looks pretty easy. But what if I want to send the same properties on _every_ event in a particular collection? Or just _every_ event, period?” We’ve got you covered through something we call Global Properties.

Global properties are properties which are sent with every event. For example, you may wish to always capture device information like OS version, handset type, orientation, etc.

There are two ways to handle Global Properties - one is more simple but more limited, while the other is a bit more complex but much more powerful. For each of them, after you register your client, you’ll need to set an Objective-C property on the `KeenClient` instance you’re using.

###### Dictionary-based Global Properties

For this, the Objective-C property is called `globalPropertiesDictionary`. The property’s value will be an `NSDictionary` that you define. Each time an event is added, the client will look at the value of this property and add all its contents to the user-defined event. Use this if you have a bunch of static properties that you want to add to every event.

Here's an example using a dictionary:

```objc
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    KeenClient *client = [KeenClient sharedClient];
   	client.globalPropertiesDictionary = @{@"some_standard_key": @"some_standard_value"};
}
```

> If there are two properties with the same name specified in the user-defined event and the global properties, the user-defined event’s property will be the one used.

###### Block-based Global Properties

For this, the Objective-C property is called `globalPropertiesBlock`. The property’s value will be a block that you define. Every time an event is added, the block will be called. The client expects the block to return an `NSDictionary` consisting of the global properties for that event collection. Use this if you have a bunch of dynamic properties (see below) that you want to add to every event.

Here’s an example using blocks:

```objc
- (void)applicationDidBecomeActive:(UIApplication *)application
{
   	KeenClient *client = [KeenClient sharedClient];
    client.globalPropertiesBlock = ^NSDictionary *(NSString *eventCollection) {
   	    if ([eventCollection isEqualToString:@"apples"]) {
       	    return @{ @"color": @"red" };
        } else if ([eventCollection isEqualToString:@"pears"]) {
   	        return @{ @"color": @"green" };
        } else {
   	        return nil;
        }
   	};
}
```

The block takes in a single string parameter which corresponds to the name of this particular event. And we expect it to return an `NSDictionary` of your construction. This example doesn’t make use of the parameter, but yours could!

> Because we support a block here, you can create **dynamic** global properties. For example, you might want to capture the orientation of the device, which obviously could change at run-time. With the block, you can use functional programming to ask the OS what the current orientation is, each time you add an event. Pretty useful, right?

> Another note - you can use _both_ the dictionary property and the block property at the same time. If there are conflicts between defined properties, the order of precedence is: user-defined event > block-defined event > dictionary-defined event. Meaning the properties you put in a single event will **always** show up, even if you define the same property in one of your globals.

##### Geo Location

Like any good mobile-first service, Keen supports geo localization so you can track where events happened. This is enabled by default. Just use the client as you normally would and your users will be asked to allow geo location services. All events will be automatically tagged with the current location.

###### Refreshing Current Location

Every time the app is freshly loaded, the client will automatically ask the device for its current location. It won’t ask again in order to save battery life. You can tell the client to ask the device for location again. Simply call:

```objc
[[KeenClient sharedClient] refreshCurrentLocation];
```

###### Manually Setting Location

You can also set the location manually. See the following example:

```objc
NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:@"first view", @"view_name", @"going to", @"action", nil];

KeenProperties *keenProperties = [[KeenProperties alloc] init];
CLLocation *location = [[CLLocation alloc] initWithLatitude:37.73 longitude:-122.47];
keenProperties.location = location;

[[KeenClient sharedClient] addEvent:event withKeenProperties:keenProperties toEventCollection:@"tab_views" error:nil];
```

###### Requesting Authorization for Location in iOS 8+

iOS 8 introduced a new method for requesting authorization that requires a few additional steps before location will automatically be appended to your events:

1. Add one or both of the following keys to your Info.plist file: `NSLocationWhenInUseUsageDescription`,`NSLocationAlwaysUsageDescription`
2. Call the appropriate authorization method to authorize your app to use location services. `authorizeGeoLocationWhenInUse` and `authorizeGeoLocationAlways` were both added as of version 3.2.16 of this SDK. `authorizeGeoLocationWhenInUse` is enabled by default as long as `NSLocationWhenInUseUsageDescription` is specified in your Info.plist file, so you don't need to call it if you're going the 'When in Use' route. `authorizeGeoLocationAlways` on the other hand must be called explicitly.

Example:

```objc
[KeenClient authorizeGeoLocationAlways];
[KeenClient sharedClientWithProjectId:@"your_project_id" andWriteKey:@"your_write_key" andReadKey:@"your_read_key"];
```

##### Upload Events to Keen IO

Upload the captured events to the Keen service. This must be done explicitly. We recommend doing the upload when your application is sent to the background, but you can do it whenever you’d like (for example, if your application typically has very long user sessions). The uploader spawns its own background thread so the main UI thread is not blocked.

```objc
- (void)applicationDidEnterBackground:(UIApplication *)application
{
    UIBackgroundTaskIdentifier taskId = [application beginBackgroundTaskWithExpirationHandler:^(void) {
        NSLog(@"Background task is being expired.");
    }];

    [[KeenClient sharedClient] uploadWithFinishedBlock:^(void) {
        [application endBackgroundTask:taskId];
    }];
}
```
In this example, the upload is done in a background task so that even once the user backgrounds your application, the upload can continue. Here we first start the background task, start the upload, and then end the background task once the upload completes.

If you want to call upload periodically during your application’s execution, you can do so by simply invoking the `uploadWithFinishedBlock` method on your `KeenClient` instance at any point.

```objc
[[KeenClient sharedClient] uploadWithFinishedBlock:nil];
```

**An important note:** it's a best practice to issue a single upload at a time. We make a best effort to reduce the number of threads spawned to upload in the background, but if you call upload many many times in a tight loop you're going to cause issues for yourself.

##### Add-ons

Keen IO can take data you’ve sent and enrich it by parsing the data or joining it with other data sets. This is done through the concept of “add-ons”.

To activate add-ons, you simply add some new properties within the “keen” namespace in your events. Detailed documentation for the configuration of our add-ons is available [here](https://keen.io/docs/data-collection/data-enrichment/#add-ons).

For example, let's say we want to enable the [IP to Geo](https://keen.io/docs/data-collection/data-enrichment/#ip-to-geo) add-on:

```objc
KeenClient *client = [KeenClient sharedClient];
client.globalPropertiesDictionary = @{@"keen":
                                         @{
                                           @"addons":@[
                                                       @{
                                                           @"name":@"keen:ip_to_geo",
                                                           @"input":@{
                                                                   @"ip":@"ip_address"
                                                           },
                                                           @"output":@"ip_geo_info"
                                                       }
                                                   ]
                                               },
                                           @"ip_address":[self getIPAddress:YES]
                                         };
```

In this example, we add a global property for the IP to Geo information that allows us to translate the device's current IP address into the geographical location of the device by using the `[self getIPAddress:YES]` method. 

**Note:** `[self getIPAddress:YES]` is a custom method that you'll have to implement for yourself as there's currently no built-in method to obtain the device's IP address. We've had success using a few of the solutions suggested in [this post](http://stackoverflow.com/questions/7072989/iphone-ipad-osx-how-to-get-my-ip-address-programmatically).

##### Debugging

`KeenClient` code does a lot of logging, but it’s turned off by default. If you’d like to see the log lines generated by your usage of the client, you can enable logging easily:

```objc
[KeenClient enableLogging];
```

Just put this at any point before you use `KeenClient`. A good place is in your application delegate.

To disable logging, simply call:

```objc
[KeenClient disableLogging];
```

##### Do analysis with Keen IO

    TO DO

### FAQs

Q: What happens when the device is offline? Will events automatically be sent when the device connects to wifi again?

A: Our SDK handles offline data collection and have built-in limits to prevent too much data from building up. We also handle re-posting events so that you don't have to worry about this.

Here's how it works. You specify when events should be uploaded to Keen (e.g. when the app is backgrounded).

If your player is offline when that happens, their data will be collected on the device and it will not be posted to Keen IO.
However, the next time they trigger the code that send events (e.g. backgrounding the app again) all the data from the previous sessions will also be posted (the timestamps will reflect the times the events actually happened).
    
### Changelog

##### 3.2.20
+ Skipped 3.2.19 due to CocoaPods versioning issue.
+ Fixed semaphore_wait_trap issue caused by recursive calls of dispatch_sync.

##### 3.2.18
+ Fixed erroneous removal of disableGeoLocation method call from KeenClient.h.

##### 3.2.17
+ Fixed bug created in CocoaPods by 3.2.16.

##### 3.2.16
+ Added support for `requestWhenInUseAuthorization` and `requestAlwaysAuthorization` in iOS 8.

##### 3.2.15

+ Updated GitHub documentation to match documentation found at [keen.io](http://keen.io)
+ Added KeenClient-Cocoa build target/universal binary to support Mac OS X
+ Added convertNSDateToISO8601 to dispatch queue
+ Refactored semaphores to use dispatch_sync and cleaned up instances of dispatch_retain

##### 3.2.14

+ Fixed analyzer warnings.
+ Fixed methods returning NSErrors as double pointers.
+ Enabled ARC in Simulator and Device targets.

##### 3.2.13

+ Updated podspec to include c source for sqlite3.

##### 3.2.12

+ Skipped 3.2.11 versioning in favor of 3.2.12 to workaround CocoaPods versioning issue.
+ Converted KeenClient to use ARC.
+ Renamed all SQLite files with keen\_io\_ prefix.
+ Moved keen\_io\_sqlite3.h import to KIOEventStore.m.
+ Added sdkVersion class method.
+ Replaced usage of NSDateFormatter with SQLite based date conversion (thread safe).
+ Fixed KEEN\_LOGGING\_ macro.
+ Added call to resetPendingEvents in getEvents.
+ Fixed instance client issues created by KIOEventStore implementation.

##### 3.2.10

+ Fixed array allocation/deallocation bug in prepareJSONData.
+ Added queuing to KIOEventStore to ensure SQLite calls are serialized.
+ Added sqlite-amalgamation library to eliminate dependency on libsqlite3.dylib.
+ Added SDK version string to logging.

##### 3.2.9

+ Replaced use of filesystem's cache directory with SQLite via KIOEventStore.

##### 3.2.8

+ Upload with finished block consistency fix.

##### 3.2.7

+ Support sending addons in events.

##### 3.2.6

+ Bugfix to always invoke callback on upload, even if there are no events to upload.

##### 3.2.5

+ Don't throw exceptions and crash the app when the local cache directory is unavailable.
+ Remove ISO8601DateFormatter dependency.
+ Use Grand Central Dispatch to not spawn one thread per upload invocation.

##### 3.2.4

+ Get semantic versioning cleaned up for cocoapods (somehow got confused between 3.2.2 and 3.2.3).

##### 3.2.2

+ Support for iOS 7 and ARM64.
+ Removed JSONKit dependency in favor of NSJONSerialization.

##### 3.2.1

+ Changed project token -> project ID.
+ Added support for read and write scoped keys.
+ Added support for travis.

### To Do

* Support analysis APIs.
* Native iOS visualizations.

### Questions & Support

If you have any questions, bugs, or suggestions, please
report them via Github Issues. Or, come chat with us anytime
at [users.keen.io](http://users.keen.io). We'd love to hear your feedback and ideas!

### Contributing
This is an open source project and we love involvement from the community! Hit us up with pull requests and issues.
