//
//  ViewController.m
//  HostLookupTest
//
//  Created by 能登 要 on 12/12/30.
//  Copyright (c) 2012年 irimasu. All rights reserved.
//

#import "ViewController.h"
#import "HostLookupHelper.h"
#import "AppDelegate.h"

//------------------------------------------------------------------------------------------
// soket connect
//------------------------------------------------------------------------------------------
#include <fcntl.h>
#include <arpa/inet.h> // using inet_addr
#include <netdb.h> // using gethostbyname() HOST_NOT_FOUND
#include <unistd.h> // using read() warite() close()
//------------------------------------------------------------------------------------------

@interface ViewController ()
{
    IBOutlet UITextField *_textFieldURL;
    IBOutlet UISwitch *_switchIPV6Only;
    IBOutlet UITextView *_textViewResult;
}
@end

@implementation ViewController

- (IBAction)firedRequest:(id)sender
{
    
    if( [_textFieldURL.text length] > 0 ){
        HostLookupHelper* hostLookupHelper = [[HostLookupHelper alloc] init];
    
        [hostLookupHelper lookupWithHost:_textFieldURL.text block:^(HostLookupHelper *helper, NSString *resolvedhost, NSString *resolvedpath, NSUInteger port, NSData *address4, NSData *address6) {
            if( _switchIPV6Only.on == YES && address6 == nil ){
                _textViewResult.text = @"IPv6に対応していないサーバです。";
            }else{
                // ソケット生成
                // ソケットのためのファイルディスクリプタ
                int soketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0);
                if ( soketFileDescriptor >= 0 ){
                    int result = _switchIPV6Only.on ? connect(soketFileDescriptor,[address6 bytes], [address6 length] ) : connect(soketFileDescriptor,[address4 bytes], [address4 length] );
                    if (result != -1 ) {
                        // ヘッダの作成
                        NSString *requestHeader = [NSString stringWithFormat:
                                                   @"GET %@ HTTP/1.0\r\n"
                                                   @"Host: %@\r\n"
//                                                   @"User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7; rv:17.0) Gecko/20100101 Firefox/17.0\r\n"
//                                                   @"Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n"
                                                   @"Accept-Language: ja,en-us;q=0.7,en;q=0.3\r\n"
                                                   @"\r\n"
                                                   ,resolvedpath
                                                   ,resolvedhost];
                        result = write(soketFileDescriptor, [requestHeader UTF8String] , strlen([requestHeader UTF8String]) );
                        if ( result > 0 ){
                            NSMutableString* header = [[NSMutableString alloc] init];
                            NSMutableData* dataResult = nil;
                            char header_terminateCode[4] = {'\r','\n','\r','\n'};
                            char* flag= header_terminateCode;
                            //	printf("サーバからのレスポンス\n");
                            while (1){
                                char buf[1024];
                                int read_size;
                                read_size = read(soketFileDescriptor, buf, sizeof(buf)-1);
                                buf[read_size] = '\0';
                                
                                if ( read_size > 0 && read_size < sizeof(buf) ){
                                    if( dataResult == nil ){
                                        for( char*p = buf; p != buf+read_size; p++ ){
                                            if( *flag == *p ){
                                                flag++;
                                                if( flag == header_terminateCode + 4 ){
                                                    dataResult = [[NSMutableData alloc]init];
                                                    if( (p + 1) < buf + read_size ){
                                                        size_t bodyReadSize = read_size - ((p + 1) - buf);
                                                        [dataResult appendBytes:(p+1) length:bodyReadSize];
                                                    }
                                                    *(p + 1) = '\0';
                                                    break;
                                                }
                                            }else{
                                                flag = header_terminateCode;
                                            }
                                        }
                                        [header appendString:[NSString stringWithUTF8String:buf]];
                                    }else{
                                        [dataResult appendBytes:buf length:read_size];
                                    }
                                }else if ( read_size == 0 ){
                                    char* terminator = '\0';
                                    [dataResult appendBytes:&terminator length:sizeof(terminator)];
                                        // ターミネーターを追加
                                    NSString* resultText = [NSString stringWithUTF8String:[dataResult bytes]];
                                    _textViewResult.text = resultText;

                                    break;
                                }else {
                                    result = 0;
                                    _textViewResult.text = @"読み込み中に不明なエラーが発生しました。";
                                    break;
                                }
                            }                            
                        }else{
                            _textViewResult.text = @"リクエストの送信に失敗しました。";
                        }
                    }else{
                        _textViewResult.text = @"connect に失敗しました。";
                    }
                    close(soketFileDescriptor);
                }else{
                    _textViewResult.text = @"ソケットの作成に失敗しました。";
                }
            }
        }
        failureBlock:^(HostLookupHelper *helper, HostLookupHelperFailureType failureType) {
            switch (failureType) {
            case HostLookupHelperFailureTypeEmptyHostName:
                _textViewResult.text = @"ホスト名が空白です";
                break;
            case HostLookupHelperFailureTypeToolongHostName:
                _textViewResult.text = @"ホスト名が長過ぎます";
                break;
            case HostLookupHelperFailureTypeNotFoundProtocolScheme:
                _textViewResult.text = @"プロトコルスキームが見つかりません(http or https)";
                break;
            case HostLookupHelperFailureTypeNotConvertIPAdress:
                break;
            default:
                _textViewResult.text = @"IPアドレスがコンバートできませんでした。";
                break;
            }
        }];
        
        [hostLookupHelper release];
    }else{
        _textViewResult.text = @"URLを指定してください。";
    }
    
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_textFieldURL release];
    [_switchIPV6Only release];
    [_textViewResult release];
    [super dealloc];
}
@end
