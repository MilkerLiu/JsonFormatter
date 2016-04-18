//
//  JsonFormatter.h
//  JsonFormatter
//
//  Created by milker on 16/4/17.
//  Copyright © 2016年 milker. All rights reserved.
//

#import <AppKit/AppKit.h>

@class JsonFormatter;

static JsonFormatter *sharedPlugin;

@interface JsonFormatter : NSObject

+ (instancetype)sharedPlugin;
- (id)initWithBundle:(NSBundle *)plugin;

@property (nonatomic, strong, readonly) NSBundle* bundle;
@end