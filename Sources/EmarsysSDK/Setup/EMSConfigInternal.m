//
// Copyright (c) 2019 Emarsys. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EMSConfigInternal.h"
#import "EMSMobileEngageV3Internal.h"
#import "MERequestContext.h"
#import "EMSPushV3Internal.h"
#import "PRERequestContext.h"
#import "EMSDeviceInfo.h"
#import "EMSRequestManager.h"
#import "EMSEmarsysRequestFactory.h"
#import "EMSRemoteConfigResponseMapper.h"
#import "EMSEndpoint.h"
#import "EMSLogger.h"
#import "EMSResponseModel.h"
#import "EMSCrypto.h"
#import "EMSDispatchWaiter.h"
#import "NSError+EMSCore.h"
#import "EMSDeviceInfoV3ClientInternal.h"
#import "MEExperimental.h"
#import "EMSInnerFeature.h"
#import "EMSRemoteConfig.h"

#define METHOD_TIMEOUT 60

@interface EMSConfigInternal ()

@property(nonatomic, strong) EMSMobileEngageV3Internal *mobileEngage;
@property(nonatomic, strong) MERequestContext *meRequestContext;
@property(nonatomic, strong) PRERequestContext *preRequestContext;
@property(nonatomic, strong) EMSPushV3Internal *pushInternal;
@property(nonatomic, strong) EMSDeviceInfo *deviceInfo;
@property(nonatomic, strong) EMSRequestManager *requestManager;
@property(nonatomic, strong) EMSEmarsysRequestFactory *emarsysRequestFactory;
@property(nonatomic, strong) EMSEndpoint *endpoint;
@property(nonatomic, strong) EMSLogger *logger;
@property(nonatomic, strong) EMSRemoteConfigResponseMapper *remoteConfigResponseMapper;
@property(nonatomic, strong) EMSCrypto *crypto;
@property(nonatomic, strong) NSOperationQueue *queue;
@property(nonatomic, strong) EMSDispatchWaiter *waiter;
@property(nonatomic, strong) EMSDeviceInfoV3ClientInternal *deviceInfoClient;

@end

@implementation EMSConfigInternal

- (instancetype)initWithRequestManager:(EMSRequestManager *)requestManager
                      meRequestContext:(MERequestContext *)meRequestContext
                     preRequestContext:(PRERequestContext *)preRequestContext
                          mobileEngage:(EMSMobileEngageV3Internal *)mobileEngage
                          pushInternal:(EMSPushV3Internal *)pushInternal
                            deviceInfo:(EMSDeviceInfo *)deviceInfo
                 emarsysRequestFactory:(EMSEmarsysRequestFactory *)emarsysRequestFactory
            remoteConfigResponseMapper:(EMSRemoteConfigResponseMapper *)remoteConfigResponseMapper
                              endpoint:(EMSEndpoint *)endpoint
                                logger:(EMSLogger *)logger
                                crypto:(EMSCrypto *)crypto
                                 queue:(NSOperationQueue *)queue
                                waiter:(EMSDispatchWaiter *)waiter
                      deviceInfoClient:(EMSDeviceInfoV3ClientInternal *)deviceInfoClient {
    NSParameterAssert(requestManager);
    NSParameterAssert(meRequestContext);
    NSParameterAssert(preRequestContext);
    NSParameterAssert(mobileEngage);
    NSParameterAssert(pushInternal);
    NSParameterAssert(deviceInfo);
    NSParameterAssert(emarsysRequestFactory);
    NSParameterAssert(remoteConfigResponseMapper);
    NSParameterAssert(endpoint);
    NSParameterAssert(logger);
    NSParameterAssert(crypto);
    NSParameterAssert(queue);
    NSParameterAssert(waiter);
    NSParameterAssert(deviceInfoClient);
    if (self = [super init]) {
        _requestManager = requestManager;
        _mobileEngage = mobileEngage;
        _meRequestContext = meRequestContext;
        _preRequestContext = preRequestContext;
        _pushInternal = pushInternal;
        _deviceInfo = deviceInfo;
        _emarsysRequestFactory = emarsysRequestFactory;
        _remoteConfigResponseMapper = remoteConfigResponseMapper;
        _endpoint = endpoint;
        _logger = logger;
        _crypto = crypto;
        _queue = queue;
        _waiter = waiter;
        _deviceInfoClient = deviceInfoClient;
    }
    return self;
}

- (void)refreshConfigFromRemoteConfigWithCompletionBlock:(_Nullable EMSCompletionBlock)completionBlock {
    if (self.meRequestContext.applicationCode) {
        EMSRequestModel *signatureRequestModel = [self.emarsysRequestFactory createRemoteConfigSignatureRequestModel];
        [self.requestManager submitRequestModelNow:signatureRequestModel
                                      successBlock:^(NSString *requestId, EMSResponseModel *response) {
                                          [self fetchRemoteConfigWithSignatureData:response.body
                                                                   completionBlock:completionBlock];
                                      }
                                        errorBlock:^(NSString *requestId, NSError *error) {
                                            if (completionBlock) {
                                                completionBlock(error);
                                            }
                                            if (error) {
                                                [self.endpoint reset];
                                                [self.logger reset];
                                            }
                                        }];
    }
}

- (void)fetchRemoteConfigWithSignatureData:(NSData *)signatureData
                           completionBlock:(_Nullable EMSCompletionBlock)completionBlock {
    EMSRequestModel *requestModel = [self.emarsysRequestFactory createRemoteConfigRequestModel];
    [self.requestManager submitRequestModelNow:requestModel
                                  successBlock:^(NSString *requestId, EMSResponseModel *response) {
                                      if ([self.crypto verifyContent:response.body
                                                       withSignature:signatureData]) {
                                          if (response) {
                                              EMSRemoteConfig *remoteConfig = [self.remoteConfigResponseMapper map:response];
                                              [self.endpoint updateUrlsWithRemoteConfig:remoteConfig];
                                              [self.logger updateWithRemoteConfig:remoteConfig];
                                              [self overrideFeatureFlippers:remoteConfig];
                                              if (completionBlock) {
                                                  completionBlock(nil);
                                              }
                                          } else {
                                              if (completionBlock) {
                                                  completionBlock([NSError errorWithCode:400
                                                                    localizedDescription:@"No response"]);
                                              }
                                              [self.endpoint reset];
                                              [self.logger reset];
                                          }
                                      } else {
                                          if (completionBlock) {
                                              completionBlock([NSError errorWithCode:500
                                                                localizedDescription:@"Crypto error"]);
                                          }
                                          [self.endpoint reset];
                                          [self.logger reset];
                                      }
                                  }
                                    errorBlock:^(NSString *requestId, NSError *error) {
                                        if (completionBlock) {
                                            completionBlock(error);
                                        }
                                        if (error) {
                                            [self.endpoint reset];
                                            [self.logger reset];
                                        }
                                    }];
}

- (void)overrideFeatureFlippers:(EMSRemoteConfig *)remoteConfig {
    NSDictionary *featureMatrix = [remoteConfig features];
    NSNumber *mobileEngageFeature = featureMatrix[@"mobile_engage"];
    if (mobileEngageFeature) {
        if (mobileEngageFeature.boolValue) {
            [MEExperimental enableFeature:EMSInnerFeature.mobileEngage];
        } else {
            [MEExperimental disableFeature:EMSInnerFeature.mobileEngage];
        }
    }
    NSNumber *predictFeature = featureMatrix[@"predict"];
    if (predictFeature) {
        if (predictFeature.boolValue) {
            [MEExperimental enableFeature:EMSInnerFeature.predict];
        } else {
            [MEExperimental disableFeature:EMSInnerFeature.predict];
        }
    }
}

- (void)changeApplicationCode:(nullable NSString *)applicationCode
              completionBlock:(_Nullable EMSCompletionBlock)completionHandler; {
    [self changeApplicationCode:applicationCode
                 contactFieldId:[self.meRequestContext contactFieldId]
                completionBlock:completionHandler];
}

- (void)changeApplicationCode:(nullable NSString *)applicationCode
               contactFieldId:(NSNumber *)contactFieldId
              completionBlock:(_Nullable EMSCompletionBlock)completionHandler {
    NSData *pushToken = self.pushInternal.deviceToken;
    NSNumber *oldContactFieldId = self.meRequestContext.contactFieldId;
    __block NSError *error = nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (pushToken) {
            error = [self clearPushToken];
        }
        if (!error && self.meRequestContext.applicationCode && self.meRequestContext.contactFieldValue) {
            error = [self clearContact];
        }
        if (!error) {
            self.meRequestContext.contactFieldId = contactFieldId;
            self.meRequestContext.applicationCode = applicationCode;
            if (applicationCode) {
                [self sendDeviceInfo];
                if (pushToken) {
                    error = [self sendPushToken:pushToken];
                }
            }
        }
        if (error) {
            self.meRequestContext.applicationCode = nil;
            self.meRequestContext.contactFieldId = oldContactFieldId;
        }
        if (completionHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(error);
            });
        }
    });
}


- (NSError *)clearContact {
    __weak typeof(self) weakSelf = self;
    return [self synchronizeMethodWithRunnerBlock:^(EMSCompletionBlock completion) {
        [weakSelf.mobileEngage clearContactWithCompletionBlock:completion];
    }];
}

- (NSError *)clearPushToken {
    __weak typeof(self) weakSelf = self;
    return [self synchronizeMethodWithRunnerBlock:^(EMSCompletionBlock completion) {
        [weakSelf.pushInternal clearPushTokenWithCompletionBlock:completion];
    }];
}

- (NSError *)sendDeviceInfo {
    __weak typeof(self) weakSelf = self;
    return [self synchronizeMethodWithRunnerBlock:^(EMSCompletionBlock completion) {
        [weakSelf.deviceInfoClient sendDeviceInfoWithCompletionBlock:completion];
    }];
}

- (NSError *)sendPushToken:(NSData *)pushToken {
    __weak typeof(self) weakSelf = self;
    return [self synchronizeMethodWithRunnerBlock:^(EMSCompletionBlock completion) {
        [weakSelf.pushInternal setPushToken:pushToken
                            completionBlock:completion];
    }];
}

- (NSError *)synchronizeMethodWithRunnerBlock:(void (^)(EMSCompletionBlock completion))runnerBlock {
    __block NSError *result = [NSError errorWithCode:-1408
                                localizedDescription:@"SDK method timeout error"];
    [self.waiter enter];
    if (runnerBlock) {
        __weak typeof(self) weakSelf = self;
        EMSCompletionBlock completionBlock = ^(NSError *error) {
            result = error;
            [weakSelf.waiter exit];
        };
        runnerBlock(completionBlock);
    }
    [self.waiter waitWithInterval:METHOD_TIMEOUT];
    return result;
}

- (void)changeMerchantId:(nullable NSString *)merchantId {
    self.preRequestContext.merchantId = merchantId;
}

- (void)changeMerchantId:(NSString *)merchantId
         completionBlock:(EMSCompletionBlock)completionHandler {
    self.preRequestContext.merchantId = merchantId;
    [self.waiter enter];
    __weak typeof(self) weakSelf = self;
    [self.queue addOperationWithBlock:^{
        [weakSelf.waiter exit];
    }];
    [self.waiter waitWithInterval:5];
    if (completionHandler) {
        completionHandler(nil);
    }
}

- (NSString *)applicationCode {
    return self.meRequestContext.applicationCode;
}

- (NSString *)merchantId {
    return self.preRequestContext.merchantId;
}

- (NSNumber *)contactFieldId {
    return self.meRequestContext.contactFieldId;
}

- (void)setContactFieldId:(NSNumber *)contactFieldId {
    NSParameterAssert(contactFieldId);
    self.meRequestContext.contactFieldId = contactFieldId;
}

- (NSString *)hardwareId {
    return [self.deviceInfo hardwareId];
}

- (NSString *)languageCode {
    return [self.deviceInfo languageCode];
}

- (NSDictionary *)pushSettings {
    return [self.deviceInfo pushSettings];
}

@end
