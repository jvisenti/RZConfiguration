//
//  UIView+RZConfiguration.m
//
//  Created by Rob Visentin on 5/12/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "UIView+RZConfiguration.h"

@implementation UIView (RZConfiguration)

+ (NSDictionary *)rz_configurationBindings
{
    NSDictionary *bindings =
  @{ RZDB_KP(UIView, backgroundColor) : RZDB_KP(RZViewConfiguration, backgroundColor),
     RZDB_KP(UIView, tintColor) : RZDB_KP(RZViewConfiguration, tintColor),
     RZDB_KP(UIView, alpha) : RZDB_KP(RZViewConfiguration, alpha),
     RZDB_KP(UIView, hidden) : RZDB_KP(RZViewConfiguration, hidden) };

    return [[super rz_configurationBindings] rz_dictionaryByAddingEntriesFromDictionary:bindings];
}

+ (RZDBKeyBindingTransform)rz_configurationTransformForKey:(NSString *)key
{
    RZDBKeyBindingTransform transform = nil;

    if ( [key isEqualToString:RZDB_KP(UIView, alpha)] ) {
        transform = kRZDBNilToOneTransform;
    }
    else if ( [key isEqualToString:RZDB_KP(UIView, hidden)] ) {
        transform = kRZDBNilToZeroTransform;
    }
    else {
        transform = [super rz_configurationTransformForKey:key];
    }

    return transform;
}

@end

@implementation RZViewConfiguration

@dynamic backgroundColor;
@dynamic tintColor;
@dynamic alpha;
@dynamic hidden;

@end
