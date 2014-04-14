//
//  AppController.m
//  SyncBar
//
//  Created by Andrew James on 24/04/07.
//  Copyright 2007 semaja2.net All rights reserved.
//


#import "AppController.h"

//#define kLastSync @"lastSync"
#define kLastSyncDate @"lastSyncDate"
#define kPeriod @"syncPeriod"

int createNewLoop = 0;

@implementation AppController

//-(void)awakeFromNib{
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
    NSBundle *bundle = [NSBundle mainBundle];	
	
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
	
	NSImage *statusImageOn = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"syncIcon" ofType:@"tiff"]];
	[statusItem setImage:statusImageOn];
	[statusItem setHighlightMode:YES];
	[statusItem setAction:@selector(MenuAction:)];
	[statusItem setTarget:self];
	
	
	
	NSDate *lastSyncDate = [[NSUserDefaults standardUserDefaults] objectForKey:kLastSyncDate];
	int lastSyncDateMil = [lastSyncDate timeIntervalSinceNow];
	int timerPeriod = [[NSUserDefaults standardUserDefaults] integerForKey:kPeriod];
	//NSLog(@"%i", timerPeriod);
	
	
	if (timerPeriod != 0){
		float timerPeriodAdjusted;
		timerPeriodAdjusted = timerPeriod + lastSyncDateMil;
		if (timerPeriodAdjusted < 0) {
			[self syncDevices];
			createNewLoop = 0;
			autoSyncTimer = [NSTimer scheduledTimerWithTimeInterval:timerPeriod
															 target:self
														   selector:@selector(syncLoop)
														   userInfo:nil
															repeats:YES];
			
			[[NSRunLoop currentRunLoop] addTimer:autoSyncTimer forMode:NSDefaultRunLoopMode];
		} else {
			//NSLog(@"new");
			createNewLoop = 1;
			autoSyncTimer = [NSTimer scheduledTimerWithTimeInterval:timerPeriodAdjusted
															 target:self
														   selector:@selector(syncLoop)
														   userInfo:nil
															repeats:NO];
			
			[[NSRunLoop currentRunLoop] addTimer:autoSyncTimer forMode:NSDefaultRunLoopMode];
			
		}
		//[syncEveryItem setState:YES];
	}
	NSNotificationCenter *notCenter;
	notCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
	[notCenter addObserver:self
				  selector:@selector(sleepObserver:)
					  name:NSWorkspaceWillSleepNotification
					object:nil];
	
	[notCenter addObserver:self
				  selector:@selector(wakeObserver:)
					  name:NSWorkspaceDidWakeNotification
					object:nil];
	
}

-(IBAction)MenuAction:(id)sender{
	NSMenu *statusMenu = [[[NSMenu alloc] init] autorelease];
    [[NSUserDefaults standardUserDefaults] synchronize];
    int lastSyncDateMil;
    float timerPeriod;
    float timerPeriodAdjusted;
    NSDate *lastSyncDate = [[NSUserDefaults standardUserDefaults] objectForKey:kLastSyncDate];
    lastSyncDateMil = [lastSyncDate timeIntervalSinceNow];
    timerPeriod = [[NSUserDefaults standardUserDefaults] floatForKey:kPeriod];
    timerPeriodAdjusted = timerPeriod + lastSyncDateMil;
    /*if (autoSyncTimer != nil) {
        timerPeriodAdjusted = [[autoSyncTimer fireDate] timeIntervalSinceNow];
    } else {
        timerPeriodAdjusted = 0.0;
    }*/
    NSString *tempString = [[[NSString alloc] init] autorelease]; //store a string

    if ([[NSUserDefaults standardUserDefaults] objectForKey:kLastSyncDate] != nil) {
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:@"%X" allowNaturalLanguage:NO] autorelease];
        NSString *formattedDateString = [dateFormatter stringFromDate:lastSyncDate];
        //[lastSyncDate descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M" timeZone:nil locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]]
        [statusMenu addItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"lastSync", @"Last Sync"),formattedDateString] action:nil keyEquivalent:@""];
    } /*else {
        [statusMenu addItemWithTitle:NSLocalizedString(@"noLastSync", @"No Last Sync") action:nil keyEquivalent:@""];
    }*/
    if (timerPeriod != 0) {
        if (timerPeriodAdjusted < 60) {
            tempString  = [NSString stringWithFormat:NSLocalizedString(@"Sec", @"Seconds"), timerPeriodAdjusted];
        } else if (timerPeriodAdjusted / 60.0  < 59) {
            tempString  = [NSString stringWithFormat:NSLocalizedString(@"Min", @"Minute"), timerPeriodAdjusted / 60.0];
        } else if (timerPeriodAdjusted / 60.0 / 60.0 < 24) {
            tempString  = [NSString stringWithFormat:NSLocalizedString(@"Hour", @"Hour"), timerPeriodAdjusted / 60.0 / 60.0];
        } else {
            tempString  = [NSString stringWithFormat:NSLocalizedString(@"Day", @"Day"), timerPeriodAdjusted / 60.0 / 60.0 / 24.0];
        }
        [statusMenu addItemWithTitle:[NSString stringWithFormat:@"%@%@", NSLocalizedString(@"syncRemain", @"Sync Remaining"), tempString] action:nil keyEquivalent:@""];
    } /*else {
        [statusMenu addItemWithTitle:NSLocalizedString(@"syncNotSched", @"Sync Not Scheduled") action:nil keyEquivalent:@""];
    }*/

    if ([[NSUserDefaults standardUserDefaults] objectForKey:kLastSyncDate] != nil || timerPeriodAdjusted != 0.0) {
        [statusMenu addItem:[NSMenuItem separatorItem]];
    }
    //NSLog(@"test5");
    [[statusMenu addItemWithTitle:NSLocalizedString(@"syncNow", @"Sync Now") action:@selector(syncDevices) keyEquivalent:@""] setTarget:self];

    if (timerPeriod == 0.0) {
        tempString  = @"";
    } else if (timerPeriod < 60) {
        tempString  = [NSString stringWithFormat:NSLocalizedString(@"Sec", @"Seconds"), timerPeriod];
    } else if (timerPeriod / 60.0 < 59) {
        tempString  = [NSString stringWithFormat:NSLocalizedString(@"Min", @"Minute"), timerPeriod / 60.0];
    } else if (timerPeriod / 60.0 / 60.0 < 24) {
        tempString  = [NSString stringWithFormat:NSLocalizedString(@"Hour", @"Hour"), timerPeriod / 60.0 / 60.0];
    } else {
        tempString  = [NSString stringWithFormat:NSLocalizedString(@"Day", @"Day"), timerPeriod / 60.0 / 60.0 / 24.0];
    }
    [[statusMenu addItemWithTitle:[NSString stringWithFormat:@"%@%@", NSLocalizedString(@"syncEvery", @"Sync Every"), tempString] action:@selector(makeWindow) keyEquivalent:@""] setTarget:self];
    [statusMenu addItem:[NSMenuItem separatorItem]];
    [[statusMenu addItemWithTitle:NSLocalizedString(@"openISync", @"Open iSync") action:@selector(openiSync:) keyEquivalent:@""] setTarget:self];
    [statusMenu addItem:[NSMenuItem separatorItem]];
    [[statusMenu addItemWithTitle:NSLocalizedString(@"aboutSyncBar", @"About SyncBar")action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""] setTarget:[NSApplication sharedApplication]];
    [[statusMenu addItemWithTitle:NSLocalizedString(@"quitSyncBar", @"Quit SyncBar") action:@selector(terminate:) keyEquivalent:@""] setTarget:NSApp];
	//NSLog(@"test6");
	[NSApp activateIgnoringOtherApps:YES];
	//NSLog(@"test7");
	[statusItem popUpStatusItemMenu:statusMenu];
	//[statusMenu autorelease];
	//[tempString autorelease];
}

-(IBAction)openiSync:(id)sender{
	NSWorkspace	*theWorkspace = [NSWorkspace sharedWorkspace];
	[theWorkspace launchApplication:@"iSync.app"];	
}

-(void)syncDevices{
	/* Request our Bluetooth Session */
	if (![[NSUserDefaults standardUserDefaults] integerForKey:@"disableBTSessions"]) 
		BTRequestSession();
	
	int iSyncState;
	iSyncState = [[[[NSWorkspace sharedWorkspace] launchedApplications] 
                    valueForKey:@"NSApplicationName"] containsObject:@"iSync"];
	
	if (!iSyncState) {
		[[NSWorkspace sharedWorkspace] launchApplication:@"iSync" showIcon:NO autolaunch:YES];
		NSAppleScript *as1 = [[NSAppleScript alloc] initWithSource:		@"tell application \"System Events\"\n"
			@"set this_app to some item of (get processes whose name = \"iSync\")\n"
			@"set visible of this_app to false\n"
			@"end tell\n"];
		[as1 executeAndReturnError:nil];
	}
	
	
	
	/* Nice sexy SyncNow recoded script */
	NSString *source = 
		@"tell application \"iSync\"\n"
		@"if not syncing then synchronize\n"
		@"repeat while syncing\n"
		@"delay 1\n"
		@"end repeat\n"
		@"end tell\n";
	
	//NSLog(source);
	
	NSAppleScript *as = [[[NSAppleScript alloc] initWithSource:source] autorelease];
	
	[as executeAndReturnError:nil];
	
	/* Finish our Bluetooth Session */
	if (![[NSUserDefaults standardUserDefaults] integerForKey:@"disableBTSessions"])
		BTFinishSession();
	
	if (!iSyncState) 
		[self quitApplicationWithBundleID:@"com.apple.iSync"];
	
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastSyncDate];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	//[as release];
}

-(void)syncLoop{
	[self syncDevices];
	if (createNewLoop) {
		int timerPeriod = [[NSUserDefaults standardUserDefaults] integerForKey:kPeriod];
		[autoSyncTimer invalidate];
		autoSyncTimer = [NSTimer scheduledTimerWithTimeInterval:timerPeriod
														 target:self
													   selector:@selector(syncLoop)
													   userInfo:nil
														repeats:YES];
		
		[[NSRunLoop currentRunLoop] addTimer:autoSyncTimer forMode:NSDefaultRunLoopMode];
		createNewLoop = NO;
	}
}

-(OSStatus)quitApplicationWithBundleID:(NSString*)bundleID
{
	OSStatus	result = noErr;
	AEAddressDesc	target = {};
	AEInitializeDesc(&target);
	
	const char	*bundleIDString = [bundleID UTF8String];
	
	result = AECreateDesc( typeApplicationBundleID, bundleIDString, strlen(bundleIDString), &target );
	if ( result == noErr )
	{
		AppleEvent	event = {};
		AEInitializeDesc(&event);
		
		result = AECreateAppleEvent( kCoreEventClass, kAEQuitApplication, &target, kAutoGenerateReturnID, kAnyTransactionID, &event );
		if ( result == noErr )
		{
			AppleEvent	reply = {};
			AEInitializeDesc(&reply);
			
			result = AESendMessage( &event, &reply, kAENoReply, 60 );
			
			AEDisposeDesc( &event );
		}
		
		AEDisposeDesc( &target );
	}
	
	return( result );
}

-(void)makeWindow{
	NSView *stuff;
	NSRect screenRect = [[NSScreen mainScreen] frame];
	float x = screenRect.size.width/2 - 225;
	float y = screenRect.size.height/2 - 100;
	NSRect windowRect = NSMakeRect(x,y,450,168);
	timerPanel2 = [[NSWindow alloc] initWithContentRect:windowRect
											  styleMask:NSTitledWindowMask | NSMiniaturizableWindowMask | NSTexturedBackgroundWindowMask | NSClosableWindowMask
												backing:NSBackingStoreBuffered
												  defer:NO
												 screen:[NSScreen mainScreen]];
	[timerPanel2 setReleasedWhenClosed:YES];
	[timerPanel2 setTitle:NSLocalizedString(@"syncEveryPanelTitle", @"Sync Every Panel Title")];
	[timerPanel2 setDelegate:self];
	[timerPanel2 center];
	stuff = [[NSView alloc] initWithFrame:windowRect];
	
	NSTextField *message;
	message = [[NSTextField alloc] initWithFrame:NSMakeRect(17,126,416,22)];
	[message setEditable:NO];
	[message setStringValue:NSLocalizedString(@"syncEveryPanelMessage", @"Sync Every Panel Message")];
	[message setDrawsBackground:NO];
	[message setBordered:NO];
	[stuff addSubview:message];
	
	slider = [[NSSlider alloc] initWithFrame:NSMakeRect(17,80,414,25)];
	[slider setMinValue:0];
	[slider setMaxValue:48];
	[slider setFloatValue:[[NSUserDefaults standardUserDefaults] floatForKey:kPeriod] / 60.0 / 60.0];
	[slider setTickMarkPosition:NSTickMarkBelow];
	[slider setNumberOfTickMarks:97];
	[slider setContinuous:YES];
	[slider setAllowsTickMarkValuesOnly:YES];
	[slider setAction:@selector(tickMoved)];
	[slider setTarget:self];
	[stuff addSubview:slider];
	
	
	NSTextField *sliderValueMin;
	sliderValueMin = [[NSTextField alloc] initWithFrame:NSMakeRect(17,54,47,22)];
	[sliderValueMin setEditable:NO];
	[sliderValueMin setStringValue:NSLocalizedString(@"Never", @"Never")];
	[sliderValueMin setDrawsBackground:NO];
	[sliderValueMin setBordered:NO];
	[stuff addSubview:sliderValueMin];
	
	NSTextField *sliderValueMax;
	sliderValueMax = [[NSTextField alloc] initWithFrame:NSMakeRect(342,54,87,22)];
	[sliderValueMax setEditable:NO];
	[sliderValueMax setAlignment:NSRightTextAlignment];
	[sliderValueMax setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Hour", @"Hour"), 48.0]];
	[sliderValueMax setDrawsBackground:NO];
	[sliderValueMax setBordered:NO];
	[stuff addSubview:sliderValueMax];
	
	sliderValueText = [[NSTextField alloc] initWithFrame:NSMakeRect(357,112,75,15)];
	[sliderValueText setEditable:NO];
	[sliderValueText setAlignment:NSRightTextAlignment];
	[sliderValueText setStringValue:NSLocalizedString(@"Never", @"Never")];
	[sliderValueText setDrawsBackground:NO];
	[sliderValueText setBordered:NO];
	[stuff addSubview:sliderValueText];
	
	
	
	
	NSButton *okButton;
	okButton = [[NSButton alloc] initWithFrame:NSMakeRect(354,12,82,32)];
	[okButton setButtonType:NSMomentaryPushInButton];
	[okButton setBezelStyle:NSRoundedBezelStyle];
	[okButton setAction:@selector(timerOK:)];
	[okButton setTarget:self];
	[okButton setTitle:NSLocalizedString(@"okButton", @"OK Button")];
	[stuff addSubview:okButton];
	
	
	NSButton *canButton;
	canButton = [[NSButton alloc] initWithFrame:NSMakeRect(272,12,82,32)];
	[canButton setButtonType:NSMomentaryPushInButton];
	[canButton setBezelStyle:NSRoundedBezelStyle];
	[canButton setAction:@selector(close)];
	[canButton setTarget:timerPanel2];
	[canButton setTitle:NSLocalizedString(@"canButton", @"Cancel Button")];
	[stuff addSubview:canButton];
	
	
	
	[timerPanel2 setContentView:stuff];
	[stuff autorelease];
	[timerPanel2 makeKeyAndOrderFront:self];
}


-(IBAction)timerOK:(id)sender{
	float timerPeriod = [slider floatValue] * 60.0 * 60.0;
	
	if (timerPeriod == 0) {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:kPeriod];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:kLastSyncDate];
		[autoSyncTimer invalidate];
		autoSyncTimer = nil;
	} else {
		autoSyncTimer = [NSTimer scheduledTimerWithTimeInterval:timerPeriod
														 target:self
													   selector:@selector(syncLoop)
													   userInfo:nil
														repeats:YES];
		[[NSRunLoop currentRunLoop] addTimer:autoSyncTimer forMode:NSDefaultRunLoopMode];
	}
	//if ([[NSUserDefaults standardUserDefaults] objectForKey:kLastSyncDate] == nil) 
	//	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastSyncDate];
	
	[[NSUserDefaults standardUserDefaults] setFloat:timerPeriod forKey:kPeriod];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[timerPanel2 close];
}

-(void)tickMoved{
	if ([slider floatValue] == 0.0)	
		[sliderValueText setStringValue:NSLocalizedString(@"Never", @"Never")];
	else 
		[sliderValueText setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Hour", @"Hour"), [slider floatValue]]];
}

- (void)windowWillClose:(NSNotification *)aNotification{
	[slider autorelease];
	[sliderValueText autorelease];
}

- (void)sleepObserver:(id)aNotification {
	// Invalidate the NSTimer
	[autoSyncTimer invalidate];
}


- (void)wakeObserver:(id)aNotification {
	NSDate *lastSyncDate = [[NSUserDefaults standardUserDefaults] objectForKey:kLastSyncDate];
	int lastSyncDateMil = [lastSyncDate timeIntervalSinceNow];
	int timerPeriod = [[NSUserDefaults standardUserDefaults] integerForKey:kPeriod];
	//NSLog(@"%i", timerPeriod);
	
	
	if (timerPeriod != 0){
		float timerPeriodAdjusted;
		timerPeriodAdjusted = timerPeriod + lastSyncDateMil;
		NSLog(@"%f", timerPeriodAdjusted);
		if (timerPeriodAdjusted < 0) {
			[self syncDevices];
			createNewLoop = 0;
			autoSyncTimer = [NSTimer scheduledTimerWithTimeInterval:timerPeriod
															 target:self
														   selector:@selector(syncLoop)
														   userInfo:nil
															repeats:YES];
			
			[[NSRunLoop currentRunLoop] addTimer:autoSyncTimer forMode:NSDefaultRunLoopMode];
		} else {
			//NSLog(@"new");
			createNewLoop = 1;
			autoSyncTimer = [NSTimer scheduledTimerWithTimeInterval:timerPeriodAdjusted
															 target:self
														   selector:@selector(syncLoop)
														   userInfo:nil
															repeats:NO];
			
			[[NSRunLoop currentRunLoop] addTimer:autoSyncTimer forMode:NSDefaultRunLoopMode];
			
		}
	}
}
@end