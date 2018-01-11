//
//  ViewController.m
//  TestForUrlEncode
//
//  Created by dvt04 on 2017/11/23.
//  Copyright © 2017年 dvt04. All rights reserved.
//

#import "ViewController.h"
#import "M3U8SegmentModel.h"

@interface ViewController ()

@end

@implementation ViewController
{
    NSMutableArray *_arrSegements;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // 测试urlencode和decode
    [self testForUrlEncodeAndDecode];
    // 测试获取m3u8时长
    _arrSegements = [NSMutableArray arrayWithCapacity:0];
    NSString *urlString = @"http://192.166.62.66:5660/vod/GCABLE_201711202254101506443141_6000.m3u8";
    urlString = @"http://192.166.62.66:5660/live/1.5Mhigh.m3u8";
    [self parseM3U8Url:urlString];
    
    NSLog(@"parse finished , arrSegements is %@", _arrSegements);
    CGFloat duration = 0;
    for (M3U8SegmentModel *model in _arrSegements) {
        CGFloat tsDuration = [model.duration floatValue];
        duration += tsDuration;
    }
    
    NSLog(@"%lf", duration);
    
}

#pragma mark - Test For Url Encode And Decode
- (void)testForUrlEncodeAndDecode
{
    NSString *strTmp = @"+";
    NSString *str1Tmp = @" ";
    
    NSString *encodeStr = [strTmp stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"#%<>[\\]^`{|}\"]+ "].invertedSet];
    NSLog(@"encode: %@", encodeStr);
    encodeStr = [encodeStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"#%<>[\\]^`{|}\"]+ "].invertedSet];
    NSLog(@"encode: %@", encodeStr);
    encodeStr = [encodeStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"#%<>[\\]^`{|}\"]+ "].invertedSet];
    NSLog(@"encode: %@", encodeStr);
    
    NSString *encodeStr1 = [str1Tmp stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"#%<>[\\]^`{|}\"]+ "].invertedSet];
    NSLog(@"encode: %@", encodeStr1);
    encodeStr1 = [encodeStr1 stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"#%<>[\\]^`{|}\"]+ "].invertedSet];
    NSLog(@"encode: %@", encodeStr1);
    encodeStr1 = [encodeStr1 stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"#%<>[\\]^`{|}\"]+ "].invertedSet];
    NSLog(@"encode: %@", encodeStr1);
    
    
#if 0
    NSString *decodedURL = [self decodedURLStringWithStr:encodeStr];
    NSLog(@"decode: %@", decodedURL);
    decodedURL = [self decodedURLStringWithStr:decodedURL];
    NSLog(@"decode: %@", decodedURL);
    decodedURL = [self decodedURLStringWithStr:decodedURL];
    NSLog(@"decode: %@", decodedURL);
#else
    NSString *decodedURL = [strTmp stringByRemovingPercentEncoding];
    NSLog(@"decode: %@", decodedURL);
    decodedURL = [decodedURL stringByRemovingPercentEncoding];
    NSLog(@"decode: %@", decodedURL);
    decodedURL = [decodedURL stringByRemovingPercentEncoding];
    NSLog(@"decode: %@", decodedURL);
    
    NSString *decodedURL1 = [str1Tmp stringByRemovingPercentEncoding];
    NSLog(@"decode: %@", decodedURL1);
    decodedURL1 = [decodedURL1 stringByRemovingPercentEncoding];
    NSLog(@"decode: %@", decodedURL1);
    decodedURL1 = [decodedURL1 stringByRemovingPercentEncoding];
    NSLog(@"decode: %@", decodedURL1);
    
#endif
}

- (NSString *)decodedURLStringWithStr:(NSString *)str
{
    NSString *result = (NSString *)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault, (CFStringRef)str, CFSTR("")));
    return result;
}

#pragma mark - Test For Get M3U8 Duration
- (void)parseM3U8Url:(NSString *)urlStr
{
    //判断是否是HTTP连接
    if (!([urlStr hasPrefix:@"http://"] || [urlStr hasPrefix:@"https://"])) {
        NSLog(@"error url");
        return;
    }
    
    //解析出M3U8
    NSError *error = nil;
    NSStringEncoding encoding;
    NSString *m3u8Str = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:urlStr] usedEncoding:&encoding error:&error];//这一步是耗时操作，要在子线程中进行
    /*注意1、请看代码下方注意1*/
    if (m3u8Str == nil) {
        NSLog(@"m3u8Str is nil");
        return;
    }
    
    //解析TS文件
    NSRange segmentRange = [m3u8Str rangeOfString:@"#EXTINF:"];
    if (segmentRange.location == NSNotFound) {
        //M3U8里没有TS文件
        NSLog(@"segementRange failed");
        return;
    }
    
    //逐个解析TS文件，并存储
    while (segmentRange.location != NSNotFound) {
        //声明一个model存储TS文件链接和时长的model
        M3U8SegmentModel *model = [[M3U8SegmentModel alloc] init];
        //读取TS片段时长
        NSRange commaRange = [m3u8Str rangeOfString:@","];
        NSString* value = [m3u8Str substringWithRange:NSMakeRange(segmentRange.location + [@"#EXTINF:" length], commaRange.location -(segmentRange.location + [@"#EXTINF:" length]))];
        model.duration = value;
        //截取M3U8
        m3u8Str = [m3u8Str substringFromIndex:commaRange.location];
        //获取TS下载链接,这需要根据具体的M3U8获取链接，可以根据自己公司的需求
        NSRange linkRangeBegin = [m3u8Str rangeOfString:@","];
        NSRange linkRangeEnd = [m3u8Str rangeOfString:@".ts"];
        NSString* linkUrl = [m3u8Str substringWithRange:NSMakeRange(linkRangeBegin.location + 2, (linkRangeEnd.location + 3) - (linkRangeBegin.location + 2))];
        model.locationUrl = linkUrl;
        [_arrSegements addObject:model];
        m3u8Str = [m3u8Str substringFromIndex:(linkRangeEnd.location + 3)];
        segmentRange = [m3u8Str rangeOfString:@"#EXTINF:"];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
