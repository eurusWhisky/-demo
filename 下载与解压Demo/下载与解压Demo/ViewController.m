//
//  ViewController.m
//  下载与解压Demo
//
//  Created by 陈伟杰 on 2020/4/24.
//  Copyright © 2020 陈伟杰. All rights reserved.
//

#import "ViewController.h"
#import <CommonCrypto/CommonDigest.h>
@interface ViewController ()<NSURLSessionDownloadDelegate>
@property (nonatomic,strong)NSURLSession *dataSession;
@property (nonatomic,strong)NSURLSessionDownloadTask *dataTask;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSURLSessionConfiguration *sessionCfg = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionCfg.requestCachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    
    self.dataSession = [NSURLSession sessionWithConfiguration:sessionCfg delegate:self delegateQueue:[self sessionQueue]];
    self.dataTask = [self.dataSession downloadTaskWithURL:[NSURL URLWithString:@"http://fileserver1.clife.net:8080/group1/M01/73/BE/Cvtlp16CtfaARwThAADEDeYKw-Q581.zix"]];
    [self.dataTask resume];
}

- (NSOperationQueue *)sessionQueue
{
    static NSOperationQueue *_sessionQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sessionQueue = [[NSOperationQueue alloc]init];
        _sessionQueue.name = @"com.heth5.session";
        _sessionQueue.maxConcurrentOperationCount = 1;
        _sessionQueue.qualityOfService = NSQualityOfServiceDefault;
    });
    return _sessionQueue;
}

#pragma mark ----delegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location{
    NSString *cachePath=NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSString *tempPath = [cachePath stringByAppendingPathComponent:location.lastPathComponent];
    //需要将下载后的文件替换到其他位置,否则跳过这个方法后系统会自己删除该文件,这里tempPath对应的文件为下载文件
    [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:tempPath] error:nil];
    //解压可以使用第三方库SSZipArchive
    
    //解压
    
    [session finishTasksAndInvalidate];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
    
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error{
    if (error) {
    
    }
}


#pragma mark --- unzip
#define HETH5FileHashDefaultChunkSizeForReadingData 1024*8
-(NSString*)HETH5getFileMD5WithPath:(NSString*)path{
    return (__bridge_transfer NSString *)HETH5FileMD5HashCreateWithPath((__bridge CFStringRef)path, HETH5FileHashDefaultChunkSizeForReadingData);
}

CFStringRef HETH5FileMD5HashCreateWithPath(CFStringRef filePath,size_t chunkSizeForReadingData) {
    
    // Declare needed variables
    
    CFStringRef result = NULL;
    
    CFReadStreamRef readStream = NULL;
    
    // Get the file URL
    
    CFURLRef fileURL =
    
    CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                  
                                  (CFStringRef)filePath,
                                  
                                  kCFURLPOSIXPathStyle,
                                  
                                  (Boolean)false);
    
    if (!fileURL) goto done;
    
    // Create and open the read stream
    
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,
                                            
                                            (CFURLRef)fileURL);
    
    if (!readStream) goto done;
    
    bool didSucceed = (bool)CFReadStreamOpen(readStream);
    
    if (!didSucceed) goto done;
    
    // Initialize the hash object
    
    CC_MD5_CTX hashObject;
    
    CC_MD5_Init(&hashObject);
    
    // Make sure chunkSizeForReadingData is valid
    
    if (!chunkSizeForReadingData) {
        
        chunkSizeForReadingData = HETH5FileHashDefaultChunkSizeForReadingData;
        
    }
    
    // Feed the data to the hash object
    
    bool hasMoreData = true;
    
    while (hasMoreData)
    {
        uint8_t buffer[chunkSizeForReadingData];
        
        CFIndex readBytesCount = CFReadStreamRead(readStream,(UInt8 *)buffer,(CFIndex)sizeof(buffer));
        
        if (readBytesCount == -1) break;
        
        if (readBytesCount == 0) {
            
            hasMoreData = false;
            
            continue;
        }
        
        CC_MD5_Update(&hashObject,(const void *)buffer,(CC_LONG)readBytesCount);
        
    }
    
    // Check if the read operation succeeded
    
    didSucceed = !hasMoreData;
    
    // Compute the hash digest
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5_Final(digest, &hashObject);
    
    // Abort if the read operation failed
    
    if (!didSucceed) goto done;
    
    // Compute the string result
    
    char hash[2 * sizeof(digest) + 1];
    
    for (size_t i = 0; i < sizeof(digest); ++i) {
        
        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }
    result = CFStringCreateWithCString(kCFAllocatorDefault,(const char *)hash,kCFStringEncodingUTF8);
    
done:
    
    if (readStream)
    {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL)
    {
        CFRelease(fileURL);
    }
    return result;
}


@end
