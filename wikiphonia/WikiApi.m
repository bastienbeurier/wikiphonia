//
//  WikiHelper.m
//  wikiphonia
//
//  Created by Bastien Beurier on 4/24/15.
//  Copyright (c) 2015 bastien. All rights reserved.
//

#import "WikiApi.h"

@implementation WikiApi

+ (WikiApi *)sharedClient
{
    static WikiApi *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _sharedClient = [[WikiApi alloc] initWithBaseURL:[NSURL URLWithString:@"https://en.wikipedia.org/"]];
        
        // Add m4a content type for audio
        _sharedClient.responseSerializer.acceptableContentTypes = [_sharedClient.responseSerializer.acceptableContentTypes setByAddingObject:@"audio/m4a"];
        
        // Stop request if we lose connection
        NSOperationQueue *operationQueue = _sharedClient.operationQueue;
        [_sharedClient.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            if(status == AFNetworkReachabilityStatusNotReachable) {
                [operationQueue cancelAllOperations];
            }
        }];
    });
    
    return _sharedClient;
}

+ (void)getArticleContentWithTitle:(NSString *)title success:(void(^)(NSString *, NSString *))success failure:(void(^)(void))failure
{
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    [parameters setObject:title forKey:@"titles"];
    [parameters setObject:@"json" forKey:@"format"];
    [parameters setObject:@"query" forKey:@"action"];
    [parameters setObject:@"extracts" forKey:@"prop"];
    [parameters setObject:@"" forKey:@"explaintext"];
    [parameters setObject:@"" forKey:@"redirects"];
    
    [[WikiApi sharedClient] GET:@"w/api.php" parameters:parameters success:^(NSURLSessionDataTask *task, id JSON) {
        NSDictionary *pages = [[JSON valueForKeyPath:@"query"] valueForKey:@"pages"];
        
        NSLog(@"JSON: %@", JSON);
        
        for (NSString *key in pages) {
            if (![key isEqualToString:@"-1"]) {
                NSMutableDictionary *page = [pages valueForKey:key];
                success([page valueForKey:@"title"], [page valueForKey:@"extract"]);
                return;
            }
        }
        
        success(title, nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failure) {
            failure();
        }
    }];
}

@end
