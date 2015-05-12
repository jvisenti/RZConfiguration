//
//  RZTextConfiguration.m
//
//  Created by Rob Visentin on 5/12/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZTextConfiguration.h"

#import "RZDataBinding.h"

@implementation RZTextConfiguration

@dynamic text;
@dynamic font;
@dynamic color;

@synthesize attributedString = _attributedString;

- (instancetype)init
{
    self = [super init];
    if ( self ) {
        [self rz_addTarget:self
                    action:@selector(invalidateAttributedString)
         forKeyPathChanges:[[[self class] keyPathsDrivingAttributedString] allObjects]];
    }
    return self;
}

+ (id)defaultValueForKey:(NSString *)key
{
    id value = nil;

    if ( [key isEqualToString:RZDB_KP(RZTextConfiguration, font)] ) {
        value = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    }
    else if ( [key isEqualToString:RZDB_KP(RZTextConfiguration, color)] ) {
        value = [UIColor blackColor];
    }
    else {
        value = [super defaultValueForKey:key];
    }

    return value;
}

- (void)willChangeValueForKey:(NSString *)key
{
    [super willChangeValueForKey:key];

    if ( [[[self class] keyPathsDrivingAttributedString] containsObject:key] ) {
        [self willChangeValueForKey:RZDB_KP_SELF(attributedString)];
    }
}

- (void)didChangeValueForKey:(NSString *)key
{
    [super didChangeValueForKey:key];

    if ( [[[self class] keyPathsDrivingAttributedString] containsObject:key] ) {
        [self invalidateAttributedString];
        [self didChangeValueForKey:RZDB_KP_SELF(attributedString)];
    }
}

- (NSAttributedString *)attributedString
{
    if ( _attributedString == nil ) {
        NSMutableAttributedString *attributedString = nil;

        if ( self.text != nil ) {
            UIColor *color = self.color ?: [UIColor blackColor];
            UIFont *font = self.font ?: [UIFont systemFontOfSize:[UIFont systemFontSize]];
            NSDictionary *attributes = @{
                                         NSForegroundColorAttributeName: color,
                                         NSFontAttributeName: font
                                         };

            attributedString = [[NSMutableAttributedString alloc] initWithString:self.text
                                                                      attributes:attributes];
        }

        _attributedString = [attributedString copy];
    }

    return _attributedString;
}

#pragma mark - private methods

+ (NSSet *)keyPathsDrivingAttributedString
{
    static NSSet *s_KeyPaths = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_KeyPaths = [NSSet setWithObjects:RZDB_KP(RZTextConfiguration, font), RZDB_KP(RZTextConfiguration, color), RZDB_KP(RZTextConfiguration, text), nil];
    });

    return s_KeyPaths;
}

- (void)invalidateAttributedString
{
    _attributedString = nil;
}

@end
