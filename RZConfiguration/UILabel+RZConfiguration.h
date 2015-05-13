//
//  UILabel+RZConfiguration.h
//
//  Created by Rob Visentin on 5/12/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "UIView+RZConfiguration.h"

#import "RZTextConfiguration.h"

@class RZLabelConfiguration;

@interface UILabel (RZConfiguration)

@property (strong, nonatomic, setter=rz_setConfiguration:) RZLabelConfiguration *rz_configuration;

@end

@interface RZLabelConfiguration : RZConfiguration

@property (strong, nonatomic) RZViewConfiguration *viewConfiguration;
@property (strong, nonatomic) RZTextConfiguration *textConfiguration;

@end
