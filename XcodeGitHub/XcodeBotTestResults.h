//
/**
 @file          XcodeBotTestResults.h
 @package       XcodeGitHub
 @brief         < A brief description of the file function. >

 @author        Daniel Wetzel
 @date          2021
 @copyright     Copyright © 2021 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>
#import "XGXcodeBot.h"

NS_ASSUME_NONNULL_BEGIN

@interface XcodeBotTestResults : NSObject

@property (nonatomic, readonly) XGXcodeBot *bot;
@property (nonatomic, readonly) NSString *integrationID;

- (instancetype)initWithBot:(XGXcodeBot *)bot integrationID:(NSString *)integrationID;

- (NSUInteger)fetchResults;

- (nullable NSString *)digest;

@end

NS_ASSUME_NONNULL_END
