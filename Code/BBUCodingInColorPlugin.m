//
//  BBUCodingInColorPlugin.m
//  BBUCodingInColorPlugin
//
//  Created by Boris Bügling on 28.01.14.
//    Copyright (c) 2014 Boris Bügling. All rights reserved.
//

#import <NSObject+YOLO/NSObject+YOLO.h>

#import "BBUCodingInColorPlugin.h"
#import "BBUIndexHelper.h"
#import "OhNoMoreXcodeInterfaces.h"

#pragma mark -

@interface BBUCodingInColorPlugin ()

@property (nonatomic, strong) BBUIndexHelper* indexHelper;
@property (nonatomic, assign) NSTextView* textView;

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
    for (DVTSourceModelItem* sourceItem in children) {
        if ([sourceItem isIdentifier]) {
            NSRange range = [sourceItem range];
            if (self.textView.string.length < range.location + range.length) {
                continue;
            }
            
            NSString* sourceCode = [self.textView.string substringWithRange:range];
            if ([self.indexHelper isVariableSymbol:sourceCode]) {
                [self.textView setTextColor:[NSColor yellowColor] range:range];
            }
            
            //NSLog(@"BBUCodingInColor: item %@", soureCode);
        } else {
            [self handleChildren:[sourceItem children]];
        }
    }
}

#pragma mark -

- (id)initWithBundle:(NSBundle *)plugin {
    if (self = [super init]) {
        self.indexHelper = [BBUIndexHelper new];
        
        [[DVTSourceTextView new] yl_swizzleSelector:@selector(_commonInitDVTSourceTextView)
                                          withBlock:^(DVTSourceTextView* sself) {
                                              [sself yl_performSelector:@selector(_commonInitDVTSourceTextView)
                                                          returnAddress:NULL
                                                      argumentAddresses:NULL];
                                              
                                              self.textView = sself;
                                          }];
        
        [[DVTTextStorage new] yl_swizzleSelector:@selector(fixSyntaxColoringInRange:)
                                       withBlock:^(DVTTextStorage* sself, NSRange range) {
                                           [sself yl_performSelector:@selector(fixSyntaxColoringInRange:) returnAddress:NULL argumentAddresses:&range, NULL];
                                           
                                           [self handleChildren:sself.sourceModel.sourceItems.children];
                                       }];
        
        [[DVTTextStorage new] yl_swizzleSelector:@selector(colorAtCharacterIndex:effectiveRange:context:)
                                       withBlock:^NSColor*(DVTTextStorage* sself, unsigned long long charIndex,
                                                           NSRangePointer rangePointer, id context) {
                                           NSRange range = *rangePointer;
                                           NSLog(@"range: %@", NSStringFromRange(range));
                                           
                                           if (range.location + range.length < self.textView.string.length) {
                                               NSString* string = [self.textView.string substringWithRange:range];
                                               NSLog(@"coloring %@", string);
                                               
                                               if ([self.indexHelper isVariableSymbol:string]) {
                                                   return [NSColor yellowColor];
                                               }
                                           }
                                           
                                           return [sself yl_colorAtCharacterIndex:charIndex
                                                                   effectiveRange:rangePointer
                                                                          context:context];
                                       }];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
