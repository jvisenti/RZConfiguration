//
//  RZConfiguration.m
//
//  Created by Rob Visentin on 5/7/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <objc/runtime.h>
#import <CoreGraphics/CGGeometry.h>
#import <QuartzCore/CATransform3D.h>

#import "RZConfiguration.h"

static void* const kRZConfigurationPropertyKey = (void *)&kRZConfigurationPropertyKey;

#define RZ_GETTER_BLOCK(key, type) \
^type (RZConfiguration *self) \
{ \
    if ( ![self.setKeys containsObject:key] ) { \
        id defaultVal = [[self class] defaultValueForKey:key]; \
        [self setValue:defaultVal forKey:key]; \
    } \
    id val = [self valueForUndefinedKey:key]; \
    type t; \
    [val getValue:&t]; \
    return t;\
}

#define RZ_SETTER_BLOCK(key, type, encoding) \
^void (RZConfiguration *self, type value) \
{ \
    @autoreleasepool { \
        NSValue *val = [NSValue valueWithBytes:&value objCType:encoding.UTF8String]; \
        [self setValue:val forUndefinedKey:key]; \
        [self.setKeys addObject:key]; \
    } \
}

#pragma mark - RZConfigurationProperty interface

@interface RZObjcProperty : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *typeEncoding;
@property (nonatomic, readonly) NSUInteger typeSize;

@property (nonatomic, readonly) SEL getter;
@property (nonatomic, readonly) SEL setter;

@property (nonatomic, readonly) NSString *getterTypeEncoding;
@property (nonatomic, readonly) NSString *setterTypeEncoding;

+ (instancetype)propertyWithObjCProperty:(objc_property_t)prop;

@end

#pragma mark - NSObject+RZProperties interface

@interface NSObject (RZProperties)

+ (CFDictionaryRef)rz_propertiesBySelector;
+ (NSDictionary *)rz_propertiesByKey;

+ (RZObjcProperty *)rz_propertyForSelector:(SEL)selector;
+ (RZObjcProperty *)rz_propertyForKey:(NSString *)key;

@end

#pragma mark - RZConfiguration private interface

@interface RZConfiguration ()

@property (strong, nonatomic) NSMutableDictionary *undefinedKeyValuePairs;
@property (strong, nonatomic) NSMutableSet *setKeys;

@end

#pragma mark - RZConfiguration implementation

@implementation RZConfiguration

- (instancetype)init
{
    self = [super init];
    if ( self ) {
        _undefinedKeyValuePairs = [NSMutableDictionary dictionary];
        _setKeys = [NSMutableSet set];
    }
    return self;
}

#pragma mark - KVC

+ (id)defaultValueForKey:(NSString *)key
{
    return nil;
}

- (id)valueForKey:(NSString *)key
{
    if ( ![self.setKeys containsObject:key] ) {
        id defaultVal = [[self class] defaultValueForKey:key];

        if ( defaultVal != nil ) {
            [self setValue:defaultVal forKey:key];
        }
    }

    return [super valueForKey:key];
}

- (id)valueForUndefinedKey:(NSString *)key
{
    return self.undefinedKeyValuePairs[key];
}

- (void)setValue:(id)value forKey:(NSString *)key
{
    if ( key != nil ) {
        [super setValue:value forKey:key];

        [self.setKeys addObject:key];
    }
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    if ( value != nil ) {
        self.undefinedKeyValuePairs[key] = value;
    }
    else {
        [self.undefinedKeyValuePairs removeObjectForKey:key];
    }
}

- (void)setNilValueForKey:(NSString *)key
{
    RZObjcProperty *prop = [[self class] rz_propertyForKey:key];

    if ( prop != nil) {
        void *zeroBytes = calloc(1, prop.typeSize);

        NSValue *val = [NSValue valueWithBytes:zeroBytes objCType:prop.typeEncoding.UTF8String];
        [self setValue:val forKey:key];

        free(zeroBytes);
    }
    else {
        [super setNilValueForKey:key];
    }
}

#pragma mark - method resolution (fallback when properties can't be synthesized)

+ (BOOL)resolveInstanceMethod:(SEL)sel
{
    BOOL resolved = NO;

    RZObjcProperty *prop = [self rz_propertyForSelector:sel];

    if ( prop != nil ) {
        resolved = [self synthesizeProperty:prop];
    }
    else {
        resolved = [super resolveInstanceMethod:sel];
    }

    return resolved;
}

+ (BOOL)instancesRespondToSelector:(SEL)aSelector
{
    BOOL respond = [super instancesRespondToSelector:aSelector];

    if ( !respond ) {
        respond = ([self rz_propertyForSelector:aSelector] != nil);
    }

    return respond;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [[self class] instancesRespondToSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *methodSig = nil;

    RZObjcProperty *prop = [[self class] rz_propertyForSelector:aSelector];

    if ( prop != nil ) {

        if ( prop != nil ) {
            if ( aSelector == prop.getter ) {
                methodSig = [NSMethodSignature signatureWithObjCTypes:prop.getterTypeEncoding.UTF8String];
            }
            else if ( aSelector == prop.setter ) {
                methodSig = [NSMethodSignature signatureWithObjCTypes:prop.setterTypeEncoding.UTF8String];
            }
        }

        if ( methodSig != nil ) {
            objc_setAssociatedObject(methodSig, kRZConfigurationPropertyKey, prop, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    else {
        methodSig = [super methodSignatureForSelector:aSelector];
    }

    return methodSig;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    RZObjcProperty *prop = objc_getAssociatedObject(anInvocation.methodSignature, kRZConfigurationPropertyKey);

    if ( prop != nil ) {
        if ( anInvocation.selector == prop.getter ) {
            [self forwardGetterInvocation:anInvocation forProperty:prop];
        }
        else if ( anInvocation.selector == prop.setter ) {
            [self forwardSetterInvocation:anInvocation forProperty:prop];
        }
    }
    else {
        [self doesNotRecognizeSelector:anInvocation.selector];
    }
}

#pragma mark - private methods

+ (void)getGetterBlock:(__autoreleasing id *)getter setterBlock:(__autoreleasing id *)setter forProperty:(RZObjcProperty *)prop
{
    id getRet, setRet;

    NSString *key = prop.name;
    NSString *encoding = prop.typeEncoding;

    const char *utf8Encoding = encoding.UTF8String;

    if ( strcmp(utf8Encoding, @encode(id)) == 0 ) {
        getRet = ^id (RZConfiguration *s) {
            if ( ![s.setKeys containsObject:key] ) {
                id defaultVal = [[s class] defaultValueForKey:key];
                [s setValue:defaultVal forKey:key];
            }

            return [s valueForUndefinedKey:key];
        };

        setRet = ^void (RZConfiguration *s, id val) {
            [s setValue:val forUndefinedKey:key];
            [s.setKeys addObject:key];
        };
    }
    else if ( strcmp(utf8Encoding, @encode(char)) == 0 ) {
        getRet = RZ_GETTER_BLOCK(key, char);
        setRet = RZ_SETTER_BLOCK(key, char, encoding);
    }
    else if ( strcmp(utf8Encoding, @encode(u_char)) == 0 ) {
        getRet = RZ_GETTER_BLOCK(key, u_char);
        setRet = RZ_SETTER_BLOCK(key, u_char, encoding);
    }
    else if ( strcmp(utf8Encoding, @encode(short)) == 0 ) {
        getRet = RZ_GETTER_BLOCK(key, short);
        setRet = RZ_SETTER_BLOCK(key, short, encoding);
    }
    else if ( strcmp(utf8Encoding, @encode(u_short)) == 0 ) {
        getRet = RZ_GETTER_BLOCK(key, u_short);
        setRet = RZ_SETTER_BLOCK(key, u_short, encoding);
    }
    else if ( strcmp(utf8Encoding, @encode(int)) == 0 ) {
        getRet = RZ_GETTER_BLOCK(key, int);
        setRet = RZ_SETTER_BLOCK(key, int, encoding);
    }
    else if ( strcmp(utf8Encoding, @encode(u_int)) == 0 ) {
        getRet = RZ_GETTER_BLOCK(key, u_int);
        setRet = RZ_SETTER_BLOCK(key, u_int, encoding);
    }
    else if ( strcmp(utf8Encoding, @encode(long)) == 0 ) {
        getRet = RZ_GETTER_BLOCK(key, long);
        setRet = RZ_SETTER_BLOCK(key, long, encoding);
    }
    else if ( strcmp(utf8Encoding, @encode(u_long)) == 0 ) {
        getRet = RZ_GETTER_BLOCK(key, u_long);
        setRet = RZ_SETTER_BLOCK(key, u_long, encoding);
    }
    else if ( strcmp(utf8Encoding, @encode(long long)) == 0 ) {
        getRet = RZ_GETTER_BLOCK(key, long long);
        setRet = RZ_SETTER_BLOCK(key, long long, encoding);
    }
    else if ( strcmp(utf8Encoding, @encode(unsigned long long)) == 0 ) {
        getRet = RZ_GETTER_BLOCK(key, unsigned long long);
        setRet = RZ_SETTER_BLOCK(key, unsigned long long, encoding);
    }
    else if ( strcmp(utf8Encoding, @encode(float)) == 0 ) {
        getRet = RZ_GETTER_BLOCK(key, float);
        setRet = RZ_SETTER_BLOCK(key, float, encoding);
    }
    else if ( strcmp(utf8Encoding, @encode(double)) == 0 ) {
        getRet = RZ_GETTER_BLOCK(key, double);
        setRet = RZ_SETTER_BLOCK(key, double, encoding);
    }
    else if ( strcmp(utf8Encoding, @encode(BOOL)) == 0 ) {
        getRet = RZ_GETTER_BLOCK(key, BOOL);
        setRet = RZ_SETTER_BLOCK(key, BOOL, encoding);
    }
    else if ( prop.typeSize == sizeof(CGPoint) ) {
        getRet = RZ_GETTER_BLOCK(key, CGPoint);
        setRet = RZ_SETTER_BLOCK(key, CGPoint, encoding);
    }
    else if ( prop.typeSize == sizeof(CGRect) ) {
        getRet = RZ_GETTER_BLOCK(key, CGRect);
        setRet = RZ_SETTER_BLOCK(key, CGRect, encoding);
    }
    else if ( prop.typeSize == sizeof(CGAffineTransform) ) {
        getRet = RZ_GETTER_BLOCK(key, CGAffineTransform);
        setRet = RZ_SETTER_BLOCK(key, CGAffineTransform, encoding);
    }
    else if ( prop.typeSize == sizeof(CATransform3D) ) {
        getRet = RZ_GETTER_BLOCK(key, CATransform3D);
        setRet = RZ_SETTER_BLOCK(key, CATransform3D, encoding);
    }

    if ( getter != NULL ) {
        *getter = getRet;
    }

    if ( setter != NULL ) {
        *setter = setRet;
    }
}

+ (BOOL)synthesizeProperty:(RZObjcProperty *)prop
{
    BOOL synthesized = NO;

    id getter, setter;
    [self getGetterBlock:&getter setterBlock:&setter forProperty:prop];

    if ( getter != nil && setter != nil ) {
        synthesized = YES;

        IMP getterIMP = imp_implementationWithBlock(getter);

        synthesized &= class_addMethod(self, prop.getter, getterIMP, prop.getterTypeEncoding.UTF8String);

        IMP setterIMP = imp_implementationWithBlock(setter);

        synthesized &= class_addMethod(self, prop.setter, setterIMP, prop.setterTypeEncoding.UTF8String);
    }

    return synthesized;
}

- (void)forwardGetterInvocation:(NSInvocation *)invocation forProperty:(RZObjcProperty *)property
{
    __unsafe_unretained id value = [self valueForKey:property.name];

    if ( strcmp(property.typeEncoding.UTF8String, @encode(id)) == 0 ) {
        [invocation setReturnValue:&value];
    }
    else {
        void *val = malloc(property.typeSize);
        [value getValue:val];

        [invocation setReturnValue:val];

        free(val);
    }
}

- (void)forwardSetterInvocation:(NSInvocation *)invocation forProperty:(RZObjcProperty *)property
{
    const char *typeEncoding = property.typeEncoding.UTF8String;

    if ( strcmp(typeEncoding, @encode(id)) == 0 ) {
        __unsafe_unretained id value = nil;
        [invocation getArgument:&value atIndex:2];

        [self setValue:value forKey:property.name];
    }
    else {
        void *primitiveVal = malloc(property.typeSize);
        [invocation getArgument:primitiveVal atIndex:2];

        NSValue *value = [NSValue valueWithBytes:primitiveVal objCType:typeEncoding];

        [self setValue:value forKey:property.name];

        free(primitiveVal);
    }
}

@end

#pragma mark - NSObject+RZProperties implementation

@implementation NSObject (RZProperties)

+ (void)rz_loadProperties
{
    CFMutableDictionaryRef propertiesBySel = CFDictionaryCreateMutable(NULL, 0, NULL, &kCFTypeDictionaryValueCallBacks);

    NSMutableDictionary *propertiesByKey = [NSMutableDictionary dictionary];

    unsigned int n;
    objc_property_t *properties = class_copyPropertyList(self, &n);

    for ( unsigned int i = 0; i < n; i++ ) {
        RZObjcProperty *property = [RZObjcProperty propertyWithObjCProperty:properties[i]];

        if ( property != nil ) {
            CFDictionaryAddValue(propertiesBySel, property.getter, (__bridge const void *)(property));
            CFDictionaryAddValue(propertiesBySel, property.setter, (__bridge const void *)(property));

            propertiesByKey[property.name] = property;
        }
    }

    free(properties);

    objc_setAssociatedObject(self, @selector(rz_propertiesBySelector), (__bridge NSDictionary *)propertiesBySel, OBJC_ASSOCIATION_COPY);
    objc_setAssociatedObject(self, @selector(rz_propertiesByKey), propertiesByKey, OBJC_ASSOCIATION_COPY);
}

+ (CFDictionaryRef)rz_propertiesBySelector
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self rz_loadProperties];
    });

    return (__bridge CFDictionaryRef)objc_getAssociatedObject(self, _cmd);
}

+ (NSDictionary *)rz_propertiesByKey
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self rz_loadProperties];
    });

    return objc_getAssociatedObject(self, _cmd);
}

+ (RZObjcProperty *)rz_propertyForSelector:(SEL)selector
{
    RZObjcProperty *property = nil;

    for ( Class cls = self; property == nil && cls != nil; cls = class_getSuperclass(cls) ) {
        CFDictionaryRef properties = [cls rz_propertiesBySelector];
        if ( properties != nil ) {
            property = CFDictionaryGetValue([cls rz_propertiesBySelector], selector);
        }
    }

    return property;
}

+ (RZObjcProperty *)rz_propertyForKey:(NSString *)key
{
    RZObjcProperty *property = nil;

    for ( Class cls = self; property == nil && cls != nil; cls = class_getSuperclass(cls) ) {
        property = [cls rz_propertiesByKey][key];
    }

    return property;
}

@end

#pragma mark - RZConfigurationProperty implementation

@implementation RZObjcProperty

+ (instancetype)propertyWithObjCProperty:(objc_property_t)prop
{
    RZObjcProperty *property = [[RZObjcProperty alloc] init];

    const char *name = property_getName(prop);

    if ( name != NULL ) {
        property->_name = [NSString stringWithUTF8String:name];
    }

    const char *attributes = property_getAttributes(prop);

    char *delim = strchr(attributes, ',');

    if ( delim != NULL ) {
        const char *start = attributes + 1;
        size_t len = (size_t)(delim - start);

        char *encoding = (char *)malloc(len + 1);
        memcpy(encoding, start, len);
        encoding[len] = '\0';

        property->_typeEncoding = [NSString stringWithUTF8String:encoding];
        NSGetSizeAndAlignment(encoding, &property->_typeSize, NULL);

        free(encoding);
    }

    const char *getterPtr = strstr(attributes, ",G");

    if ( getterPtr != NULL ) {
        property->_getter = [self selectorAt:getterPtr + 2];
    }
    else {
        property->_getter = NSSelectorFromString(property.name);
    }

    const char *setterPtr = strstr(attributes, ",S");

    if ( setterPtr != NULL ) {
        property->_setter = [self selectorAt:setterPtr + 2];
    }
    else {
        NSString *capName = [[property.name substringToIndex:1] uppercaseString];

        if ( property.name.length > 0 ) {
            capName = [capName stringByAppendingString:[property.name substringFromIndex:1]];
        }

        property->_setter = NSSelectorFromString([NSString stringWithFormat:@"set%@:", capName]);
    }

    char *typeSig = NULL;
    asprintf(&typeSig, "%s%s%s", property.typeEncoding.UTF8String, @encode(id), @encode(SEL));

    property->_getterTypeEncoding = [NSString stringWithUTF8String:typeSig];

    free(typeSig);

    typeSig = NULL;
    asprintf(&typeSig, "%s%s%s%s", @encode(void), @encode(id), @encode(SEL), property.typeEncoding.UTF8String);

    property->_setterTypeEncoding = [NSString stringWithUTF8String:typeSig];

    free(typeSig);

    return property;
}

+ (SEL)selectorAt:(const char *)start
{
    SEL selector = NULL;

    if ( start != NULL ) {
        char *delim = strchr(start, ',');

        if ( delim == NULL ) {
            selector = sel_getUid(start);
        }
        else {
            size_t len = (size_t)(delim - start);

            char *selStr = malloc(len + 1);
            memcpy(selStr, start, len);
            selStr[len] = '\0';
            
            selector = sel_getUid(selStr);

            free(selStr);
        }
    }
    
    return selector;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@, T:%@, G:%@, S:%@>", self.name, self.typeEncoding, NSStringFromSelector(self.getter), NSStringFromSelector(self.setter)];
}

@end
