//
//  UILabel+RZConfiguration.m
//
//  Created by Rob Visentin on 5/12/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "UILabel+RZConfiguration.h"
#import "RZDBMacros.h"

@implementation UILabel (RZConfiguration)

@dynamic rz_configuration;

+ (NSDictionary *)rz_configurationBindings
{
    return @{ RZDB_KP(UILabel, attributedText) : RZDB_KP(RZTextConfiguration, attributedString) };
}

@end
