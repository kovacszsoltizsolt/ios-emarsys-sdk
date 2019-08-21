//
// Copyright (c) 2019 Emarsys. All rights reserved.
//
#import "EMSLoggingPredictInternal.h"
#import "EMSMacros.h"
#import "EMSMethodNotAllowed.h"

#define proto @protocol(EMSPredictProtocol)

@implementation EMSLoggingPredictInternal

- (void)trackCartWithCartItems:(NSArray<id <EMSCartItemProtocol>> *)cartItems {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"cartItems"] = [cartItems description];
    EMSLog([[EMSMethodNotAllowed alloc] initWithProtocol:proto
                                                     sel:_cmd
                                              parameters:parameters]);
}

- (void)trackPurchaseWithOrderId:(NSString *)orderId
                           items:(NSArray<id <EMSCartItemProtocol>> *)items {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"orderId"] = orderId;
    parameters[@"cartItems"] = [items description];
    EMSLog([[EMSMethodNotAllowed alloc] initWithProtocol:proto
                                                     sel:_cmd
                                              parameters:parameters]);
}

- (void)trackCategoryViewWithCategoryPath:(NSString *)categoryPath {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"categoryPath"] = categoryPath;
    EMSLog([[EMSMethodNotAllowed alloc] initWithProtocol:proto
                                                     sel:_cmd
                                              parameters:parameters]);
}

- (void)trackItemViewWithItemId:(NSString *)itemId {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"itemId"] = itemId;
    EMSLog([[EMSMethodNotAllowed alloc] initWithProtocol:proto
                                                     sel:_cmd
                                              parameters:parameters]);
}

- (void)trackSearchWithSearchTerm:(NSString *)searchTerm {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"searchTerm"] = searchTerm;
    EMSLog([[EMSMethodNotAllowed alloc] initWithProtocol:proto
                                                     sel:_cmd
                                              parameters:parameters]);
}

- (void)setContactWithContactFieldValue:(NSString *)contactFieldValue {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"customerId"] = contactFieldValue;
    EMSLog([[EMSMethodNotAllowed alloc] initWithProtocol:proto
                                                     sel:_cmd
                                              parameters:parameters]);
}

- (void)clearContact {
    EMSLog([[EMSMethodNotAllowed alloc] initWithProtocol:proto
                                                     sel:_cmd
                                              parameters:nil]);
}

- (void)trackTag:(NSString *)tag
  withAttributes:(nullable NSDictionary *)attributes {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"tag"] = tag;
    parameters[@"attributes"] = attributes;
    EMSLog([[EMSMethodNotAllowed alloc] initWithProtocol:proto
                                                     sel:_cmd
                                              parameters:parameters]);
}

- (void)recommendProducts:(EMSProductsBlock)productsBlock
                withLogic:(EMSLogic *)logic {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"productsBlock"] = @(productsBlock != nil);
    parameters[@"logic"] = logic;
    EMSLog([[EMSMethodNotAllowed alloc] initWithProtocol:proto
                                                     sel:_cmd
                                              parameters:parameters]);
}

- (void)recommendProducts:(EMSProductsBlock)productsBlock
                withLogic:(EMSLogic *)logic
                withLimit:(nullable NSNumber *)limit {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"productsBlock"] = @(productsBlock != nil);
    parameters[@"logic"] = logic;
    parameters[@"limit"] = limit;
    EMSLog([[EMSMethodNotAllowed alloc] initWithProtocol:proto
                                                     sel:_cmd
                                              parameters:parameters]);
}

- (void)recommendProducts:(EMSProductsBlock)productsBlock
                withLogic:(EMSLogic *)logic
               withFilter:(nullable NSArray<id <EMSRecommendationFilterProtocol>> *)filter {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"productsBlock"] = @(productsBlock != nil);
    parameters[@"logic"] = logic;
    parameters[@"filter"] = [filter description];
    EMSLog([[EMSMethodNotAllowed alloc] initWithProtocol:proto
                                                     sel:_cmd
                                              parameters:parameters]);
}

- (void)recommendProducts:(EMSProductsBlock)productsBlock
                withLogic:(EMSLogic *)logic
                withLimit:(nullable NSNumber *)limit
               withFilter:(nullable NSArray<id <EMSRecommendationFilterProtocol>> *)filter {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"productsBlock"] = @(productsBlock != nil);
    parameters[@"logic"] = logic;
    parameters[@"limit"] = limit;
    parameters[@"filter"] = [filter description];
    EMSLog([[EMSMethodNotAllowed alloc] initWithProtocol:proto
                                                     sel:_cmd
                                              parameters:parameters]);
}

@end