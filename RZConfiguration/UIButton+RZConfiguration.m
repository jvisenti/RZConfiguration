//
//  UIButton+RZConfiguration.m
//
//  Created by Rob Visentin on 5/13/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "UIButton+RZConfiguration.h"

#import "NSObject+RZDataBinding.h"

static NSString* const kRZButtonImageKey = @"RZImage";
static NSString* const kRZButtonBackgroundImageKey = @"RZBackgroundImage";
static NSString* const kRZButtonAttributedTitleKey = @"RZAttributedTitle";

@implementation UIButton (RZConfiguration)

+ (NSDictionary *)rz_configurationBindings
{
    NSArray *imageKeys = @[ RZDB_KP(RZButtonConfiguration, normalConfiguration.image),
                            RZDB_KP(RZButtonConfiguration, highlightedConfiguration.image),
                            RZDB_KP(RZButtonConfiguration, selectedConfiguration.image),
                            RZDB_KP(RZButtonConfiguration, selectedHighlightedConfiguration.image),
                            RZDB_KP(RZButtonConfiguration, disabledConfiguration.image) ];

    NSArray *backgroundImageKeys = @[ RZDB_KP(RZButtonConfiguration, normalConfiguration.backgroundImage),
                            RZDB_KP(RZButtonConfiguration, highlightedConfiguration.backgroundImage),
                            RZDB_KP(RZButtonConfiguration, selectedConfiguration.backgroundImage),
                            RZDB_KP(RZButtonConfiguration, selectedHighlightedConfiguration.backgroundImage),
                            RZDB_KP(RZButtonConfiguration, disabledConfiguration.backgroundImage) ];

    NSArray *titleKeys = @[ RZDB_KP(RZButtonConfiguration, normalConfiguration.textConfiguration.attributedString),
                            RZDB_KP(RZButtonConfiguration, highlightedConfiguration.textConfiguration.attributedString),
                            RZDB_KP(RZButtonConfiguration, selectedConfiguration.textConfiguration.attributedString),
                            RZDB_KP(RZButtonConfiguration, selectedHighlightedConfiguration.textConfiguration.attributedString),
                            RZDB_KP(RZButtonConfiguration, disabledConfiguration.textConfiguration.attributedString) ];

    NSDictionary *bindings = @{ kRZButtonImageKey : imageKeys,
                                kRZButtonBackgroundImageKey : backgroundImageKeys,
                                kRZButtonAttributedTitleKey : titleKeys };

    return [[super rz_configurationBindings] rz_dictionaryByAddingEntriesFromDictionary:bindings];
}

+ (SEL)rz_configurationActionForKey:(NSString *)key
{
    SEL action = NULL;

    if ( [key isEqualToString:kRZButtonImageKey] ) {
        action = @selector(rz_imageChanged:);
    }
    else if ( [key isEqualToString:kRZButtonBackgroundImageKey] ) {
        action = @selector(rz_backgroundImageChanged:);
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
    UIControlState state = [self rz_controlStateForChangedKeyPath:changeDict[kRZDBChangeKeyKeyPath]];

    [self setImage:changeDict[kRZDBChangeKeyNew] forState:state];
}

- (void)rz_backgroundImageChanged:(NSDictionary *)changeDict
{
    UIControlState state = [self rz_controlStateForChangedKeyPath:changeDict[kRZDBChangeKeyKeyPath]];

    [self setBackgroundImage:changeDict[kRZDBChangeKeyNew] forState:state];
}

- (void)rz_attributedTitleChanged:(NSDictionary *)changeDict
{
    UIControlState state = [self rz_controlStateForChangedKeyPath:changeDict[kRZDBChangeKeyKeyPath]];

    [self setAttributedTitle:changeDict[kRZDBChangeKeyNew] forState:state];
}

- (UIControlState)rz_controlStateForChangedKeyPath:(NSString *)keyPath
{
    RZButtonConfiguration *configuration = self.rz_configuration;
    UIControlState state = UIControlStateNormal;

    NSRange dotRange = [keyPath rangeOfString:@"."];

    if ( dotRange.location != NSNotFound ) {
        NSString *key = [keyPath substringToIndex:dotRange.location];
        RZButtonStateConfiguration *stateConfig = [configuration valueForKey:key];

        if ( configuration.highlightedConfiguration != nil &&
            stateConfig == configuration.highlightedConfiguration ) {
            state = UIControlStateHighlighted;
        }
        else if ( configuration.selectedConfiguration != nil &&
                 stateConfig == configuration.selectedConfiguration ) {
            state = UIControlStateSelected;
        }
        else if ( configuration.selectedHighlightedConfiguration != nil &&
                 stateConfig == configuration.selectedHighlightedConfiguration ) {
            state = UIControlStateSelected | UIControlStateHighlighted;
        }
        else if ( configuration.disabledConfiguration != nil &&
                 stateConfig == configuration.disabledConfiguration ) {
            state = UIControlStateDisabled;
        }
    }

    return state;
}

@end

@implementation RZButtonStateConfiguration

@dynamic image;
@dynamic backgroundImage;
@dynamic textConfiguration;

+ (id)defaultValueForKey:(NSString *)key
{
    id defaultVal = nil;

    if ( [key isEqualToString:RZDB_KP(RZButtonStateConfiguration, textConfiguration)] ) {
        defaultVal = [[RZTextConfiguration alloc] init];
    }
    else {
        defaultVal = [super defaultValueForKey:key];
    }

    return defaultVal;
}

@end

@implementation RZButtonConfiguration

@dynamic normalConfiguration;
@dynamic highlightedConfiguration;
@dynamic selectedConfiguration;
@dynamic selectedHighlightedConfiguration;
@dynamic disabledConfiguration;

+ (id)defaultValueForKey:(NSString *)key
{
    static NSArray *s_ConfigurationKeys = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_ConfigurationKeys = @[ RZDB_KP(RZButtonConfiguration, normalConfiguration),
                                        RZDB_KP(RZButtonConfiguration, highlightedConfiguration),
                                        RZDB_KP(RZButtonConfiguration, selectedConfiguration),
                                        RZDB_KP(RZButtonConfiguration, selectedHighlightedConfiguration),
                                        RZDB_KP(RZButtonConfiguration, disabledConfiguration) ];
    });

    id defaultVal = nil;

    if ( [s_ConfigurationKeys containsObject:key] ) {
        defaultVal = [[RZButtonStateConfiguration alloc] init];
    }
    else {
        defaultVal = [super defaultValueForKey:key];
    }

    return defaultVal;
}

@end
