//
//  UILabel+RZConfiguration.m
//
//  Created by Rob Visentin on 5/12/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "UILabel+RZConfiguration.h"

#import "RZDBMacros.h"
#import "NSArray+RZConfigurationHelpers.h"

@implementation UILabel (RZConfiguration)

@dynamic rz_configuration;

+ (NSDictionary *)rz_configurationBindings
{
    NSMutableDictionary *bindings = [@{RZDB_KP(UILabel, attributedText) : RZDB_KP(RZLabelConfiguration, textConfiguration.attributedString)} mutableCopy];

    NSDictionary *superBindings = [super rz_configurationBindings];
    NSArray *prefixedValues = [superBindings.allValues rz_keyPathsByPrependingKey:RZDB_KP(RZLabelConfiguration, viewConfiguration)];

    superBindings = [NSDictionary dictionaryWithObjects:prefixedValues forKeys:superBindings.allKeys];

    [bindings addEntriesFromDictionary:superBindings];

    return bindings;
}

@end

@implementation RZLabelConfiguration

@dynamic viewConfiguration;
@dynamic textConfiguration;

+ (id)defaultValueForKey:(NSString *)key
{
    id defaultVal = nil;

    if ( [key isEqualToString:RZDB_KP(RZLabelConfiguration, viewConfiguration)] ) {
        defaultVal = [[RZViewConfiguration alloc] init];
    }
    else if ( [key isEqualToString:RZDB_KP(RZLabelConfiguration, textConfiguration)] ) {
        defaultVal = [[RZTextConfiguration alloc] init];
    }

    return defaultVal;
}

@end
