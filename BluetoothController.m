//
//  BluetoothController.m
//  SyncBar
//
//  Created by Andrew James on 10/07/07.
//  semaja2.net 2007 Licenced under the GPL.
//

//#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
//#import <IOBluetooth/IOBluetooth.h>

#define BT_ON	1
#define BT_OFF	0



int state = -1;

bool BTPowerState()
{
	return IOBluetoothPreferenceGetControllerPowerState();
    //return 0;
}

int BTSetPowerState(int powerState)
{
	IOBluetoothPreferenceSetControllerPowerState(powerState);
	
	if (BTPowerState() != powerState) {
		return EXIT_FAILURE;
	}
	
	return EXIT_SUCCESS;
}

int BTRequestSession()
{
	state = BTPowerState();
	switch(state) {
		case BT_ON:
			return EXIT_SUCCESS;
		case  BT_OFF:
			return BTSetPowerState(BT_ON);
		default:
			return EXIT_FAILURE;
	}
}

int BTFinishSession()
{
	switch(state) {
		case BT_ON:
			return EXIT_SUCCESS;
		case  BT_OFF:
			return BTSetPowerState(BT_OFF);
		default:
			return EXIT_FAILURE;
	}
}