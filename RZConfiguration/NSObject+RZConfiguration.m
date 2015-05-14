//
//  NSObject+RZConfiguration.m
//
//  Created by Rob Visentin on 5/11/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <objc/runtime.h>

#import "NSObject+RZConfiguration.h"

#import "RZDataBinding.h"

@implementation NSObject (RZConfiguration)

+ (NSDictionary *)rz_configurationBindings
{
    return [NSDictionary dictionary];
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
    @synchronized ( self ) {
        [self willChangeValueForKey:RZDB_KP_SELF(rz_configuration)];

        RZConfiguration *currentConfiguration = self.rz_configuration;

        if ( currentConfiguration != nil ) {
            [self rz_unbindFromConfiguration:currentConfiguration];
        }

        objc_setAssociatedObject(self, @selector(rz_configuration), configuration, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        if ( configuration != nil ) {
            [self rz_bindToConfiguration:configuration];
        }

        [self didChangeValueForKey:RZDB_KP_SELF(rz_configuration)];
    }
}

#pragma mark - private methods

+ (NSDictionary *)rz_cachedConfigurationBindings
{
    NSDictionary *cachedBindings = objc_getAssociatedObject(self, _cmd);

    if ( cachedBindings == nil ) {
        cachedBindings = [self rz_configurationBindings];
        objc_setAssociatedObject(self, _cmd, cachedBindings, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }

    return cachedBindings;
}

+ (SEL)rz_cachedActionForKey:(NSString *)key
{
    NSMutableDictionary *cachedActions = objc_getAssociatedObject(self, _cmd);

    if ( cachedActions == nil ) {
        cachedActions = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, _cmd, cachedActions, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
        objc_setAssociatedObject(self, _cmd, cachedTransforms, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
        objc_setAssociatedObject(self, _cmd, deferredBindings, OBJC_ASSOCIATION_RETAIN);
    }

    return deferredBindings;
}

- (void)rz_bindToConfiguration:(RZConfiguration *)configuration
{
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
            [self rz_configureAction:action forKeyPaths:keyPaths ofConfiguration:configuration];
        }
        else {
            [self rz_configureBindingsForKey:key toKeyPaths:keyPaths ofConfiguration:configuration];
        }
    }];
}

- (void)rz_unbindFromConfiguration:(RZConfiguration *)configuration
{
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

        for ( NSString *keyPath in keyPaths ) {
            [configuration rz_removeTarget:self action:NULL forKeyPathChange:keyPath];
            [self rz_unbindKey:key fromKeyPath:keyPath ofObject:configuration];
        }
    }];

    [[self rz_deferredBindings] removeAllObjects];
}

- (void)rz_configureAction:(SEL)action forKeyPaths:(NSArray *)keyPaths ofConfiguration:(RZConfiguration *)configuration
{
    if ( keyPaths.count > 0 ) {
        [configuration rz_addTarget:self action:action forKeyPathChanges:keyPaths];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:action withObject:nil];
#pragma pop
    }
    else if ( keyPaths.count == 1 ) {
        NSString *keyPath = [keyPaths firstObject];
        BOOL callImmediately = [configuration containsValueAtKeyPath:keyPath];
        [configuration rz_addTarget:self action:action forKeyPathChange:keyPath callImmediately:callImmediately];
    }
}

- (void)rz_configureBindingsForKey:(NSString *)key toKeyPaths:(NSArray *)keyPaths ofConfiguration:(RZConfiguration *)configuration
{
    RZDBKeyBindingTransform transform = [[self class] rz_configurationTransformForKey:key];

    for ( NSString *keyPath in keyPaths ) {
        __weak typeof(self) wself = self;
        dispatch_block_t bindingBlock = ^{
            [wself rz_bindKey:key toKeyPath:keyPath ofObject:wself.rz_configuration withTransform:transform];
        };

        if ( [configuration containsValueAtKeyPath:keyPath] ) {
            bindingBlock();
        }
        else {
            [self rz_deferredBindings][keyPath] = [bindingBlock copy];
            [configuration rz_addTarget:self action:@selector(rz_configureDeferredBinding:) forKeyPathChange:keyPath];
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

@implementation NSDictionary (RZConfigurationHelpers)

- (NSDictionary *)rz_dictionaryByAddingEntriesFromDictionary:(NSDictionary *)dict
{
    NSMutableDictionary *mutableSelf = [self mutableCopy];
    [mutableSelf addEntriesFromDictionary:dict];

    return [mutableSelf copy];
}

@end
