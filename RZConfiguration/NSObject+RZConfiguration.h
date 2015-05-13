//
//  NSObject+RZConfiguration.h
//
//  Created by Rob Visentin on 5/11/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RZConfiguration.h"
#import "RZDBTransforms.h"

@interface NSObject (RZConfiguration)

@property (strong, nonatomic, setter=rz_setConfiguration:) RZConfiguration *rz_configuration;

+ (NSDictionary *)rz_configurationBindings;

+ (SEL)rz_configurationActionForKey:(NSString *)key;

+ (RZDBKeyBindingTransform)rz_configurationTransformForKey:(NSString *)key;

@end
