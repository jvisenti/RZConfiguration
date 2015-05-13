//
//  NSArray+RZConfigurationHelpers.h
//
//  Created by Rob Visentin on 5/12/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (RZConfigurationHelpers)

- (NSArray *)rz_keyPathsByPrependingKey:(NSString *)prefixKey;
- (NSArray *)rz_keyPathsByAppendingKey:(NSString *)suffixKey;

@end
