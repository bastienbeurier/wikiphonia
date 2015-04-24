//
//  WikiHelper.h
//  wikiphonia
//
//  Created by Bastien Beurier on 4/24/15.
//  Copyright (c) 2015 bastien. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPSessionManager.h"


@interface WikiApi : AFHTTPSessionManager

+ (WikiApi *)sharedClient;

+ (void)getArticleContentWithTitle:(NSString *)title success:(void(^)(NSString *, NSString *))success failure:(void(^)(void))failure;

@end
