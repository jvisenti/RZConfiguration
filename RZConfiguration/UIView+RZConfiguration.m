//
//  UIView+RZConfiguration.m
//
//  Created by Rob Visentin on 5/12/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "UIView+RZConfiguration.h"

#import "RZDBMacros.h"

@implementation UIView (RZConfiguration)

+ (NSDictionary *)rz_configurationBindings
{
    NSMutableDictionary *bindings =
    [@{RZDB_KP(UIView, backgroundColor) : RZDB_KP(RZViewConfiguration, backgroundColor),
       RZDB_KP(UIView, tintColor) : RZDB_KP(RZViewConfiguration, tintColor),
       RZDB_KP(UIView, alpha) : RZDB_KP(RZViewConfiguration, alpha),
       RZDB_KP(UIView, hidden) : RZDB_KP(RZViewConfiguration, hidden)} mutableCopy];

    [bindings addEntriesFromDictionary:[super rz_configurationBindings]];

    return bindings;
}

@end

@implementation RZViewConfiguration

@dynamic backgroundColor;
@dynamic tintColor;
@dynamic alpha;
@dynamic hidden;

@end
