//
//  UIButton+RZConfiguration.h
//
//  Created by Rob Visentin on 5/13/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "UIView+RZConfiguration.h"
#import "RZTextConfiguration.h"

@class RZButtonConfiguration;

@interface UIButton (RZConfiguration)

@property (strong, nonatomic, setter=rz_setConfiguration:) RZButtonConfiguration *rz_configuration;

@end

@interface RZButtonStateConfiguration : RZConfiguration

@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) UIImage *backgroundImage;

@property (strong, nonatomic) RZTextConfiguration *textConfiguration;

@end

@interface RZButtonConfiguration : RZViewConfiguration

@property (strong, nonatomic) RZButtonStateConfiguration *normalConfiguration;
@property (strong, nonatomic) RZButtonStateConfiguration *highlightedConfiguration;
@property (strong, nonatomic) RZButtonStateConfiguration *selectedConfiguration;
@property (strong, nonatomic) RZButtonStateConfiguration *selectedHighlightedConfiguration;
@property (strong, nonatomic) RZButtonStateConfiguration *disabledConfiguration;

@end
