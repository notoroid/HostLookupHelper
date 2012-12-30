//
//  HostLookupHelper.h
//  PrintOrder2
//
//  Created by 能登 要 on 12/12/30.
//  Copyright (c) 2012年 いります電算企画. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HostLookupHelper;

typedef enum tagHostLookupHelperFailureType
{
     HostLookupHelperFailureTypeEmptyHostName         // ホスト名が空白です
    ,HostLookupHelperFailureTypeToolongHostName         // ホスト名が長過ぎる
    ,HostLookupHelperFailureTypeNotFoundProtocolScheme  //　プロトコルスキームが見つからない(http or https)
    ,HostLookupHelperFailureTypeNotConvertIPAdress      // IPアドレスがコンバートできない
}HostLookupHelperFailureType;

typedef void(^HostLookupHelperLookupBlock)(HostLookupHelper* helper,NSString* resolvedhost,NSString* resolvedpath,NSUInteger port,NSData* address4,NSData* address6);
typedef void(^HostLookupHelperFailureBlock)(HostLookupHelper* helper,HostLookupHelperFailureType failureType);

@interface HostLookupHelper : NSObject
- (void) lookupWithHost:(NSString*)host block:(HostLookupHelperLookupBlock)block failureBlock:(HostLookupHelperFailureBlock)failureBlock;
@end
