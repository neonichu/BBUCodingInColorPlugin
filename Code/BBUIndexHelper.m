//
//  BBUIndexHelper.m
//  BBUCodingInColorPlugin
//
//  Created by Boris Bügling on 01.02.14.
//  Copyright (c) 2014 Boris Bügling. All rights reserved.
//
//  Took lots of inspiration from Macoscope's CodePilot for this.
//

#import "BBUIndexHelper.h"
#import "CPXcodeInterfaces.h"

static NSString * const IDEIndexDidIndexWorkspaceNotification = @"IDEIndexDidIndexWorkspaceNotification";

@interface BBUIndexHelper ()

@property NSMutableArray* variableSymbols;

@end

#pragma mark -

@implementation BBUIndexHelper

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:IDEIndexDidIndexWorkspaceNotification object:nil];
}

-(void)didIndexWorkspace:(NSNotification*)note {
    for (IDEWorkspace* workspace in [self openWorkspaces]) {
        if (workspace.index == note.object) {
            [self updateSymbolCacheForWorkspace:workspace];
        }
    }
}

-(id)init {
    self = [super init];
    if (self) {
        self.variableSymbols = [@[] mutableCopy];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didIndexWorkspace:)
                                                     name:IDEIndexDidIndexWorkspaceNotification
                                                   object:nil];
    }
    return self;
}

// TODO: Matching should be more sophisticated than this
-(BOOL)isVariableSymbol:(NSString*)string {
    for (IDEIndexSymbol* symbol in self.variableSymbols) {
        if ([symbol.name isEqualToString:string]) {
            return YES;
        }
    }
    return NO;
}

-(NSArray*)openWorkspaces {
    return [[[IDEDocumentController sharedDocumentController] workspaceDocuments] valueForKey:@"workspace"];
}

-(void)updateSymbolCacheForWorkspace:(IDEWorkspace*)workspace {
    NSArray* handledSymbolKinds = @[ [DVTSourceCodeSymbolKind localVariableSymbolKind],
                                     [DVTSourceCodeSymbolKind globalVariableSymbolKind]
                                    ];
    
    for (DVTSourceCodeSymbolKind* kind in handledSymbolKinds) {
        NSArray* matchingSymbols = [workspace.index allSymbolsMatchingKind:kind workspaceOnly:YES];
        for (IDEIndexSymbol* symbol in matchingSymbols) {
            [self.variableSymbols addObject:symbol];
            
            //NSLog(@"BBUCodingInColor: symbol %@", symbol.name);
        }
    }
}

@end
