//
//  WikiHelper.m
//  wikiphonia
//
//  Created by Bastien Beurier on 4/24/15.
//  Copyright (c) 2015 bastien. All rights reserved.
//

#import "WikiHelper.h"

@implementation WikiHelper

+ (NSArray *)processArticleExtract:(NSString *)extract
{
    NSRange searchedRange = NSMakeRange(0, [extract length]);
    NSString *pattern = @"\n=+ .+ =+\n";
    NSError *error;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    NSArray* matches = [regex matchesInString:extract options:0 range: searchedRange];
    
    NSMutableArray *headers = [NSMutableArray new];

    //Find article section headers with ranges.
    for (NSTextCheckingResult *match in matches) {
        //Remove "=" character from headers.
        NSString *header = [[extract substringWithRange:[match range]] stringByReplacingOccurrencesOfString:@"=" withString:@""];
        
        [headers addObject:header];
    }
    
    NSMutableArray *sections = [NSMutableArray new];
    
    //Find article sections with ranges.
    for (NSInteger i = 0; i < [headers count] - 1; i++) {
        NSInteger sectionStart = [[matches objectAtIndex:i] range].location + [[matches objectAtIndex:i] range].length;
        NSInteger sectionEnd = [[matches objectAtIndex:i+1] range].location;
        NSRange sectionRange = NSMakeRange(sectionStart, sectionEnd - sectionStart);
        [sections addObject:[extract substringWithRange:sectionRange]];
    }
    
    //Add last section
    NSRange lastHeaderRange = [[matches objectAtIndex:[headers count] - 1] range];
    NSInteger lastSectionStart = lastHeaderRange.location + lastHeaderRange.length;
    NSInteger lastSectionEnd = [extract length];
    
    if ([matches count] > [headers count]) {
        lastSectionEnd = [[matches objectAtIndex:[headers count]] range].location;
    }

    [sections addObject:[extract substringWithRange:NSMakeRange(lastSectionStart, lastSectionEnd - lastSectionStart)]];
    
    //Add intro
    [headers insertObject:@"Introduction" atIndex:0];
    NSRange introSectionRange = NSMakeRange(0, [[matches firstObject] range].location);
    [sections insertObject:[extract substringWithRange:introSectionRange] atIndex:0];
    
    return @[headers, sections];
}



@end
