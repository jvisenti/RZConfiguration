//
//  RZConfiguration.h
//
//  Created by Rob Visentin on 5/7/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RZConfiguration : NSObject

+ (id)defaultValueForKey:(NSString *)key;

- (BOOL)containsValueForKey:(NSString *)key;
- (BOOL)containsValueAtKeyPath:(NSString *)keyPath;

@end
