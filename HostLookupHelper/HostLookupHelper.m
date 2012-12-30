//
//  HostLookupHelper.m
//  PrintOrder2
//
//  Created by 能登 要 on 12/12/30.
//  Copyright (c) 2012年 いります電算企画. All rights reserved.
//

#import "HostLookupHelper.h"

//------------------------------------------------------------------------------------------
// soket connect
//------------------------------------------------------------------------------------------
#include <fcntl.h>
#include <arpa/inet.h> // using inet_addr
#include <netdb.h> // using gethostbyname() HOST_NOT_FOUND
#include <unistd.h> // using read() warite() close()
//------------------------------------------------------------------------------------------

typedef struct tagHostLookupHostPortInfomation
{
    const char* protocolName;
    int defaultPort;
}HostLookupHostPortInfomation;

@implementation HostLookupHelper

- (void) lookupWithHost:(NSString*)host block:(HostLookupHelperLookupBlock)block failureBlock:(HostLookupHelperFailureBlock)failureBlock
{
    HostLookupHelperLookupBlock copiedBlock = Block_copy(block);
    HostLookupHelperFailureBlock copiedfailureBlock = Block_copy(failureBlock);
    
    if( [host length] > 0 ){
#define HOST_LOOKUP_HELPER_BUF_LEN 2048
        char resolvedhost[HOST_LOOKUP_HELPER_BUF_LEN] = "localhost";    /* 接続するホスト名 */
        char resolvedpath[HOST_LOOKUP_HELPER_BUF_LEN] = "/";            /* 要求するパス */
        unsigned short port = 0;             /* 接続するポート番号 */
        
        
        const char* request= [host UTF8String] /*"https://saltworks.jp/~grambook.saltworks.jp/api/iphone/order_photo.php"*/;
        char host_path[HOST_LOOKUP_HELPER_BUF_LEN];

        if ( strlen(request) > HOST_LOOKUP_HELPER_BUF_LEN-1 ){
            copiedfailureBlock( self , HostLookupHelperFailureTypeToolongHostName );
        }else{
            const HostLookupHostPortInfomation hostLookupHostPortInfomations[] = {
                 {"https",443}
                ,{"http",80}
            };
            
            const HostLookupHostPortInfomation* pEnd = hostLookupHostPortInfomations + sizeof(hostLookupHostPortInfomations) / sizeof(hostLookupHostPortInfomations[0]);
            const HostLookupHostPortInfomation* hostLookupHostPortInfomation = NULL;
            for( hostLookupHostPortInfomation = hostLookupHostPortInfomations; hostLookupHostPortInfomation != pEnd;hostLookupHostPortInfomation++ ){
                NSString* protocolWithScheme = [NSString stringWithFormat:@"%s://",hostLookupHostPortInfomation->protocolName];
                NSString* protocolWithSchemeScanf = [NSString stringWithFormat:@"%s://%%s",hostLookupHostPortInfomation->protocolName];
                
                // hostLookupHostPortInfomation->protocolName から始まる文字列で
                // sscanf が成功しかつ、
                // hostLookupHostPortInfomation->protocolName の後に何か文字列が存在するなら
                
                if ( strstr(request, [protocolWithScheme UTF8String] ) && sscanf(request,[protocolWithSchemeScanf UTF8String], host_path) && strcmp(request, [protocolWithScheme UTF8String] ) ){
                    char *p;
                    p = strchr(host_path, '/');// ホストとパスの区切り "/" を調べる(ex http:/// or https:///)
                    if ( p != NULL ){
                        strcpy(resolvedpath, p); // "/"以降の文字列を path にコピー
                        *p = '\0';
                        strcpy(resolvedhost, host_path); // '/'より前の文字列を host にコピー */
                    } else {
                         // '/'がないなら＝http://host という引数なら */
                        strcpy(resolvedhost, host_path); /* 文字列全体を host にコピー */
                    }
                    
                    p = strchr(resolvedhost, ':');       /* ホスト名の部分に ":" が含まれていたら */
                    if ( p != NULL ){
                        port = atoi(p+1);        /* ポート番号を取得 */
                        if ( port <= 0 ){        /* 数字でない (atoi が失敗) か、0 だったら */
                            port = hostLookupHostPortInfomation->defaultPort;           /* ポート番号は 80 に決め打ち */
                        }
                        *p = '\0';
                    }
                    break;
                }
            }
            
            if( hostLookupHostPortInfomation == pEnd ){
//                NSLog(@"URL は https://host/path の形式で指定してください。");
                copiedfailureBlock( self , HostLookupHelperFailureTypeNotFoundProtocolScheme );
            }else{
#if 0
                // ホストの情報(IPアドレスなど)を取得
                struct hostent * servhost = gethostbyname(resolvedhost);

                if ( servhost == NULL ){
//                    NSLog(@"[%s] から IP アドレスへの変換に失敗しました。\n", resolvedhost);
                    copiedfailureBlock( self , HostLookupHelperFailureTypeNotConvertIPAdress );
                }else{
                    struct sockaddr_in nativeAddr;           /* ソケットを扱うための構造体 */
                    // 構造体をゼロクリア
                    memset(&nativeAddr,0,sizeof(nativeAddr));

                    nativeAddr.sin_family = AF_INET;

                    // IPアドレスを示す構造体をコピー
                    bcopy(servhost->h_addr, &nativeAddr.sin_addr, servhost->h_length);

                    if( port != 0 ){                          // 引数でポート番号が指定されていたら
                        nativeAddr.sin_port = htons(port);
                    }else{                                   // そうでないなら getservbyname でポート番号を取得
                        // サービス (http など) を扱うための構造体
                        struct servent *service = getservbyname(hostLookupHostPortInfomation->protocolName , "tcp");
                        if ( service != NULL )                // 成功したらポート番号をコピー
                            nativeAddr.sin_port = service->s_port;
                        else                               // 失敗したら hostLookupHostPortInfomation->defaultPort に決め打ち
                            nativeAddr.sin_port = htons(hostLookupHostPortInfomation->defaultPort);

                    }
                
                    NSData* address4 = [NSData dataWithBytes:&nativeAddr length:sizeof(nativeAddr)];
                    
                    copiedBlock( self , [NSString stringWithUTF8String:resolvedhost ] , [NSString stringWithUTF8String:resolvedpath] , port , address4 , nil );
                    freehostent(servhost);
                        // ホスト情報の解放
                }
            }
#else
            NSString *portString = [NSString stringWithFormat:@"%hu", port];
            
            // ヒント情報を作成
            struct addrinfo addressInfoHints;
            memset(&addressInfoHints, 0, sizeof(addressInfoHints));
            addressInfoHints.ai_family   = PF_UNSPEC;
            addressInfoHints.ai_socktype = SOCK_STREAM;
            addressInfoHints.ai_protocol = IPPROTO_TCP;
            
            struct addrinfo* rootAddressInfo = NULL;
            struct addrinfo* chaindAddressInfo = NULL;
            
            int getAdressError = getaddrinfo(resolvedhost, [portString UTF8String], &addressInfoHints, &rootAddressInfo);
            
            if (getAdressError){
                copiedfailureBlock( self , HostLookupHelperFailureTypeNotConvertIPAdress );
            }else{
                NSData* IPV4 = nil;
                NSData* IPV6 = nil;
                
                for(chaindAddressInfo = rootAddressInfo; chaindAddressInfo; chaindAddressInfo = chaindAddressInfo->ai_next)
                {
                    void* buffer = malloc(chaindAddressInfo->ai_addrlen);
                    memcpy(buffer,chaindAddressInfo->ai_addr, chaindAddressInfo->ai_addrlen);
                    struct sockaddr_in* sockaddrein = (struct sockaddr_in*)buffer;
                    sockaddrein->sin_len = chaindAddressInfo->ai_addrlen;
                    if( port != 0 ){                          // 引数でポート番号が指定されていたら
                        sockaddrein->sin_port = htons(port);
                    }else{                                   // そうでないなら getservbyname でポート番号を取得
                        // サービス (http など) を扱うための構造体
                        struct servent *service = getservbyname(hostLookupHostPortInfomation->protocolName , "tcp");
                        if ( service != NULL )                // 成功したらポート番号をコピー
                            sockaddrein->sin_port = service->s_port;
                        else                               // 失敗したら hostLookupHostPortInfomation->defaultPort に決め打ち
                            sockaddrein->sin_port = htons(hostLookupHostPortInfomation->defaultPort);
                        
                    }
                    
                    if ((IPV4 == nil) && (chaindAddressInfo->ai_family == AF_INET)){
                        IPV4 = [NSData dataWithBytes:buffer length:chaindAddressInfo->ai_addrlen];
                    }else if ((IPV6 == nil) && (chaindAddressInfo->ai_family == AF_INET6)){
                        IPV6 = [NSData dataWithBytes:buffer length:chaindAddressInfo->ai_addrlen];
                    }
                    
                    free(buffer);
                }
                freeaddrinfo(rootAddressInfo);
                
                if( IPV4 != nil || IPV6 != nil )
                    copiedBlock( self , [NSString stringWithUTF8String:resolvedhost ] , [NSString stringWithUTF8String:resolvedpath] , port , IPV4 , IPV6 );
                else
                    copiedfailureBlock( self , HostLookupHelperFailureTypeNotConvertIPAdress );
                
            }
            
        }
#endif
        }
    }else{
//        NSLog(@"URLが長過ぎます");
        copiedfailureBlock( self , HostLookupHelperFailureTypeEmptyHostName );
    }

    Block_release(copiedBlock);
    Block_release(copiedfailureBlock);
}

@end
