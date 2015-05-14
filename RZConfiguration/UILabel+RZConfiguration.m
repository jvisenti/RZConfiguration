//
//  UILabel+RZConfiguration.m
//
//  Created by Rob Visentin on 5/12/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "UILabel+RZConfiguration.h"

@implementation UILabel (RZConfiguration)

+ (NSDictionary *)rz_configurationBindings
{
    NSDictionary *bindings = @{RZDB_KP(UILabel, attributedText) : RZDB_KP(RZLabelConfiguration, textConfiguration.attributedString)};

    return [[super rz_configurationBindings] rz_dictionaryByAddingEntriesFromDictionary:bindings];
}

@end

@implementation RZLabelConfiguration

@dynamic textConfiguration;

+ (id)defaultValueForKey:(NSString *)key
{
    id defaultVal = nil;

    if ( [key isEqualToString:RZDB_KP(RZLabelConfiguration, textConfiguration)] ) {
        defaultVal = [[RZTextConfiguration alloc] init];
    }

    return defaultVal;
}

@end
