//
//  JsonFormatter.m
//  JsonFormatter
//
//  Created by milker on 16/4/17.
//  Copyright © 2016年 milker. All rights reserved.
//

#import "JsonFormatter.h"
#import "SharedXcode.h"

@interface JsonFormatter()

@property (nonatomic, strong, readwrite) NSBundle *bundle;
@end

@implementation JsonFormatter

+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        // reference to plugin's bundle, for resource access
        self.bundle = plugin;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didApplicationFinishLaunchingNotification:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
    }
    return self;
}

- (void)didApplicationFinishLaunchingNotification:(NSNotification*)noti
{
    //removeObserver
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
    
    // Create menu items, initialize UI, etc.
    // Sample Menu Item:
    NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];
    if (menuItem) {
        [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
        NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Json Format"
                                                                action:@selector(doJsonFormatAction)
                                                         keyEquivalent:@""];
        
//        NSMenu *podMenu = [[NSMenu alloc] init];
//        {
//            // pod update
//            NSMenuItem *menu = [[NSMenuItem alloc] initWithTitle:@"formatter"
//                                                          action:@selector(doJsonFormatAction)
//                                                   keyEquivalent:@"x"];
//            [menu setKeyEquivalentModifierMask:NSControlKeyMask|NSCommandKeyMask];
//            [menu setTarget:self];
//            [podMenu addItem:menu];
//        }
//        
//        [actionMenuItem setSubmenu:podMenu];
//        
        [actionMenuItem setTarget:self];
        [[menuItem submenu] addItem:actionMenuItem];
    }
}

// Sample Action, for menu item:
- (void)doJsonFormatAction
{
    NSTextView * textView = [SharedXcode textView];
    NSString *text = textView.textStorage.string;
    
    NSDictionary *jsonData = [JsonFormatter dictionaryWithJsonString:text];
    
    if(jsonData) {
        NSString *formatString = [JsonFormatter dictionaryToJson:jsonData];
        [SharedXcode replaceCharactersInRange:NSMakeRange(0, text.length) withString:formatString];
    }

}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - help functions
+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString
{
    if (jsonString == nil) {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err) {
        NSLog(@"json-format error：%@",err);
        return nil;
    }
    return dic;
}

+ (NSString*)dictionaryToJson:(NSDictionary *)dic
{
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    NSString *formatString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return [formatString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
}

@end
