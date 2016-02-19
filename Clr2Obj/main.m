//
//  main.m
//  Clr2Obj
//
//  Created by Ramon Poca on 21/08/14.
//  Copyright (c) 2014 Ramon Poca. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "NSString+CamelCaser.h"

int main(int argc, const char *argv[]) {

    @autoreleasepool {
        NSString *file;
        NSColorList *list;

        if (argc < 2) {
            NSLog(@"Usage: Clr2Obj filename.clr|Palette [ClassName]");
            exit(-1);
        }

        if (argc > 1) {
            file = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
            NSString *baseName = [file lastPathComponent];

            if ([[[file pathExtension] uppercaseString] isEqualToString:@"CLR"]) {
                NSFileManager *fm = [NSFileManager defaultManager];
                if ([fm fileExistsAtPath:file]) {
                    list = [[NSColorList alloc] initWithName:baseName fromFile:file];
                } else {
                    NSLog(@"CLR File not found at: %@", file);
                    exit(-1);
                }
            } else {
                // System palette
                list = [NSColorList colorListNamed:file];
            }
            if (!list) {
                NSLog(@"CLR File/Palette cannot be loaded: %@", file);
                exit(-1);
            }
        }
        NSString *baseName = [file lastPathComponent];
        baseName = [baseName stringByDeletingPathExtension];

        if (argc > 2) {
            baseName = [NSString stringWithCString:argv[2] encoding:NSUTF8StringEncoding];
        }

        NSString *categoryFileName = [NSString stringWithFormat:@"%@Color", [baseName fullyCasedString]];
        NSString *categoryImplementationFileName = [categoryFileName stringByAppendingPathExtension:@"swift"];
        NSError *error;

        NSString *template = [NSString stringWithContentsOfFile:@"UIColorExtension.template" encoding:NSUTF8StringEncoding error:&error];

        if (error) {
            NSLog(@"Cannot load UIColorCategory.template, will use default. Error: %@", error);
            template = @"import UIKit\n\nextension UIColor {\n%COLORLIST%}\n";
        }

        NSString *definTemplate = @"\n    class func %COLORNAME%() -> UIColor {\n        return UIColor(red:%f, green:%f, blue:%f, alpha:%f)\n    }\n";

        NSString *allDefinitions = @"";
        for (NSString *colorName in list.allKeys) {
            NSColor *color = [list colorWithKey:colorName];
            NSString *definition = [definTemplate stringByReplacingOccurrencesOfString:@"%COLORNAME%" withString:colorName];
            definition = [NSString stringWithFormat:definition, color.redComponent, color.greenComponent, color.blueComponent, color.alphaComponent];

            allDefinitions = [allDefinitions stringByAppendingString:definition];
        }

        NSString *definitionFileContents = [template stringByReplacingOccurrencesOfString:@"%COLORLIST%" withString:allDefinitions];
        if (![definitionFileContents writeToFile:categoryImplementationFileName atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
            NSLog(@"Failed to write declaration file: %@", error);
        }
    }
    return 0;
}

