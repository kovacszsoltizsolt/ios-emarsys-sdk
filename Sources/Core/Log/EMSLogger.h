//
// Copyright (c) 2018 Emarsys. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "EMSShardRepository.h"
#import "EMSTimestampProvider.h"
#import "EMSUUIDProvider.h"

typedef enum {
    LogLevelTrace,
    LogLevelDebug,
    LogLevelInfo,
    LogLevelWarn,
    LogLevelError
} LogLevel;

@protocol EMSLogEntryProtocol;

@interface EMSLogger : NSObject

- (instancetype)initWithShardRepository:(id <EMSShardRepositoryProtocol>)shardRepository
                         opertaionQueue:(NSOperationQueue *)operationQueue
                      timestampProvider:(EMSTimestampProvider *)timestampProvider
                           uuidProvider:(EMSUUIDProvider *)uuidProvider;

- (void)log:(id <EMSLogEntryProtocol>)entry
      level:(LogLevel)level;

@end