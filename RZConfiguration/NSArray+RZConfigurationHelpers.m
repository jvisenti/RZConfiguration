//
//  NSArray+RZConfigurationHelpers.m
//
//  Created by Rob Visentin on 5/12/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "NSArray+RZConfigurationHelpers.h"

@implementation NSArray (RZConfigurationHelpers)

- (NSArray *)rz_keyPathsByPrependingKey:(NSString *)prefixKey
{
    return [self rz_arrayMapWithBlock:^id(id obj) {
        return [prefixKey stringByAppendingFormat:@".%@", obj];
    }];
}

- (NSArray *)rz_keyPathsByAppendingKey:(NSString *)suffixKey
{
    return [self rz_arrayMapWithBlock:^id(id obj) {
        return [obj stringByAppendingFormat:@".%@", suffixKey];
    }];
}

#pragma mark - private helpers

- (NSArray *)rz_arrayMapWithBlock:(id (^)(id obj))block
{
    NSMutableArray *mapArray = [NSMutableArray array];

    for (id object in self ) {
        id result = block(object);

        if ( result != nil ) {
            [mapArray addObject:result];
        }
    }

    return [mapArray copy];
}

@end
