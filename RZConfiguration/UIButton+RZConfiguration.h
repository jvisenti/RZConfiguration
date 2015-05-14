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

@interface RZButtonConfiguration : RZViewConfiguration

@property (strong, nonatomic) UIImage *normalImage;
@property (strong, nonatomic) UIImage *highlightedImage;
@property (strong, nonatomic) UIImage *selectedImage;
@property (strong, nonatomic) UIImage *selectedHighlightedImage;
@property (strong, nonatomic) UIImage *disabledImage;

@property (strong, nonatomic) RZTextConfiguration *normalTextConfiguration;
@property (strong, nonatomic) RZTextConfiguration *highlightedTextConfiguration;
@property (strong, nonatomic) RZTextConfiguration *selectedTextConfiguration;
@property (strong, nonatomic) RZTextConfiguration *selectedHighlightedTextConfiguration;
@property (strong, nonatomic) RZTextConfiguration *disabledTextConfiguration;

@end
