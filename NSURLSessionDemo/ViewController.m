//
//  ViewController.m
//  NSURLSessionDemo
//
//  Created by 刘嵩野 on 2018/5/9.
//  Copyright © 2018年 kirito_song. All rights reserved.
//


#ifdef DEBUG
#define NSLog(FORMAT, ...) fprintf(stderr,"%s\n",[[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define NSLog(...)
#endif

#import "ViewController.h"

@interface ViewController ()<NSURLSessionDelegate,NSURLSessionTaskDelegate>

@property (weak, nonatomic) IBOutlet UITextView *resTextView;
@property (weak, nonatomic) IBOutlet UIImageView *resImgView;//展示图片
@property (nonatomic) NSMutableData * data;
@property (weak, nonatomic) IBOutlet UIProgressView *progressview;

@property (nonatomic) BOOL isjsonTest;
@property (nonatomic)NSUInteger expectlength;

@property (strong,nonatomic)NSURLSession * session;
@property (strong,nonatomic)NSURLSessionTask * task;
@property (nonatomic) NSData *resumeData;
@end

@implementation ViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

}

//暂停
- (IBAction)pause {
    if (self.task.state == NSURLSessionTaskStateRunning) {
        [self.task suspend];
    }
}



- (IBAction)cancel {
    switch (self.task.state) {
        case NSURLSessionTaskStateRunning:
        case NSURLSessionTaskStateSuspended:
            
            if ([self.task isKindOfClass:[NSURLSessionDownloadTask class]]) {
                [(NSURLSessionDownloadTask *)(self.task) cancelByProducingResumeData:^(NSData *resumeData) {
                    self.resumeData = resumeData;
                }];
            }else {
                [self.task cancel];
            }
            
            
            break;
        default:
            break;
    }
}



- (IBAction)resume {
    if (self.task.state == NSURLSessionTaskStateSuspended) {
        [self.task resume];
    }
}


- (void)reload {
    self.task = nil;
    self.resImgView.image = nil;
    self.resTextView.text = nil;
    self.progressview.hidden = NO;
    self.progressview.progress = 0;
    self.data = nil;
}

//普通的网络请求
- (IBAction)dataTask:(id)sender {
    self.isjsonTest = YES;
    [self reload];
    [self jsonTest];
}

//请求图片
- (IBAction)imgTest:(id)sender {
    self.isjsonTest = NO;
    [self reload];
    [self imgTest];
}

- (IBAction)imgUpDataTest:(id)sender {
    self.isjsonTest = YES;
    [self reload];
    [self upDataTest];
}
- (IBAction)downLoad:(id)sender {
    self.isjsonTest = NO;
    [self reload];
    [self downLoadTest];
    
}

- (void)jsonTest {
    NSURLSessionConfiguration * configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession * session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    NSString * url = [NSString stringWithFormat:@"http://api.androidhive.info/volley/person_object.json"];
    NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSURLSessionDataTask * task = [session dataTaskWithRequest:request];
    self.task = task;
}

- (void)imgTest {
    NSURLSessionConfiguration * configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession * session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    //这是个gif图、懒得弄了。方便暂停用的
    NSString * url = [NSString stringWithFormat:@"https://upfile.asqql.com/2009pasdfasdfic2009s305985-ts/2018-4/2018423202071807.gif"];
    NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSURLSessionDataTask * task = [session dataTaskWithRequest:request];
    self.task = task;
}

- (void)upDataTest {
    NSURLSessionConfiguration * configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession * session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    //这是个gif图、懒得弄了。方便暂停用的
    NSString * url = [NSString stringWithFormat:@"http://www.chuantu.biz/upload.php"];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"POST";
    NSString *path = [[NSBundle mainBundle]pathForResource:@"tu" ofType:@"gif"];
    NSURLSessionUploadTask * task = [session uploadTaskWithRequest:request fromFile:[NSURL URLWithString:path]];
    self.task = task;
}


- (void)downLoadTest {
    NSURLSessionConfiguration * configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession * session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    //这是个gif图、懒得弄了。方便暂停用的
    NSString * url = [NSString stringWithFormat:@"https://upfile.asqql.com/2009pasdfasdfic2009s305985-ts/2018-4/2018423202071807.gif"];
    NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];

    NSURLSessionDownloadTask * task;
    if (self.resumeData) {
        //需要服务器支持断点续传
        task = [session downloadTaskWithResumeData:self.resumeData];
    }else {
        task = [session downloadTaskWithRequest:request];
    }
    
    self.task = task;
}




#pragma mark - NSURLSessionDelegate
#pragma mark 会话总代理
#pragma mark 通知>>session被关闭
//[session invalidateAndCancel]或者[session finishTasksAndInvalidate]
//session被关闭时调用、持有的delegate将被清空
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error {
    NSLog(@"NSURLSessionDelegate:::通知>>session被关闭");
}

#pragma mark 询问>>服务器客户端配合验证--会话级别
/*
 参考：
 https://www.jianshu.com/p/2642e31919e7
 https://www.2cto.com/kf/201604/504149.html
 https://blog.csdn.net/jingcheng345413/article/details/65437649
 NSURLAuthenticationChallenge 类中最重要的一个属性是protectionSpace。
 该属性是一个 NSURLProtectionSpace 的实例，一个NSURLProtectionSpace对象通过属性host、isProxy、port、protocol、proxyType和realm代表了请求验证的服务器端的范围。
 而NSURLProtectionSpace类的authenticationMethod属性则指明了服务端的验证方式，可能的值包括:
 
    challenge.protectionSpace {
        // 默认
        NSURLAuthenticationMethodDefault
        // 基本的 HTTP 验证，通过 NSURLCredential 对象提供用户名和密码。
        NSURLAuthenticationMethodHTTPBasic
        // 类似于基本的 HTTP 验证，摘要会自动生成，同样通过 NSURLCredential 对象提供用户名和密码。
        NSURLAuthenticationMethodHTTPDigest
        // 不会用于 URL Loading System，在通过 web 表单验证时可能用到。
        NSURLAuthenticationMethodHTMLForm
 
        <<<<<***************>>>>>
        //Negotiate（协商，Kerberos or NTLM）
        NSURLAuthenticationMethodNegotiate
        //NTLM（WindowsNT使用的认证方式
        NSURLAuthenticationMethodNTLM
        // 验证客户端的证书
        NSURLAuthenticationMethodClientCertificate
        // 指明客户端要验证服务端提供的证书
        NSURLAuthenticationMethodServerTrust
    }
 
 其中后四个为会话级别验证
 将会优先调用会话级别验证、如果未实现再调用任务界别验证。
 */
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler {
    NSLog(@"NSURLSessionDelegate:::询问>>服务器客户端配合验证--会话级别");
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling,nil);
}

#pragma mark 通知>>所有后台下载任务全部完成
//必须在backgroundSessionConfiguration 并且在后台完成时才会调用
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    NSLog(@"NSURLSessionDelegate:::通知>>所有后台下载任务全部完成");
}


#pragma mark - NSURLSessionTaskDelegate
#pragma mark 任务总代理

#pragma mark 通知>>延时任务被调用
/*
    当设置了earliestBeginDate属性
    (需要注意这个属性对于非后台任务并不有效、而且不能保证定时执行、只能保证不会在指定日期之前执行)
    的NSURLSessionTask被延迟调用的、会走这里
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willBeginDelayedRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLSessionDelayedRequestDisposition disposition, NSURLRequest * _Nullable newRequest))completionHandler {
    NSLog(@"NSURLSessionTaskDelegate:::通知>>延时任务被调用");
    /*
        typedef NS_ENUM(NSInteger, NSURLSessionDelayedRequestDisposition) {
        NSURLSessionDelayedRequestContinueLoading = 0,  //使用原始请求、参数忽略
        NSURLSessionDelayedRequestUseNewRequest = 1,    //使用新请求
        NSURLSessionDelayedRequestCancel = 2,   //取消任务、参数忽略
        }
     */
    completionHandler(NSURLSessionDelayedRequestContinueLoading,request);
}


#pragma mark 通知>>网络受限导致任务进入等待
/*
    如果NSURLSessionConfiguration的waitsForConnectivity属性为true
    并且由于网络不通(并不是并发受限)没有被立即发出时
    此方法最多只能在每个任务中调用一次、并且仅在连接最初不可用时调用。
    它永远不会被调用后台会话，因为这些会话会忽略waitsForConnectivity。
 
 */
- (void)URLSession:(NSURLSession *)session taskIsWaitingForConnectivity:(NSURLSessionTask *)task {
    NSLog(@"NSURLSessionTaskDelegate:::通知>>网络受限导致任务进入等待");
}

#pragma mark 准备开始请求、询问是否重定向
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    NSLog(@"NSURLSessionTaskDelegate:::询问>>是否重定向");
    completionHandler(request);
}

#pragma mark 询问>>服务器需要客户端配合验证--任务级别
//会话级别除非未实现对应代理、否则不会调用任务级别验证方法
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler {
    NSLog(@"NSURLSessionTaskDelegate:::询问>>服务器需要客户端配合验证--任务级别");
    NSURLCredential * cre =[NSURLCredential credentialWithUser:@"kirito_song" password:@"psw" persistence:NSURLCredentialPersistenceNone];
    completionHandler(NSURLSessionAuthChallengeUseCredential,cre);
}

#pragma mark 询问>>流任务的方式上传--需要客户端提供数据源
/* 当任务需要新的请求主体流发送到远程服务器时，告诉委托。
 这种委托方法在两种情况下被调用：
 1、如果使用uploadTaskWithStreamedRequest创建任务，则提供初始请求正文流：
 2、如果任务因身份验证质询或其他可恢复的服务器错误需要重新发送包含正文流的请求，则提供替换请求正文流。
 注：如果代码使用文件URL或NSData对象提供请求主体，则不需要实现此功能。
 */

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
 needNewBodyStream:(void (^)(NSInputStream * _Nullable bodyStream))completionHandler {
    NSLog(@"NSURLSessionTaskDelegate:::询问>>数据流的方式上传--需要客户端提供数据源");
}

#pragma mark 通知>>上传进度
/* 定期通知代理向服务器发送主体内容的进度。*/
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    NSLog(@"NSURLSessionTaskDelegate:::通知>>上传进度");
    self.progressview.progress = (float)totalBytesSent/(float)totalBytesExpectedToSend;
}



#pragma mark 通知>>任务信息收集完成
/*
 对发送请求/DNS查询/TLS握手/请求响应等各种环节时间上的统计. 更易于我们检测, 分析我们App的请求缓慢到底是发生在哪个环节, 并对此进行优化提升我们APP的性能.
 
 NSURLSessionTaskMetrics对象与NSURLSessionTask对象一一对应. 每个NSURLSessionTaskMetrics对象内有3个属性 :
 
 taskInterval : task从开始到结束总共用的时间
 redirectCount : task重定向的次数
 transactionMetrics : 一个task从发出请求到收到数据过程中派生出的每个子请求, 它是一个装着许多NSURLSessionTaskTransactionMetrics对象的数组. 每个对象都代表下图的一个子过程
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics {
    NSLog(@"NSURLSessionTaskDelegate:::通知>>任务信息收集完成");
    NSLog(@"::::::::::::相关讯息::::::::::::\n总时间:%@\n,重定向次数:%zd\n,派生的子请求:%zd",metrics.taskInterval,metrics.redirectCount,metrics.transactionMetrics.count);
}

#pragma mark 通知>>任务完成
//无论成功、失败或者取消
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    NSLog(@"NSURLSessionTaskDelegate:::通知>>任务完成");
    
    self.progressview.hidden = YES;
    if (!error) {
        if (self.isjsonTest) {
            NSString * str =  [[NSString alloc]initWithData:self.data encoding:NSUTF8StringEncoding];
            self.resTextView.text = str;
        }else {
            UIImage * image = [UIImage imageWithData:self.data];
            self.resImgView.image = image;
        }
        
    }else {
        self.resTextView.text = error.localizedDescription;
    }
    
}

#pragma mark - NSURLSessionDataDelegate
#pragma mark 数据任务代理
#pragma mark 通知>>服务器返回响应头
#pragma mark 询问>>下一步操作
//服务器返回响应头、询问下一步操作(取消操作、普通传输、下载、数据流传输)
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSLog(@"NSURLSessionDataDelegate:::通知>>服务器返回响应头。询问>>下一步操作");
    self.expectlength = [response expectedContentLength];
    completionHandler(NSURLSessionResponseAllow);
//    completionHandler(NSURLSessionResponseBecomeDownload);
//    completionHandler(NSURLSessionResponseBecomeStream);
}

#pragma mark 通知>>数据任务已更改为下载任务
//你可以通过上面的 completionHandler(NSURLSessionResponseBecomeDownload);进行测试
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    NSLog(@"NSURLSessionDataDelegate:::通知>>数据任务已更改为下载任务");
}

#pragma mark 通知>>数据任务已更改为流任务
//你可以通过上面的 completionHandler(NSURLSessionResponseBecomeStream);进行测试
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didBecomeStreamTask:(NSURLSessionStreamTask *)streamTask {
    NSLog(@"NSURLSessionDataDelegate:::通知>>数据任务已更改为下载任务");
}

#pragma mark 通知>>服务器成功返回数据
//已经收到了一些(大数据可能多次调用)数据
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    NSLog(@"NSURLSessionDataDelegate:::通知>>服务器成功返回数据");
    [self.data appendData:data];
    self.progressview.progress = [self.data length]/((float) self.expectlength);
}

#pragma mark 询问>>是否把Response存储到Cache中
//任务是否应将响应存储在缓存中
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse * _Nullable cachedResponse))completionHandler {
    NSLog(@"NSURLSessionDataDelegate:::询问>>是否把Response存储到Cache中");
    NSCachedURLResponse * res = [[NSCachedURLResponse alloc]initWithResponse:proposedResponse.response data:proposedResponse.data userInfo:nil storagePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(res);
}


#pragma mark - NSURLSessionDownloadDelegate
#pragma mark 下载任务代理
#pragma mark 通知>>下载任务已经完成
//location 临时文件的位置url 需要手动移动文件至需要保存的目录
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    NSLog(@"NSURLSessionDownloadDelegate:::通知>>下载任务已经完成");
    
    NSData * data = [NSData dataWithContentsOfURL:location.filePathURL];
    [self.data appendData:data];
    self.resumeData = nil;
}

#pragma mark 通知>>下载任务进度
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    NSLog(@"NSURLSessionTaskDelegate:::通知>>下载任务进度");
    if (totalBytesExpectedToWrite != NSURLSessionTransferSizeUnknown) {
        self.progressview.progress = (float)totalBytesWritten/(float)totalBytesExpectedToWrite;
    }
    
}

#pragma mark 通知>>下载任务已经恢复下载
//filrOffest 已经下载的文件大小  expectedTotalBytes预期总大小
/*
    你可以通过 [session downloadTaskWithResumeData：resumeData]之类的方法来重新恢复一个下载任务
    resumeData在下载任务失败的时候会通过error.userInfo[NSURLSessionDownloadTaskResumeData]来返回以供保存
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes {
    NSLog(@"NSURLSessionTaskDelegate:::通知>>下载任务已经恢复下载");
}


#pragma mark - NSURLSessionStreamDelegate
#pragma mark 流任务代理
#pragma mark 通知>>数据流的连接中读数据的一边已经关闭
- (void)URLSession:(NSURLSession *)session readClosedForStreamTask:(NSURLSessionStreamTask *)streamTask {
    NSLog(@"NSURLSessionStreamDelegate:::通知>>数据流的连接中读数据的一边已经关闭");
}

#pragma mark 通知>>数据流的连接中写数据的一边已经关闭
- (void)URLSession:(NSURLSession *)session writeClosedForStreamTask:(NSURLSessionStreamTask *)streamTask {
    NSLog(@"NSURLSessionStreamDelegate:::通知>>数据流的连接中写数据的一边已经关闭");
}

#pragma mark 通知>>系统已经发现了一个更好的连接主机的路径
- (void)URLSession:(NSURLSession *)session betterRouteDiscoveredForStreamTask:(NSURLSessionStreamTask *)streamTask {
    NSLog(@"NSURLSessionStreamDelegate:::通知>>系统已经发现了一个更好的连接主机的路径");
}

#pragma mark 通知>>流任务已完成
- (void)URLSession:(NSURLSession *)session streamTask:(NSURLSessionStreamTask *)streamTask
didBecomeInputStream:(NSInputStream *)inputStream
      outputStream:(NSOutputStream *)outputStream {
    NSLog(@"NSURLSessionStreamDelegate:::通知>>流任务已完成");
}


- (NSMutableData *)data {
    if (!_data) {
        _data = [NSMutableData new];
    }
    return _data;
}

-(NSURLSession*)session{
    if (!_session) {
        NSURLSessionConfiguration * configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:configuration
                                                 delegate:self
                                            delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}
@end
