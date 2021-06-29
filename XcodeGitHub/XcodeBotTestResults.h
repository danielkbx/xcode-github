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

NS_ASSUME_NONNULL_BEGIN

@interface XcodeBotTestResults : NSObject

@property (nonatomic, readonly) NSString *serverName;
@property (nonatomic, readonly) NSString *integrationID;

- (instancetype)initWithServerName:(NSString *)serverName integrationID:(NSString *)integrationID;

- (NSUInteger)fetchResults;

- (nullable NSString *)digest;

@end

NS_ASSUME_NONNULL_END
