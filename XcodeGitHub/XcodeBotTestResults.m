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
#import "BNCLog.h"
#import "BNCNetworkService.h"
#import <XcodeGitHub-Swift.h>

@interface XcodeBotTestResults ()

@property (nonatomic, readwrite, retain) XGXcodeBot *bot;
@property (nonatomic, readwrite, copy) NSString *integrationID;

@property (nonatomic, readwrite, retain) NSArray <XcodeBotTestResult *> *tests;

@end

@implementation XcodeBotTestResults

- (instancetype)initWithBot:(XGXcodeBot *)bot integrationID:(NSString *)integrationID
{
    self = [super init];
    if (self) {
        self.bot = bot;
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
