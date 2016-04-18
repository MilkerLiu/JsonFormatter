//
//  CCPEnvironmentUtils.m
//
//  Copyright (c) 2015 Delisa Mason. http://delisa.me
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.

#import "CCPPathResolver.h"

@implementation CCPPathResolver

+ (NSString*)stringByAdjustingGemPathForEnvironment:(NSString*)path
{
    NSString* newPath = path;

    newPath = [self stringByExpandingGemHomeInPath:newPath];

    newPath = [self stringByExpandingGemPathInPath:newPath];

    newPath = [self stringByAdjustingRvmBinPath:newPath];

    return newPath;
}

+ (NSString*)resolveHomePath
{
    NSString* userId = [[[NSProcessInfo processInfo] environment] objectForKey:@"USER"];
    NSString* userHomePath = [[NSString stringWithFormat:@"~%@", userId] stringByExpandingTildeInPath];

    return userHomePath;
}

+ (NSString*)resolveWorkspacePath
{
    NSArray* workspaceWindowControllers = [NSClassFromString(@"IDEWorkspaceWindowController")
        valueForKey:@"workspaceWindowControllers"];

    id workspace;

    for (id controller in workspaceWindowControllers) {
        if ([[controller valueForKey:@"window"] isEqual:[NSApp keyWindow]]) {
            workspace = [controller valueForKey:@"_workspace"];
        }
    }

    NSString* workspacePath = [[workspace valueForKey:@"representingFilePath"]
        valueForKey:@"_pathString"];

    return workspacePath;
}

+ (NSString*)resolveCommand:(NSString*)command forPath:(NSString*)path
{
    NSArray* pathArray = [path componentsSeparatedByString:@":"];
    NSString* resolvedCommand = nil;
    NSFileManager* fileManager = [NSFileManager defaultManager];

    for (NSString* pathComponent in pathArray) {
        NSString* pathComponentWithCommand = [pathComponent stringByAppendingPathComponent:command];
        if ([fileManager isExecutableFileAtPath:pathComponentWithCommand]) {
            resolvedCommand = pathComponentWithCommand;
            break;
        }
    }

    return resolvedCommand;
}

+ (NSString*)resolveGemHome
{
    NSString* gemHome = @"";
    NSData* data;
    NSTask* task = [[NSTask alloc] init];
    NSPipe* pipe = [NSPipe pipe];

    NSString* workspacePath = [self resolveWorkspacePath];
    if (!workspacePath) {
        workspacePath = [self resolveHomePath];
    }

    NSString* bashCommandString = [NSString stringWithFormat:@"cd %@; gem env gemdir;",
                                            workspacePath];

    [task setLaunchPath:@"/bin/bash"];
    [task setArguments:@[ @"-l", @"-c", bashCommandString ]];
    [task setStandardOutput:pipe];
    [task launch];

    data = [[pipe fileHandleForReading] readDataToEndOfFile];
    gemHome = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];

    // strip newlines
    gemHome = [gemHome stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    return gemHome;
}

+ (NSString*)resolveGemPath
{
    NSString* gemPath = @"";
    NSData* data;
    NSTask* task = [[NSTask alloc] init];
    NSPipe* pipe = [NSPipe pipe];

    NSString* workspacePath = [self resolveWorkspacePath];
    if (!workspacePath) {
        workspacePath = [self resolveHomePath];
    }

    NSString* bashCommandString = [NSString stringWithFormat:@"cd %@; gem env gempath;", workspacePath];

    [task setLaunchPath:@"/bin/bash"];
    [task setArguments:@[ @"-l", @"-c", bashCommandString ]];
    [task setStandardOutput:pipe];
    [task launch];

    data = [[pipe fileHandleForReading] readDataToEndOfFile];
    gemPath = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];

    // strip newlines
    gemPath = [gemPath stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    return gemPath;
}

/**
 *  adjust path rvm, replacing /bin with /wrappers
 *
 *  @param path path containing possible replacements
 *
 *  @return updated path
 */
+ (NSString*)stringByAdjustingRvmBinPath:(NSString*)path
{
    NSString* newPath = path;
    NSArray* pathArray = [path componentsSeparatedByString:@":"];
    NSMutableArray* pathArrayAdjusted = [[NSMutableArray alloc] init];

    // path could consist of more than one component separated by ':' char!
    if ([pathArray count] > 0) {
        for (NSString* pathComponent in pathArray) {
            NSRange rangeRvm = [pathComponent rangeOfString:@".rvm"];
            NSRange rangeBin = [pathComponent rangeOfString:@"/bin" options:NSBackwardsSearch];
            NSString* pathComponentAdjusted = pathComponent;

            if (rangeRvm.location != NSNotFound && rangeBin.location != NSNotFound) {
                pathComponentAdjusted = [pathComponent stringByReplacingOccurrencesOfString:[pathComponent substringWithRange:rangeBin]
                                                                                 withString:@"/wrappers"
                                                                                    options:0
                                                                                      range:rangeBin];
            }

            [pathArrayAdjusted addObject:pathComponentAdjusted];
        }

        newPath = [pathArrayAdjusted componentsJoinedByString:@":"];
    }

    return newPath;
}

/**
 *  resolve instances of $GEM_HOME, ${GEM_HOME}
 *
 *  @param path path containing possible replacements
 *
 *  @return path with GEM_HOME references replaced
 */
+ (NSString*)stringByExpandingGemHomeInPath:(NSString*)path
{
    NSString* newPath = path;
    NSRange rangeGemHome;

    if (((rangeGemHome = [path rangeOfString:@"$GEM_HOME"]).location != NSNotFound) || ((rangeGemHome = [path rangeOfString:@"${GEM_HOME}"]).location != NSNotFound)) {

        newPath = [path stringByReplacingOccurrencesOfString:[path substringWithRange:rangeGemHome]
                                                  withString:[self resolveGemHome]
                                                     options:0
                                                       range:rangeGemHome];

        // cleanup
        newPath = [newPath stringByStandardizingPath];
    }

    return newPath;
}

/**
 *  // resolve instances of $GEM_PATH, ${GEM_PATH}
 *
 *  @param path path containing possible replacements
 *
 *  @return path with GEM_PATH references replaced
 */
+ (NSString*)stringByExpandingGemPathInPath:(NSString*)path
{
    NSString* newPath = path;
    NSRange rangeGemPath;

    if (((rangeGemPath = [path rangeOfString:@"$GEM_PATH"]).location != NSNotFound) || ((rangeGemPath = [path rangeOfString:@"${GEM_PATH}"]).location != NSNotFound)) {

        NSString* pathFirstPart = [path substringToIndex:rangeGemPath.location];
        NSString* pathLastPart = [path substringFromIndex:rangeGemPath.location + rangeGemPath.length];
        NSString* gemPath = [self resolveGemPath];
        NSArray* gemPathArray = [gemPath componentsSeparatedByString:@":"];
        NSMutableArray* gemPathArrayAdjusted = [[NSMutableArray alloc] init];

        // prepend pathFirstPart, append pathLastPart to each component in gemPath
        for (NSString* pathComponent in gemPathArray) {
            NSString* pathComponentAdjusted = [NSString stringWithFormat:@"%@%@%@", pathFirstPart, pathComponent, pathLastPart];
            [gemPathArrayAdjusted addObject:pathComponentAdjusted];
        }

        newPath = [gemPathArrayAdjusted componentsJoinedByString:@":"];

        // cleanup
        newPath = [newPath stringByStandardizingPath];
    }

    return newPath;
}

@end
