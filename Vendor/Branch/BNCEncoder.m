/**
 @file          BNCEncoder.m
 @package       Branch
 @brief         A light weight, general purpose object encoder.

 @author        Edward
 @date          June 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCEncoder.h"
#import "Logging.h"
#import <objc/runtime.h>

@implementation BNCEncoder

+ (NSError*_Nullable) decodeInstance:(id)instance
        withCoder:(NSCoder*)coder
        classes:(NSSet<Class>*)classes_
        ignoring:(NSArray<NSString*>*_Nullable)ignoreIvars_ {

    NSSet*ignoreIvars = nil;
    if (ignoreIvars_)
        ignoreIvars = [NSSet setWithArray:ignoreIvars_];

    NSMutableSet*classes = classes_ ? [classes_ mutableCopy] : [NSMutableSet new];

    uint count = 0;
    //Class class = object_getClass(instance); // Will return proxy class!
    Class class = [instance class];
    Ivar *ivars = class_copyIvarList(class, &count);
    for (uint i = 0; ivars && i < count; ++i) {
        Ivar ivar = ivars[i];
        const char* encoding = ivar_getTypeEncoding(ivars[i]);
        const char* ivarName = ivar_getName(ivars[i]);
        void* ivarPtr = nil;
        if (class == instance) {
            //  instance is a class, so there aren't any ivar values.
            continue;
        } else if (encoding[0] == '@' || encoding[0] == '#') {
            ivarPtr = (__bridge void*) object_getIvar(instance, ivars[i]);
        } else {
            ivarPtr = (void*) (((__bridge void*)instance) + ivar_getOffset(ivars[i]));
        }

        #define isTypeOf(type) \
            (strncmp(encoding, @encode(type), strlen(encoding)) == 0)

        NSString*key = [NSString stringWithFormat:@"%s", ivarName];
        if ([ignoreIvars containsObject:key])
            continue;

        if (encoding[0] == '@') {
            NSString *className = [NSString stringWithFormat:@"%s", encoding];
            if ([className hasPrefix:@"@\""])
                className = [className substringFromIndex:2];
            if ([className hasSuffix:@"\""])
                className = [className substringToIndex:className.length-1];
            //id value = [coder decodeObjectOfClass:NSClassFromString(className) forKey:key];
            [classes addObject:NSClassFromString(className)];
            id value = [coder decodeObjectOfClasses:classes forKey:key];
            object_setIvar(instance, ivar, value);
        }
        else if (isTypeOf(BOOL)) {
            *((BOOL*)ivarPtr) = [coder decodeBoolForKey:key];
        }
        else if (isTypeOf(NSInteger)) {
            *((NSInteger*)ivarPtr) = [coder decodeIntegerForKey:key];
        }
        else if (isTypeOf(CGFloat)) {
            *((CGFloat*)ivarPtr) = [coder decodeFloatForKey:key];
        }
        else if (isTypeOf(double)) {
            *((double*)ivarPtr) = [coder decodeDoubleForKey:key];
        }
        else {
            NSString*message = [NSString stringWithFormat:
                @"Couldn't decode '%s' type '%s'.", ivarName, encoding];
            LogError(@"%@", message);
            NSError*error = [NSError errorWithDomain:NSCocoaErrorDomain
                code:NSFormattingError userInfo:@{ NSLocalizedDescriptionKey: message }];
            return error;
        }
    }
    if (ivars) free(ivars);
    return nil;
}

+ (NSError*_Nullable) encodeInstance:(id)instance
        withCoder:(NSCoder*)coder
        ignoring:(NSArray<NSString*>*_Nullable)ignoreIvarsArray {

    NSSet*ignoreIvars = nil;
    if (ignoreIvarsArray)
        ignoreIvars = [NSSet setWithArray:ignoreIvarsArray];

    uint count = 0;
    //Class class = object_getClass(instance); // return the non-proxied object.
    Class class = [instance class];
    Ivar *ivars = class_copyIvarList(class, &count);
    for (uint i = 0; ivars && i < count; ++i) {
        const char* encoding = ivar_getTypeEncoding(ivars[i]);
        const char* ivarName = ivar_getName(ivars[i]);
        const void* ivarPtr = nil;
        if (class == instance) {
            //  instance is a class, so there aren't any ivar values.
        } else if (encoding[0] == '@' || encoding[0] == '#') {
            ivarPtr = (__bridge void*) object_getIvar(instance, ivars[i]);
        } else {
            ivarPtr = (void*) (((__bridge void*)instance) + ivar_getOffset(ivars[i]));
        }

        #define isTypeOf(type) \
            (strncmp(encoding, @encode(type), strlen(encoding)) == 0)

        NSString*key = [NSString stringWithFormat:@"%s", ivarName];
        if ([ignoreIvars containsObject:key])
            continue;

        if (encoding[0] == '@') {
            [coder encodeObject:(__bridge id<NSObject>)ivarPtr forKey:key];
        }
        else if (ivarPtr == NULL) {
            continue;
        }
        else if (isTypeOf(BOOL)) {
            [coder encodeBool:*((BOOL*)ivarPtr) forKey:key];
        }
        else if (isTypeOf(NSInteger)) {
            [coder encodeInteger:*((NSInteger*)ivarPtr) forKey:key];
        }
        else if (isTypeOf(CGFloat)) {
            [coder encodeFloat:*((CGFloat*)ivarPtr) forKey:key];
        }
        else if (isTypeOf(double)) {
            [coder encodeDouble:*((double*)ivarPtr) forKey:key];
        }
        else {
            NSString*message = [NSString stringWithFormat:
                @"Couldn't decode '%s' type '%s'.", ivarName, encoding];
            LogError(@"%@", message);
            NSError*error = [NSError errorWithDomain:NSCocoaErrorDomain
                code:NSFormattingError userInfo:@{ NSLocalizedDescriptionKey: message }];
            return error;
        }
    }
    if (ivars) free(ivars);
    return nil;
}

+ (NSData*) dataFromObject:(NSObject*)object ignoringIvars:(NSArray*)ignoreIvars error:(NSError**)error_ {
    NSError*error = nil;
    NSMutableData*data = nil;
    @try {
        data = [[NSMutableData alloc] init];
        NSKeyedArchiver*archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [BNCEncoder encodeInstance:object withCoder:archiver ignoring:ignoreIvars];
        [archiver finishEncoding];
    }
    @catch (id e) {
        NSString*message = [NSString stringWithFormat:@"Can't copy '%@': %@.", object, e];
        LogError(@"%@", message);
        error = [NSError errorWithDomain:NSCocoaErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey: message}];
    }
    if (error_) *error_ = error;
    return data;
}

+ (NSError*_Nullable) decodeObject:(NSObject*)object
        fromData:(NSData*)data
        classes:(NSSet<Class>*)classes
        ignoringIvars:(NSArray*_Nullable)ignoreIvars {
    NSError *error = nil;
    if (!object || !data) {
        return [NSError errorWithDomain:NSCocoaErrorDomain code:1 userInfo:@{
            NSLocalizedDescriptionKey: @"No object or data"
        }];
    }
        
    NSKeyedUnarchiver*unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:&error];
    if (error) {
        NSString*message = [NSString stringWithFormat:@"Can't decode '%@': %@.", object, error];
        LogError(@"%@", message);
        error = [NSError errorWithDomain:NSCocoaErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey: message}];
        return error;
    }
    unarchiver.requiresSecureCoding = NO;
    [BNCEncoder decodeInstance:object withCoder:unarchiver classes:classes ignoring:ignoreIvars];
    
    return error;
}

+ (NSError*) copyInstance:(id)toInstance
             fromInstance:(id)fromInstance
                 ignoring:(NSArray<NSString*>*_Nullable)ignoreIvarsArray {
    NSError*error = nil;
    
    NSMutableData *data = [[NSMutableData alloc] init];
    //NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initRequiringSecureCoding:NO];
    [BNCEncoder encodeInstance:fromInstance withCoder:archiver ignoring:ignoreIvarsArray];
    [archiver finishEncoding];
    NSKeyedUnarchiver*unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:&error];
    if (error) {
        NSString*message = [NSString stringWithFormat:@"Can't copy '%@': %@.", fromInstance, error];
        LogError(@"%@", message);
        error = [NSError errorWithDomain:NSCocoaErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey: message}];
        return error;
    }
    
    unarchiver.requiresSecureCoding = YES;
    [BNCEncoder decodeInstance:toInstance withCoder:unarchiver classes:nil ignoring:ignoreIvarsArray];
                
    return error;
}

@end

#pragma mark - BNCCoding

@implementation BNCCoding

+ (NSArray<NSString*>*) ignoreIvars {
    return @[];
}

+ (BOOL) supportsSecureCoding {
    return YES;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (!self) return self;
    NSError*error = [BNCEncoder decodeInstance:self withCoder:aDecoder classes:nil ignoring:self.class.ignoreIvars];
    if (error) LogError(@"Can't decode %@: %@", NSStringFromClass(self.class), error);
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    @synchronized (self) {
        NSError*error = [BNCEncoder encodeInstance:self withCoder:aCoder ignoring:self.class.ignoreIvars];
        if (error) LogError(@"Can't encode %@: %@", NSStringFromClass(self.class), error);
    }
}

@end
