//
//  AppController.h
//  SyncBar
//
//  Created by Andrew James on 24/04/07.
//  Copyright 2007 semaja2.net All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BluetoothController.m"


@interface AppController : NSObject {
	NSStatusItem	*statusItem;
	NSTimer			*autoSyncTimer;
	NSWindow		*timerPanel2;
	NSSlider		*slider;
	NSTextField		*sliderValueText;
}

#pragma mark Menu Bar
-(IBAction)MenuAction:(id)sender;
-(IBAction)openiSync:(id)sender;

#pragma mark MISC
-(void)syncDevices;
-(void)syncLoop;
-(OSStatus)quitApplicationWithBundleID:(NSString*)bundleID;

#pragma mark GUI Windows
-(void)makeWindow;
-(IBAction)timerOK:(id)sender;
-(void)windowWillClose:(NSNotification *)aNotification;
#pragma mark Sleep Notifications
- (void)sleepObserver:(id)aNotification;
- (void)wakeObserver:(id)aNotification;

@end
