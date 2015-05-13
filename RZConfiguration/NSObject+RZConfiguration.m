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

@interface NSString (RZConfigurationHelpers)

- (NSString *)rz_stringByAddingPrefix:(NSString *)prefix;
- (NSString *)rz_stringByRemovingPrefix:(NSString *)prefix;

@end

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

- (NSMutableDictionary *)rz_deferredBindings
{
    NSMutableDictionary *deferredBindings = objc_getAssociatedObject(self, _cmd);

    if ( deferredBindings == nil ) {
        deferredBindings = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, _cmd, deferredBindings, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    return deferredBindings;
}

- (void)rz_configureBindings
{
    // TODO: these should be reconfigured if the configuration object changes
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

        if ( keyPaths.count == 0 && [value isKindOfClass:[NSString class]] ) {
            keyPaths = @[value];
        }

        SEL action = [[self class] rz_configurationActionForKey:key];

        if ( action != NULL ) {
            [self rz_configureAction:action forKeyPaths:keyPaths];
        }
        else {
            [self rz_configureBindingsForKey:key toKeyPaths:keyPaths];
        }
    }];
}

- (void)rz_configureAction:(SEL)action forKeyPaths:(NSArray *)keyPaths
{
    if ( keyPaths.count > 0 ) {
        NSMutableArray *prefixedKeyPaths = [NSMutableArray array];

        for ( NSString *keyPath in keyPaths) {
            [prefixedKeyPaths addObject:[keyPath rz_stringByAddingPrefix:kRZConfigurationKeyPathPrefix]];
        }

        [self rz_addTarget:self action:action forKeyPathChanges:prefixedKeyPaths];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:action withObject:nil];
#pragma pop
    }
    else if ( keyPaths.count == 1 ) {
        NSString *prefixedPath = [[keyPaths firstObject] rz_stringByAddingPrefix:kRZConfigurationKeyPathPrefix];
        NSString *unPrefixedPath = [[keyPaths firstObject] rz_stringByRemovingPrefix:kRZConfigurationKeyPathPrefix];

        BOOL callImmediately = [self.rz_configuration containsValueAtKeyPath:unPrefixedPath];
        [self rz_addTarget:self action:action forKeyPathChange:prefixedPath callImmediately:callImmediately];
    }
}

- (void)rz_configureBindingsForKey:(NSString *)key toKeyPaths:(NSArray *)keyPaths
{
    RZDBKeyBindingTransform transform = [[self class] rz_configurationTransformForKey:key];

    for ( NSString *keyPath in keyPaths ) {
        NSString *prefixedPath = [keyPath rz_stringByAddingPrefix:kRZConfigurationKeyPathPrefix];
        NSString *unPrefixedPath = [keyPath rz_stringByRemovingPrefix:kRZConfigurationKeyPathPrefix];

        __weak typeof(self) wself = self;
        dispatch_block_t bindingBlock = ^{
            [wself rz_bindKey:key toKeyPath:prefixedPath ofObject:wself withTransform:transform];
        };

        if ( [self.rz_configuration containsValueAtKeyPath:unPrefixedPath] ) {
            bindingBlock();
        }
        else {
            [self rz_deferredBindings][prefixedPath] = [bindingBlock copy];
            [self rz_addTarget:self action:@selector(rz_configureDeferredBinding:) forKeyPathChange:prefixedPath];
        }
    }
}

- (void)rz_configureDeferredBinding:(NSDictionary *)changeDict
{
    NSString *keyPath = changeDict[kRZDBChangeKeyKeyPath];

    NSMutableDictionary *deferredBindings = [self rz_deferredBindings];

    dispatch_block_t bindingBlock = deferredBindings[keyPath];

    if ( bindingBlock != nil ) {
        bindingBlock();
    }

    [deferredBindings removeObjectForKey:keyPath];
    [self rz_removeTarget:self action:_cmd forKeyPathChange:keyPath];
}

@end

@implementation NSString (RZConfigurationHelpers)

- (NSString *)rz_stringByAddingPrefix:(NSString *)prefix
{
    return [self hasPrefix:prefix] ? self : [prefix stringByAppendingString:self];
}

- (NSString *)rz_stringByRemovingPrefix:(NSString *)prefix
{
    NSRange prefixRange = [self rangeOfString:prefix];

    return prefixRange.location != 0 ? self : [self substringFromIndex:NSMaxRange(prefixRange)];
}

@end
