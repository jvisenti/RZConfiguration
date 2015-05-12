//
//  NSObject+RZConfiguration.m
//
//  Created by Rob Visentin on 5/11/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <objc/runtime.h>

#import "NSObject+RZConfiguration.h"

#import "RZDataBinding.h"

static NSString* const kRZConfigurationKeyPathPrefix = @"rz_configuration.";

@implementation NSObject (RZConfiguration)

+ (NSDictionary *)rz_configurationBindings
{
    return nil;
}

+ (SEL)rz_configurationActionForKey:(NSString *)key
{
    return NULL;
}

+ (RZDBKeyBindingTransform)rz_configurationTransformForKey:(NSString *)key
{
    return nil;
}

- (RZConfiguration *)rz_configuration
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)rz_setConfiguration:(RZConfiguration *)configuration
{
    [self willChangeValueForKey:RZDB_KP_SELF(rz_configuration)];

    objc_setAssociatedObject(self, @selector(rz_configuration), configuration, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    [self rz_configureBindings];

    [self didChangeValueForKey:RZDB_KP_SELF(rz_configuration)];
}

#pragma mark - private methods

+ (NSDictionary *)rz_cachedConfigurationBindings
{
    NSDictionary *cachedBindings = objc_getAssociatedObject(self, _cmd);

    if ( cachedBindings == nil ) {
        cachedBindings = [self rz_configurationBindings];
        objc_setAssociatedObject(self, _cmd, cachedBindings, OBJC_ASSOCIATION_COPY);
    }

    return cachedBindings;
}

+ (SEL)rz_cachedActionForKey:(NSString *)key
{
    NSMutableDictionary *cachedActions = objc_getAssociatedObject(self, _cmd);

    if ( cachedActions == nil ) {
        cachedActions = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, _cmd, cachedActions, OBJC_ASSOCIATION_RETAIN);
    }

    SEL action = NULL;

    id cachedAction = cachedActions[key];

    if ( cachedAction == nil ) {
        action = [self rz_configurationActionForKey:key];
        cachedActions[key] = (action != NULL) ? [NSValue valueWithPointer:action] : [NSNull null];
    }
    else if ( [cachedAction isKindOfClass:[NSValue class]] ) {
        action = [cachedAction pointerValue];
    }

    return action;
}

+ (RZDBKeyBindingTransform)rz_cachedTransformForKey:(NSString *)key
{
    NSMutableDictionary *cachedTransforms = objc_getAssociatedObject(self, _cmd);

    if ( cachedTransforms == nil ) {
        cachedTransforms = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, _cmd, cachedTransforms, OBJC_ASSOCIATION_RETAIN);
    }

    RZDBKeyBindingTransform transform = nil;

    id cachedTransform = cachedTransforms[key];

    if ( cachedTransform == nil ) {
        transform = [self rz_configurationTransformForKey:key];
        cachedTransforms[key] = (transform != nil) ? [transform copy] : [NSNull null];
    }
    else if ( ![cachedTransform isEqual:[NSNull null]] ) {
        transform = cachedTransform;
    }

    return transform;
}

- (void)rz_configureBindings
{
    if ( [objc_getAssociatedObject(self, _cmd) boolValue] ) {
        return;
    }

    objc_setAssociatedObject(self, _cmd, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    NSDictionary *bindings = [[self class] rz_cachedConfigurationBindings];

    [bindings enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        NSArray *keyPaths = nil;

        if ( [value isKindOfClass:[NSArray class]] ) {
            keyPaths = value;
        }
        else if ( [value isKindOfClass:[NSSet class]] ) {
            keyPaths = [value allObjects];
        }

        NSMutableArray *prefixedKeyPaths = [NSMutableArray array];

        for ( NSString *keyPath in keyPaths) {
            if ( [keyPath isKindOfClass:[NSString class]] ) {
                if ( [keyPath hasPrefix:kRZConfigurationKeyPathPrefix] ) {
                    [prefixedKeyPaths addObject:keyPath];
                }
                else {
                    [prefixedKeyPaths addObject:[kRZConfigurationKeyPathPrefix stringByAppendingString:keyPath]];
                }
            }
        }

        keyPaths = prefixedKeyPaths;

        SEL action = [[self class] rz_configurationActionForKey:key];

        if ( action != NULL ) {
            if ( keyPaths.count > 0 ) {
                [self rz_addTarget:self action:action forKeyPathChanges:keyPaths];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [self performSelector:action withObject:nil];
#pragma pop
            }
            else if ( [value isKindOfClass:[NSString class]] ) {
                [self rz_addTarget:self action:action forKeyPathChange:value callImmediately:YES];
            }
        }
        else {
            RZDBKeyBindingTransform transform = [[self class] rz_configurationTransformForKey:key];

            if ( keyPaths.count == 0 && [value isKindOfClass:[NSString class]] ) {
                keyPaths = @[[kRZConfigurationKeyPathPrefix stringByAppendingString:value]];
            }

            for ( NSString *keyPath in keyPaths ) {
                [self rz_bindKey:key toKeyPath:keyPath ofObject:self withTransform:transform];
            }
        }
    }];
}

@end
