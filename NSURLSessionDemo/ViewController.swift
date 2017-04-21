//
//  ViewController.swift
//  NSURLSessionDemo
//
//  Created by 婉卿容若 on 2017/4/20.
//  Copyright © 2017年 婉卿容若. All rights reserved.
//

import UIKit
import SystemConfiguration

class ViewController: UIViewController {
    
    var delegate: URLSessionDelegate?
    
    var  downloadSession: URLSession?
    var downlaodTask: URLSessionDownloadTask?
    
    let reachability = SCNetworkReachabilityCreateWithName(nil, "www.baidu.com")

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // session configuration
        
//        let defaultSessionConfiguration = URLSessionConfiguration.default
//        let ephemeralSessionConfiguration = URLSessionConfiguration.ephemeral
//        let backgroundSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "identifier")
//        
//        let testSession = URLSession(configuration: defaultSessionConfiguration, delegate: delegate, delegateQueue: OperationQueue.current)
//        
//        dataCacheUseRequest()
//        dataCacheUseConfiguration()
      
        
        let config = URLSessionConfiguration.background(withIdentifier: "mydownlaod")
        self.downloadSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
       
        
        }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

/// ## URLSession 概览

/**
 * ## URLSession 的类型 --  通过 URLSessionConfiguration 指定 具体使用哪个 session 类型
 * Default Sessions(默认会话): 使用了持久的磁盘存储, 并且将证书存入用户的钥匙串中
 * Ephemeral Session(临时会话): 没有向磁盘中存入任何数据, 与该会话相关的证书、缓存都会存在 RAM 中。 因此当你的 APP 临时会话无效时，证书以及缓存等数据就会被清除掉
 * Background sessions(后台会话)：除了使用一个单线程来处理会话之外，与默认会话类似。不过要使用后台会话要有一些限制条件，比如会话必须提供事件交付的代理方法、只有HTTP和HTTPS协议支持后台会话、总是伴随着重定向。仅仅在上传文件时才支持后台会话，当你上传二进制对象或者数据流时是不支持后台会话的。当App进入后台时，后台传输就会被初始化。（需要注意的是iOS8和OS X 10.10之前的版本中后台会话是不支持数据任务（data task）的）
 */


/**
 * ## URLSession 的各种任务
 * Data Task(数据任务）：负责使用 Data 对象来发送和接收数据。Data Task 是为了那些简短的并且经常从服务器请求的数据而准备的。该任务可以每请求一次就对返回的数据进行一次处理
 * Download Task（下载任务）：以表单的形式接收一个文件的数据，该任务支持后台下载。
 * Upload Task(上传任务)：以表单的形式上传一个文件的数据，该任务同样支持后台上传
 */

/// ## URL 编码

/// CRUD: creat read update delete => post get update delete => 基于　REST　协议
/// URL 是 URI 的一种 - uniform resource location/identifier
// http://example.com:8042/over/there?key1=value&key2[]=value2&key3[subkey]=value3  => scheme + authority + path + query

/// ## 数据任务 -- URLSessionDataTask
extension ViewController {
    
    func sessionDataTaskRequest(method: String, paramenters: [String: AnyObject]) {
        
        // 1. 创建 url
        let hostString = "https://httpbin.org/ip"
        var request = URLRequest(url: URL(string: hostString)!)
        request.httpMethod = "GET"
        // request.httpBody
        
        let session = URLSession.shared
        let sessiontask = session.dataTask(with: request) { (data, response, error) in
            guard error == nil else{
                return
            }
            
            guard let data = data else{
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                print(json )
            }   
            catch {
                print("json 解析错误")
            }
           
        }
        
        sessiontask.resume()
    }
}

// upload

extension ViewController {
    
    func uploadTask(parameters: Data) {
        
        let uploadURLString = "https://httpbin.org/ip"
        let url: URL = URL.init(string: uploadURLString)!
        
        var request = URLRequest.init(url: url)
        request.httpMethod = "POST"
        
       
        
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        
        let uploadTask = session.uploadTask(with: request, from: parameters) { (data, response, error) in
            guard error == nil else{
                return
            }
            
            print("上传成功")
        }
        
        uploadTask.resume()
    }
    
    
}

// URLSessionTaskDelegate

extension ViewController: URLSessionTaskDelegate {
    
    // 上传进度
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        print("本次上传: \(bytesSent)")
        print("已经上传: \(totalBytesSent)")
        print("文件总量: \(totalBytesExpectedToSend)")
    }
}

// download

extension ViewController {
    
    func downlaodtask() {
        
        let resumeData: Data? = UserDefaults.standard.object(forKey: "hhhh") as? Data
        if resumeData != nil {
            
            self.downlaodTask = self.downloadSession?.downloadTask(withResumeData: resumeData!)
        }else{
            
            let fileUrl = URL(string: "https://httpbin.org/ip")
            let request = URLRequest(url: fileUrl!)
            self.downlaodTask = self.downloadSession?.downloadTask(with: request)
        }
        
        downlaodTask?.resume()
    }
    
    func pausetask() {
        
        downlaodTask?.cancel(byProducingResumeData: { (resumeData) in
            if let resumeData = resumeData {
                
                // 看内容
                if let str = String.init(data: resumeData, encoding: String.Encoding.utf8) {
                    print(str)
                }
                
                UserDefaults.standard.set(resumeData, forKey: "hhhh")
                
                print(resumeData.count)
            }
        })
    }
   
}

// URLSessionDownloadDelegate

extension ViewController: URLSessionDownloadDelegate {
    
    // 下载完成
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // 临时文件会被删除,,所以需要将数据存到确定目录中
        UserDefaults.standard.removeObject(forKey: "hhhh")
        
        print("临时目录地址: \(location.path)") // 临时文件目录
            
        // 创建文件目录
        
        let newFileName = String(UInt(Date().timeIntervalSince1970))
        var newFileExtensionName = "txt"
        
        if session.configuration.identifier == "mydownlaod" {
            
            newFileExtensionName = "png"
        }
        
        let newFilePath = NSHomeDirectory() + "/Documents/\(newFileName).\(newFileExtensionName)"
        
        // 文件管理
        let fileManager = FileManager.default
        do {
            try fileManager.moveItem(atPath: location.path, toPath: newFilePath)
        }
        catch {
            print("存储文件失败")
        }
    }
    
    // 监听下载进度
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print("本次接收: \(bytesWritten)")
        print("已经接收: \(totalBytesWritten)")
        print("文件总量: \(totalBytesExpectedToWrite)")
    }
    
    // 暂停后再下载
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        print("已经下载: \(fileOffset)")
        print("文件总量: \(expectedTotalBytes)")
        
        // 更新进度条或者其他操作
    }
}


/**
 * ## 网络缓存 --- 利用 URLSession 相关内容进行缓存
 * #### 缓存策略
 * 1. URLRequest.CachePolicy.useProtocolCachePolicy // 缓存存在就读缓存,若不存在就请求服务器
 * 2. URLRequest.CachePolicy.reloadIgnoringLocalCacheData // 忽略本地缓存,直接请求服务器数据
 * 3. URLRequest.CachePolicy.returnCacheDataElseLoad // 本地有缓存,忽略其有效性,无则请求服务器
 * 4. URLRequest.CachePolicy.returnCacheDataDontLoad // 直接加载本地缓存, 没有也不请求网络
 * 5. URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData // 未实现
 * 6. URLRequest.CachePolicy.reloadRevalidatingCacheData // 未实现
 
 * #### 使用方法
 * 1. request.cachePolicy = .useProtocolCachePolicy => URLRequest
 * 2. config.requestCachePolicy = .useProtocolCachePolicy => URLSessionConfiguration
 
 * #### 使用 URLCache + reqeust 进行缓存
 * #### 使用 URLCache + URLSessionConfiguration 进行缓存
 
 */

// 使用 URLCache + reqeust 进行缓存

extension ViewController {
    
    func dataCacheUseRequest() {
        
        let fileURL = URL(string: "https://httpbin.org/ip")
        var request = URLRequest(url: fileURL!)
        
        let memoryCapacity = 4 * 1024 * 1024 // 内存容量 4g
        let diskCapaciry = 10 * 1024 * 1024 // 磁盘容量 10g
        let cacheFilePath = "RoniCache" // 缓存路径
        
        let urlCache = URLCache.shared
        urlCache.memoryCapacity = memoryCapacity
        urlCache.diskCapacity = diskCapaciry
        
        print("URLCache's disk capacity is \(URLCache.shared.diskCapacity) bytes")
        print("URLCache's disk usage capacity is \(URLCache.shared.currentDiskUsage) bytes")
        print("URLCache's memory capacity is \(URLCache.shared.memoryCapacity) bytes")
        print("URLCache's memory usage capacity is \(URLCache.shared.currentMemoryUsage) bytes")
        print("\(URLCache.shared)")
        
        request.cachePolicy = .returnCacheDataElseLoad
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request) { (data, response, error) in
            guard let data =  data else{
                return
            }
            
            print("缓存数据长度: \(data.count)")
        }
        
        dataTask.resume()
    }

}


// 使用 URLCache + URLSessionConfiguration 进行缓存

extension ViewController {

    func dataCacheUseConfiguration() {
        
        let fileURL = URL(string: "https://httpbin.org/ip")
        var request = URLRequest(url: fileURL!)
        
        let memoryCapacity = 3 * 1024 * 1024 // 内存容量 4g
        let diskCapaciry = 20 * 1024 * 1024 // 磁盘容量 10g
        let cacheFilePath = "RoniCache" // 缓存路径
        
        let urlCache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapaciry, diskPath: cacheFilePath)
        
        request.cachePolicy = .returnCacheDataElseLoad
        let config = URLSessionConfiguration.default
        config.urlCache = urlCache
        
        let session = URLSession(configuration: config)
        let dataTask = session.dataTask(with: request) { (data, response, error) in
            guard let data =  data else{
                return
            }
            
            print("缓存数据长度: \(data.count)")
        }
        
        dataTask.resume()
    }

}

// 清理缓存

extension ViewController {
    
    func clearCacheFile() {
        
        // 获取路径
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        
        // 获取 bundleID
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return
        }
        
        // 拼接缓存文件路径
        let projectCachePath = "\(cachePath)/\(bundleIdentifier)"
        
        // 创建文件管理
        let fileManager = FileManager.default
        
        // 获取缓存文件列表
        guard let cacheFileList = try? fileManager.contentsOfDirectory(atPath: projectCachePath) else {
            return
        }
        
        // 遍历文件列表, 移除所有文件
        for fileName in cacheFileList {
            let willRemoveFilePath = projectCachePath + fileName
            
            if fileManager.fileExists(atPath: willRemoveFilePath) {
                try! fileManager.removeItem(atPath: willRemoveFilePath)
            }
        }
        
    }
}


/**
 * ## 请求认证 - 为了网络请求的安全性，服务器与客户端之间要进行身份的验证...单向或者双向
 * #### 认证方式 - HTTPS
 * 1. NSURLAuthenticationMethodHTTPBasic // HTTP基本认证, 需要提供用户名和密码
 * 2. NSURLAuthenticationMethodHTTPDigest // HTTP 数字认证, 与基本认证相似需要用户名和密码
 * 3. NSURLAuthenticationMethodHTMLForm // HTTP 表单认证, 需要提供用户名和密码
 * 4. NSURLAuthenticationMethodNTLM // NTLM 认证(NT LAN Manager) 是一系列指向用户提供认证,完整性和机密性的微软安全协议
 * 5. NSURLAuthenticationMethodNegotiate // 协商认证
 * 6. NSURLAuthenticationMethodClientCertificate // 客户端认证, 需要客户端提供认证所需的证书
 * 7. NSURLAuthenticationMethodServerTrust // 服务端认证, 有认证请求的保护空间提供信任
 **后两个是我们在请求 HTTPS 时会遇到的认证,需要服务器或者客户端来提供认证的，这个证书就是我们平时常说的CA证书**
 
 * #### 认证处理策略
 * 1. URLSession.AuthChallengeDisposition.useCredential // 使用证书
 * 2. URLSession.AuthChallengeDisposition.performDefaultHandling // 执行默认处理,类似于该代理没有实现一样, credential 参数会被忽略
 * 3. URLSession.AuthChallengeDisposition.rejectProtectionSpace // 拒绝保护空间, 重试下一次认证, credential 参数会被忽略
 * 4. URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge // 取消请求,credential 参数会被忽略

 * #### HTTPS请求证书处理
 
 */

// HTTPS请求证书处理

extension ViewController {
    
    func authentication() {
        
        let fileURL = URL(string: "https://httpbin.org/ip")
        var request = URLRequest(url: fileURL!)
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
        
        let sessionTask = session.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                return
            }
            
            print(data)
        }
        
        sessionTask.resume()
    }
}

extension ViewController: URLSessionDelegate {
    
    
    
    /// 请求数据时, 如果服务器需要验证, 则会调用这个代理方法
    ///
    /// - Parameters:
    ///   - session:  session
    ///   - challenge: 授权质疑
    ///   - completionHandler: 回调
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        let authenticationMethod = challenge.protectionSpace.authenticationMethod  // 从保护空间中取出认证方式
        
        if authenticationMethod == NSURLAuthenticationMethodServerTrust {
            
            let disposition = URLSession.AuthChallengeDisposition.useCredential // 处理策略
            let credential = URLCredential.init(trust: challenge.protectionSpace.serverTrust!) // 创建证书
            completionHandler(disposition, credential) // 证书认证
        }
        
        if authenticationMethod == NSURLAuthenticationMethodHTTPBasic {
            
            let disposition = URLSession.AuthChallengeDisposition.useCredential // 处理策略
            let credential = URLCredential.init(user: "username", password: "pwd", persistence: URLCredential.Persistence.forSession)
            completionHandler(disposition, credential) // 证书认证
            
            return
            
        }
        
        // 取消请求
        let disposition = URLSession.AuthChallengeDisposition.cancelAuthenticationChallenge
        completionHandler(disposition, nil)
    }
}

/**
 * ## NSURLSession相关代理
 * #### SessionDelegate
 * <#item2#>
 * <#item3#>
 */


/**
 * ## 监测网络连接状态
 * #### 使用SystemConfiguration实现reachability
 * <#item2#>
 * <#item3#>
 */

// 监测网络连接状态

extension ViewController {
    
    func observeNetwork() {
        
        // 1. 创建 reachability 上下文
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        
        // 2. 设置回调
        let closureCallbackEnable = SCNetworkReachabilitySetCallback(reachability!, { (reachabi, flags, info) in
            guard flags.contains(SCNetworkReachabilityFlags.reachable) else {
                
                print("网络不可用")
                return
            }
            
            if !flags.contains(SCNetworkReachabilityFlags.connectionRequired) {
                print("以太网或者 WIFI")
            }
            
            if flags.contains(SCNetworkReachabilityFlags.connectionOnDemand) || flags.contains(SCNetworkReachabilityFlags.connectionOnTraffic) {
                
                if !flags.contains(SCNetworkReachabilityFlags.interventionRequired) {
                    
                    print("以太网或者 WiFI")
                }
            }
            
            #if os(iOS)
                if flags.contains(SCNetworkReachabilityFlags.isWWAN) {
                    
                    print("蜂窝数据")
                }
            #endif
        }, &context)
        
        // 3. 将 reachability 加入执行队列
        let queueEnable = SCNetworkReachabilitySetDispatchQueue(reachability!, DispatchQueue.main)
        
        if closureCallbackEnable && queueEnable {
            print("已监听网络状态")
        }
    }
}

