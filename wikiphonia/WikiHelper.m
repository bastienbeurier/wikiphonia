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
        NSString *section = [WikiHelper removeParentheses:[extract substringWithRange:sectionRange]];
        [sections addObject:section];
    }
    
    //Add last section.
    NSRange lastHeaderRange = [[matches objectAtIndex:[headers count] - 1] range];
    NSInteger lastSectionStart = lastHeaderRange.location + lastHeaderRange.length;
    NSInteger lastSectionEnd = [extract length];
    
    if ([matches count] > [headers count]) {
        lastSectionEnd = [[matches objectAtIndex:[headers count]] range].location;
    }

    NSString *lastSection = [WikiHelper removeParentheses:[extract substringWithRange:NSMakeRange(lastSectionStart, lastSectionEnd - lastSectionStart)]];
    [sections addObject:lastSection];
    
    //Add intro.
    [headers insertObject:@"Introduction" atIndex:0];
    NSRange introSectionRange = NSMakeRange(0, [[matches firstObject] range].location);
    NSString *firstSection = [WikiHelper removeParentheses:[extract substringWithRange:introSectionRange]];
    [sections insertObject:firstSection atIndex:0];
    
    return @[headers, sections];
}

+ (NSString *)removeParentheses:(NSString *)str {
    NSMutableString *mutableStr = [str mutableCopy];
    
    //Remove parenthesis.
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\s+\\([^()]*\\)" options:0 error:nil];
    [regex replaceMatchesInString:mutableStr options:0 range:NSMakeRange(0, [mutableStr length]) withTemplate:@""];
    
    return mutableStr;
}



@end
