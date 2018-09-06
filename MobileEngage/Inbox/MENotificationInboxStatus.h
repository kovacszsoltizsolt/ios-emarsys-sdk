//
// Copyright (c) 2017 Emarsys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EMSNotification.h"

@interface MENotificationInboxStatus : NSObject

@property(nonatomic, strong) NSArray<EMSNotification *> *notifications;
@property(nonatomic, assign) NSUInteger badgeCount;

@end