//
//  BBUCodingInColorPlugin.m
//  BBUCodingInColorPlugin
//
//  Created by Boris Bügling on 28.01.14.
//    Copyright (c) 2014 Boris Bügling. All rights reserved.
//

#import <NSObject+YOLO/NSObject+YOLO.h>
#import <objc/runtime.h>

#import "BBUCodingInColorPlugin.h"

@interface NSObject (Private)

@property id sourceItems;
@property id sourceModel;

-(void)_commonInitDVTSourceTextView;
-(void)fixSyntaxColoringInRange:(NSRange)range;
-(BOOL)isIdentifier;

@end

#pragma mark -

@interface BBUCodingInColorPlugin ()

@property NSTextView* textView;

@end

#pragma mark -

@implementation BBUCodingInColorPlugin

+ (void)pluginDidLoad:(NSBundle *)plugin {
    static id sharedPlugin = nil;
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];
        });
    }
}

- (void)handleChildren:(NSArray*)children {
    for (id sourceItem in children) {
        if ([sourceItem isIdentifier]) {
            NSRange range = [sourceItem range];
            if (self.textView.string.length < range.location + range.length) {
                continue;
            }
            
            [self.textView setTextColor:[NSColor yellowColor] range:range];
        } else {
            [self handleChildren:[sourceItem children]];
        }
    }
}

- (id)initWithBundle:(NSBundle *)plugin {
    if (self = [super init]) {
        [[objc_getClass("DVTSourceTextView") new] yl_swizzleSelector:@selector(_commonInitDVTSourceTextView)
                                                           withBlock:^(id sself) {
                                                               [sself yl_performSelector:@selector(_commonInitDVTSourceTextView) returnAddress:NULL argumentAddresses:NULL];
                                                               
                                                               self.textView = sself;
                                                           }];
        
        [[objc_getClass("DVTTextStorage") new] yl_swizzleSelector:@selector(fixSyntaxColoringInRange:)
                                                        withBlock:^(id sself, NSRange range) {
                                                            [sself yl_performSelector:@selector(fixSyntaxColoringInRange:) returnAddress:NULL argumentAddresses:&range, NULL];
                                                            
                                                            [self handleChildren:[[[sself sourceModel] sourceItems] children]];
                                                        }];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
