//
//  main.m
//  SyncBar
//
//  Created by Andrew James on 24/04/07.
//  Copyright __MyCompanyName__ 2007. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AppController;

int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    AppController *myController = [[AppController alloc] init];
    [[NSApplication sharedApplication] setDelegate: myController];	

    [[NSApplication sharedApplication] run];
    [myController release];

	[pool release];
	return 0;
}
