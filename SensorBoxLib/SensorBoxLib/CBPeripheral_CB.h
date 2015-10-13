//
//  CBPeripheral_CB.h
//  Flyskyhy
//
//  Created by René Dekker on 18/09/2015.
//  Copyright © 2015 Renevision. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface CBPeripheral (BackwardCompatibility)

- (CFUUIDRef) UUID_BC;
- (NSString *) uuidString;
- (bool) uuidIsEqual:(CBPeripheral *)other;

@end

