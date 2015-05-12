//
//  UILabel+RZConfiguration.h
//
//  Created by Rob Visentin on 5/12/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "NSObject+RZConfiguration.h"
#import "RZTextConfiguration.h"

@interface UILabel (RZConfiguration)

@property (strong, nonatomic, setter=rz_setConfiguration:) RZTextConfiguration *rz_configuration;

@end
