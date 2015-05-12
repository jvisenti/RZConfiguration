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
#import "NSObject+RZDataBinding.h"

static void* const kRZConfigurationPropertyKey = (void *)&kRZConfigurationPropertyKey;

#define RZ_GETTER_BLOCK(_key, _type) \
^_type (RZConfiguration *self) \
{ \
    if ( ![self isKeySet:_key] ) { \
        id defaultVal = [[self class] defaultValueForKey:_key]; \
        if ( defaultVal != nil ) { \
            [self setValue:defaultVal forKey:_key]; \
        } \
    } \
    id val = [self valueForUndefinedKey:_key]; \
    _type t; \
    [val getValue:&t]; \
    return t;\
}

#define RZ_SETTER_BLOCK(_key, _type, _encoding) \
^void (RZConfiguration *self, _type value) \
{ \
    @autoreleasepool { \
        [self.setKeys addObject:_key]; \
        [self setValue:[NSValue rz_wrapValue:&value encoding:_encoding.UTF8String]  forUndefinedKey:_key]; \
    } \
}

#pragma mark - NSValue+RZConfigurationExtensions interface

@interface NSValue (RZConfigurationExtensions)

+ (NSValue *)rz_wrapValue:(const void *)value encoding:(const char *)encoding;

@end

#pragma mark - RZConfigurationProperty interface

@interface RZObjcProperty : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *typeEncoding;
@property (nonatomic, readonly) NSUInteger typeSize;

@property (nonatomic, readonly, getter=isDynamic) BOOL dynamic;
@property (nonatomic, readonly, getter=isWeak) BOOL weak;
@property (nonatomic, readonly, getter=isCopy) BOOL copy;

@property (nonatomic, readonly, getter=isObject) BOOL object;

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
    if ( ![self isKeySet:key] ) {
        id defaultVal = [[self class] defaultValueForKey:key];

        if ( defaultVal != nil ) {
            [self setValue:defaultVal forKey:key];
        }
    }

    return [super valueForKey:key];
}

- (id)valueForUndefinedKey:(NSString *)key
{
    id value = self.undefinedKeyValuePairs[key];

    if ( [value isKindOfClass:[NSValue class]] ) {
        if ( [[self class] rz_propertyForKey:key].isWeak ) {
            value = [value nonretainedObjectValue];

            if ( value == nil ) {
                [self.undefinedKeyValuePairs removeObjectForKey:key];
            }
        }
    }

    return value;
}

- (void)setValue:(id)value forKey:(NSString *)key
{
    if ( key != nil ) {
        [self.setKeys addObject:key];
        [super setValue:value forKey:key];
    }
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    if ( value != nil ) {
        RZObjcProperty *prop = [[self class] rz_propertyForKey:key];

        if ( prop.isWeak ) {
            value = [NSValue valueWithNonretainedObject:value];
        }
        else if ( prop.isCopy ) {
            value = [value copy];
        }
        
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

        NSValue *val = [NSValue rz_wrapValue:zeroBytes encoding:prop.typeEncoding.UTF8String];
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

    if ( prop.isObject ) {
        getRet = ^id (RZConfiguration *self) {
            return [self valueForKey:key];
        };

        setRet = ^void (RZConfiguration *self, id val) {
            [self setValue:val forKey:key];
        };
    }
    else if ( strcmp(utf8Encoding, @encode(char)) == 0 ) {
        getRet = RZ_GETTER_BLOCK(key, char);
        setRet = RZ_SETTER_BLOCK(key, char, encoding);
    }
    else if ( strcmp(utf8Encoding, @encode(char *)) == 0 ) {
        getRet = RZ_GETTER_BLOCK(key, char *);
        setRet = RZ_SETTER_BLOCK(key, char *, encoding);
    }
    else if ( strcmp(utf8Encoding, @encode(void *)) == 0 ) {
        getRet = RZ_GETTER_BLOCK(key, void *);
        setRet = RZ_SETTER_BLOCK(key, void *, encoding);
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
    else if ( strcmp(utf8Encoding, @encode(SEL)) == 0 ) {
        getRet = RZ_GETTER_BLOCK(key, SEL);
        setRet = RZ_SETTER_BLOCK(key, SEL, encoding);
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

    if ( getter != nil ) {
        synthesized = YES;

        IMP getterIMP = imp_implementationWithBlock(getter);

        class_addMethod(self, prop.getter, getterIMP, prop.getterTypeEncoding.UTF8String);
    }

    if ( setter != nil ) {
        synthesized = YES;

        IMP setterIMP = imp_implementationWithBlock(setter);

        class_addMethod(self, prop.setter, setterIMP, prop.setterTypeEncoding.UTF8String);
    }

    return synthesized;
}

- (void)forwardGetterInvocation:(NSInvocation *)invocation forProperty:(RZObjcProperty *)property
{
    __unsafe_unretained id value = [self valueForKey:property.name];

    if ( property ) {
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

    if ( property.isObject ) {
        __unsafe_unretained id value = nil;
        [invocation getArgument:&value atIndex:2];

        [self setValue:value forKey:property.name];
    }
    else {
        void *primitiveVal = malloc(property.typeSize);
        [invocation getArgument:primitiveVal atIndex:2];

        NSValue *value = [NSValue rz_wrapValue:primitiveVal encoding:typeEncoding];

        [self setValue:value forKey:property.name];

        free(primitiveVal);
    }
}

- (BOOL)isKeySet:(NSString *)key
{
    return [self.setKeys containsObject:key] || ![[self class] rz_propertyForKey:key].isDynamic;
}

@end

#pragma mark - NSObject+RZProperties implementation

@implementation NSObject (RZProperties)

static dispatch_once_t s_PropertiesLoadedToken;

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
    dispatch_once(&s_PropertiesLoadedToken, ^{
        [self rz_loadProperties];
    });

    return (__bridge CFDictionaryRef)objc_getAssociatedObject(self, _cmd);
}

+ (NSDictionary *)rz_propertiesByKey
{
    dispatch_once(&s_PropertiesLoadedToken, ^{
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

        property->_object = encoding[0] == _C_ID || strcmp(encoding, @encode(Class)) == 0;

        free(encoding);
    }

    property->_dynamic = (strstr(attributes, ",D") != NULL);
    property->_weak = (strstr(attributes, ",W") != NULL);
    property->_copy = (strstr(attributes, ",C") != NULL);

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

#pragma mark - NSValue+RZConfigurationExtensions implementation

@implementation NSValue (RZConfigurationExtensions)

+ (NSValue *)rz_wrapValue:(const void *)value encoding:(const char *)encoding
{
    NSValue *wrappedValue = nil;

    if ( strcmp(encoding, @encode(char)) == 0 ) {
        wrappedValue = [NSNumber numberWithChar:*((char *)value)];
    }
    else if ( strcmp(encoding, @encode(unsigned char)) == 0 ) {
        wrappedValue = [NSNumber numberWithUnsignedChar:*((unsigned char *)value)];
    }
    else if ( strcmp(encoding, @encode(short)) == 0 ) {
        wrappedValue = [NSNumber numberWithShort:*((short *)value)];
    }
    else if ( strcmp(encoding, @encode(unsigned short)) == 0 ) {
        wrappedValue = [NSNumber numberWithUnsignedShort:*((unsigned short *)value)];
    }
    else if ( strcmp(encoding, @encode(int)) == 0 ) {
        wrappedValue = [NSNumber numberWithInt:*((int *)value)];
    }
    else if ( strcmp(encoding, @encode(unsigned int)) == 0 ) {
        wrappedValue = [NSNumber numberWithUnsignedInt:*((int *)value)];
    }
    else if ( strcmp(encoding, @encode(long)) == 0 ) {
        wrappedValue = [NSNumber numberWithLong:*((long *)value)];
    }
    else if ( strcmp(encoding, @encode(unsigned long)) == 0 ) {
        wrappedValue = [NSNumber numberWithUnsignedLong:*((unsigned long *)value)];
    }
    else if ( strcmp(encoding, @encode(long long)) == 0 ) {
        wrappedValue = [NSNumber numberWithLongLong:*((long long *)value)];
    }
    else if ( strcmp(encoding, @encode(unsigned long long)) == 0 ) {
        wrappedValue = [NSNumber numberWithUnsignedLongLong:*((unsigned long long *)value)];
    }
    else if ( strcmp(encoding, @encode(float)) == 0 ) {
        wrappedValue = [NSNumber numberWithFloat:*((float *)value)];
    }
    else if ( strcmp(encoding, @encode(double)) == 0 ) {
        wrappedValue = [NSNumber numberWithDouble:*((double *)value)];
    }
    else if ( strcmp(encoding, @encode(BOOL)) == 0 ) {
        wrappedValue = [NSNumber numberWithBool:*((BOOL *)value)];
    }
    else {
        wrappedValue = [NSValue valueWithBytes:value objCType:encoding];
    }

    return wrappedValue;
}

@end
