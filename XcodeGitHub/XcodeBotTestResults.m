//
/**
 @file          XcodeBotTestResults.m
 @package       XcodeGitHub
 @brief         < A brief description of the file function. >

 @author        Daniel Wetzel
 @date          2021
 @copyright     Copyright © 2021 Branch. All rights reserved.
*/

#import "XcodeBotTestResults.h"

@interface XcodeBotTestResults ()

@property (nonatomic, readwrite, copy) NSString *serverName;
@property (nonatomic, readwrite, copy) NSString *integrationID;


@end

@implementation XcodeBotTestResults

- (instancetype)initWithServerName:(NSString *)serverName integrationID:(NSString *)integrationID
{
    self = [super init];
    if (self) {
        self.serverName = serverName;
        self.integrationID= integrationID;
    }
    return self;
}

- (NSString *)digest
{
    return nil;
}

- (NSUInteger)fetchResults
{
    return 0;
}

@end
