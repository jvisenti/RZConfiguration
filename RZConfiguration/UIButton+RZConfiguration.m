//
//  UIButton+RZConfiguration.m
//
//  Created by Rob Visentin on 5/13/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "UIButton+RZConfiguration.h"

static NSString* const kRZButtonImageKey = @"RZImage";
static NSString* const kRZButtonAttributedTitleKey = @"RZAttributedTitle";

@implementation UIButton (RZConfiguration)

+ (NSDictionary *)rz_configurationBindings
{
    NSArray *imageKeys = @[ RZDB_KP(RZButtonConfiguration, normalImage),
                            RZDB_KP(RZButtonConfiguration, highlightedImage),
                            RZDB_KP(RZButtonConfiguration, selectedImage),
                            RZDB_KP(RZButtonConfiguration, selectedHighlightedImage),
                            RZDB_KP(RZButtonConfiguration, disabledImage) ];

    NSArray *titleKeys = @[ RZDB_KP(RZButtonConfiguration, normalTextConfiguration.attributedString),
                            RZDB_KP(RZButtonConfiguration, highlightedTextConfiguration.attributedString),
                            RZDB_KP(RZButtonConfiguration, selectedTextConfiguration.attributedString),
                            RZDB_KP(RZButtonConfiguration, selectedHighlightedTextConfiguration.attributedString),
                            RZDB_KP(RZButtonConfiguration, disabledTextConfiguration.attributedString) ];

    NSDictionary *bindings = @{ kRZButtonImageKey : imageKeys,
                                kRZButtonAttributedTitleKey : titleKeys };

    return [[super rz_configurationBindings] rz_dictionaryByAddingEntriesFromDictionary:bindings];
}

+ (SEL)rz_configurationActionForKey:(NSString *)key
{
    SEL action = NULL;

    if ( [key isEqualToString:kRZButtonImageKey] ) {
        action = @selector(rz_imageChanged:);
    }
    else if ( [key isEqualToString:kRZButtonAttributedTitleKey] ) {
        action = @selector(rz_attributedTitleChanged:);
    }
    else {
        action = [super rz_configurationActionForKey:key];
    }

    return action;
}

#pragma mark - private methods

- (void)rz_imageChanged:(NSDictionary *)changeDict
{
    // TODO
}

- (void)rz_attributedTitleChanged:(NSDictionary *)changeDict
{
    // TODO
}

@end

@implementation RZButtonConfiguration

@dynamic normalImage;
@dynamic highlightedImage;
@dynamic selectedImage;
@dynamic selectedHighlightedImage;
@dynamic disabledImage;
@dynamic normalTextConfiguration;
@dynamic highlightedTextConfiguration;
@dynamic selectedTextConfiguration;
@dynamic selectedHighlightedTextConfiguration;
@dynamic disabledTextConfiguration;

+ (id)defaultValueForKey:(NSString *)key
{
    id defaultVal = nil;

    if ( [key hasSuffix:@"TextConfiguration"] ) {
        defaultVal = [[RZTextConfiguration alloc] init];
    }
    else {
        defaultVal = [super defaultValueForKey:key];
    }

    return defaultVal;
}

@end
