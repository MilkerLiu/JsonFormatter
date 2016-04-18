//
//  NSObject_Extension.m
//  JsonFormatter
//
//  Created by milker on 16/4/17.
//  Copyright © 2016年 milker. All rights reserved.
//


#import "NSObject_Extension.h"
#import "JsonFormatter.h"

@implementation NSObject (Xcode_Plugin_Template_Extension)

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[JsonFormatter alloc] initWithBundle:plugin];
        });
    }
}
@end
