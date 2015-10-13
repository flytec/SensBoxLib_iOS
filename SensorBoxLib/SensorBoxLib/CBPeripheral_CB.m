//
//  CBPeripheral_CB.m
//  Flyskyhy
//
//  Created by René Dekker on 18/09/2015.
//  Copyright © 2015 Renevision. All rights reserved.
//

#import "CBPeripheral_CB.h"

@implementation CBPeripheral (BackwardCompatibility)

- (CFUUIDRef) UUID_BC
{
    if ([self respondsToSelector:@selector(identifier)]) {
        NSUUID *uuid = [self identifier];
        NSString *string = uuid.UUIDString;
        return CFUUIDCreateFromString(NULL, (CFStringRef)string);
    } else {
        return (__bridge CFUUIDRef)([self performSelector:@selector(UUID)]);
    }
}

- (NSString *) uuidString
{
    if ([self respondsToSelector:@selector(identifier)]) {
        return [[self identifier] UUIDString];
    } else {
        CFUUIDRef uuid = (__bridge CFUUIDRef)[self performSelector:@selector(UUID)];
        return [(( NSString *) CFUUIDCreateString(NULL, uuid)) autorelease];
    }
}

- (bool) uuidIsEqual:(CBPeripheral *)other
{
    if ([self respondsToSelector:@selector(identifier)]) {
        return [[self identifier] isEqual:[other identifier]];
    } else {
        CFUUIDRef uuid = (__bridge CFUUIDRef)[self performSelector:@selector(UUID)];
        CFUUIDRef uuidOther = (__bridge CFUUIDRef)[self performSelector:@selector(UUID)];
        return CFEqual(uuid, uuidOther);
    }
}

@end


