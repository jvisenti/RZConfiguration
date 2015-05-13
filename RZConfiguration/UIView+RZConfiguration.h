//
//  UIView+RZConfiguration.h
//
//  Created by Rob Visentin on 5/12/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NSObject+RZConfiguration.h"

@class RZViewConfiguration;

@interface UIView (RZConfiguration)

@property (strong, nonatomic, setter=rz_setConfiguration:) RZViewConfiguration *rz_configuration;

@end

@interface RZViewConfiguration : RZConfiguration

@property (strong, nonatomic) UIColor *backgroundColor;
@property (strong, nonatomic) UIColor *tintColor;

@property (assign, nonatomic) CGFloat alpha;
@property (assign, nonatomic) BOOL hidden;

@end
