//
//  RZTextConfiguration.h
//
//  Created by Rob Visentin on 5/12/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RZConfiguration.h"

@interface RZTextConfiguration : RZConfiguration

@property (copy, nonatomic) NSString *text;
@property (strong, nonatomic) UIFont *font;
@property (strong, nonatomic) UIColor *color;

@property (copy, nonatomic, readonly) NSAttributedString *attributedString;

@end
