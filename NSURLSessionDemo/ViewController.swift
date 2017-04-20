//
//  ViewController.swift
//  NSURLSessionDemo
//
//  Created by 婉卿容若 on 2017/4/20.
//  Copyright © 2017年 婉卿容若. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var delegate: URLSessionDelegate?
    
    var  downloadSession: URLSession?
    var downlaodTask: URLSessionDownloadTask?

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
        var hostString = "https://httpbin.org/ip"
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
