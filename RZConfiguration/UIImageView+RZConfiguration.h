//
//  UIImageView+RZConfiguration.h
//
//  Created by Rob Visentin on 5/13/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "UIView+RZConfiguration.h"

@class RZImageViewConfiguration;

@interface UIImageView (RZConfiguration)

@property (strong, nonatomic, setter=rz_setConfiguration:) RZImageViewConfiguration *rz_configuration;

@end

@interface RZImageViewConfiguration : RZViewConfiguration

@property (strong, nonatomic) UIImage *image;

@end
