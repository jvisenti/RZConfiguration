//
//  UIImageView+RZConfiguration.m
//
//  Created by Rob Visentin on 5/13/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "UIImageView+RZConfiguration.h"

@implementation UIImageView (RZConfiguration)

+ (NSDictionary *)rz_configurationBindings
{
    NSDictionary *bindings = @{ RZDB_KP(UIImageView, image) : RZDB_KP(RZImageViewConfiguration, image) };

    return [[super rz_configurationBindings] rz_dictionaryByAddingEntriesFromDictionary:bindings];
}

@end

@implementation RZImageViewConfiguration

@dynamic image;

@end