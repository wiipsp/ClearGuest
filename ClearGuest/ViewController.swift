//
//  ViewController.swift
//  ClearGuest
//
//  Created by Kobe on 14/12/11.
//  Copyright (c) 2014年 kobe. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import Alamofire
import SystemConfiguration

let KShowScanViewIdentifier: String = "showScanView"
let ContactFilePath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0].stringByAppendingPathComponent("pwd.data")

//扩展UIDevice类的方法
extension UIDevice {
    public var SSID: String? {
        get {
            if let interfaces = CNCopySupportedInterfaces() {
                let interfacesArray = interfaces.takeRetainedValue() as! [String]
                if let unsafeInterfaceData = CNCopyCurrentNetworkInfo(interfacesArray.first) {
                    let interfaceData = unsafeInterfaceData.takeRetainedValue() as Dictionary
                    return interfaceData["SSID"] as? String
                }
            }
            return nil
        }
    }
}

class ViewController: UIViewController, UIAlertViewDelegate {
    
    @IBOutlet weak var localPwd: UILabel!
    @IBOutlet weak var networkStatus: UILabel!
    @IBOutlet weak var getServerPwdBtn: UIButton!
    @IBOutlet weak var pushToLogin: UIButton!
    @IBOutlet weak var exitBtn: UIButton!
    var pushPwd:String?
    let opaqueview : UIView = UIView()
    let activityIndicator : UIActivityIndicatorView  = UIActivityIndicatorView()
    
    //启动等待菊花
    func startWaitingImg(){
        activityIndicator.startAnimating()
        opaqueview.hidden = false
    }
    //关闭等待菊花
    func stopWaitingImg(){
        activityIndicator.stopAnimating()
        opaqueview.hidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Clear-Guest WIFI登录器"
        //设置按钮圆角
        pushToLogin.layer.cornerRadius = 3
        getServerPwdBtn.layer.cornerRadius = 3
        exitBtn.layer.cornerRadius = 3
        //启动监听如果有推送调用logMsg方法
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "logMsg:", name: "logMsg", object: nil)
        //先把当前密码显示出来
        getLatestPwd()
        //启动监听当前网络状态
        let reachability = Reachability.reachabilityForInternetConnection()
        reachabilityChanged(NSNotification(name: ReachabilityChangedNotification, object: reachability, userInfo: nil))
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityChanged:", name: ReachabilityChangedNotification, object: reachability)
        //程序启动后检测当天网络状态
        reachability.startNotifier()
        
        //绘制等待菊花
        opaqueview.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, UIScreen.mainScreen().bounds.size.height)
        activityIndicator.frame = CGRectMake(50,50,50,50)
        activityIndicator.center = opaqueview.center
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.White
        opaqueview.backgroundColor = UIColor.blackColor()
        opaqueview.alpha = 0.8
        self.view.addSubview(opaqueview)
        opaqueview.addSubview(activityIndicator)
        activityIndicator.stopAnimating()
        opaqueview.hidden = true
    }
    //当有推送过来的操作
    func logMsg(notification: NSNotification) {
        let pwd = notification.userInfo!["record"] as! String
        println("get record Pwd:" + pwd)
        NSKeyedArchiver.archiveRootObject(pwd, toFile: ContactFilePath)
        getLatestPwd()
    }
    //关闭程序
    func exitProgram(){
        abort()
    }
    //网络改变的操作
    func reachabilityChanged(note: NSNotification) {
        var response = ""
        let reachability = note.object as! Reachability
        if reachability.isReachable() {
            if reachability.isReachableViaWiFi() {
                if (UIDevice.currentDevice().SSID != nil) {
                    response = "当前wifi为: \(UIDevice.currentDevice().SSID!)"
                }
            } else {
                response = "当前使用的是移动网络"
            }
        } else {
            response = "当前没有网络"
        }
        
        networkStatus.text = response
    }
    //把密码存入本地
    func getLatestPwd(){
        println("从归档中提取")
        self.pushPwd = NSKeyedUnarchiver.unarchiveObjectWithFile(ContactFilePath) as! String!
        if(pushPwd == nil){
            println("归档中没有，创建数组")
            pushPwd = String()
        }
        
        let response = "当前密码为: \(pushPwd!)"
        localPwd.text = response
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginByScan(sender: UIButton) {
        if UIDevice.currentDevice().SSID == "clear-guest" {
            self.performSegueWithIdentifier(KShowScanViewIdentifier, sender: self);
        }else{
            var alertView = UIAlertView()
            alertView.title = "clear-guest"
            alertView.message = "当前WIFI不是clear-guest，请连接后再试"
            alertView.addButtonWithTitle("确认")
            alertView.show()
        }
    }
    
    @IBAction func getServerPwd(sender: AnyObject) {
        startWaitingImg()
        Alamofire.request(.GET, "http://kobe.ora2000.com/ClearGuestWebservice/rest/clearguest/getLatestClearguestPwd")
            .responseString { (_, _, result, _) in
                self.stopWaitingImg()
                if (result == nil) {
                    var alertView = UIAlertView()
                    alertView.title = "clear-guest"
                    alertView.message = "当前服务器返回密码为空，请稍后再试"
                    alertView.addButtonWithTitle("确认")
                    alertView.show()
                }else if(result!.hasPrefix("<")){
                    var alertView = UIAlertView()
                    alertView.title = "clear-guest"
                    alertView.message = "请先连接到internet，然后再获取密码"
                    alertView.addButtonWithTitle("确认")
                    alertView.show()
                }else{
                    NSKeyedArchiver.archiveRootObject(result!, toFile: ContactFilePath)
                    self.getLatestPwd()
                }
                
        }
    }
    
    @IBAction func loginByPush(sender: UIButton) {
        if(pushPwd == nil || pushPwd!.isEmpty){
            var alertView = UIAlertView()
            alertView.title = "clear-guest"
            alertView.message = "密码为空！"
            alertView.addButtonWithTitle("确认")
            alertView.show()
        }else{
            if UIDevice.currentDevice().SSID?.lowercaseString == "clear-guest" {
                loginToClearGuest(pushPwd!)
            }else{
                var alertView = UIAlertView()
                alertView.title = "clear-guest"
                alertView.message = "当前WIFI不是clear-guest，请连接后再试"
                alertView.addButtonWithTitle("确认")
                alertView.show()
            }
        }
    }
    
    @IBAction func exitApp(sender: UIButton) {
        exitProgram()
    }
    //处理alert 的button click。 关闭程序
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int){
        exitProgram()
    }
    
    //包装Form表单 提交login
    func loginToClearGuest(qrCode : String){
        startWaitingImg()
        let parameters = [
            "username": "guest",
            "password": qrCode,
            "buttonClicked" : "4"
        ]
        
        println("teset here:" + qrCode)
        
        var alertView = UIAlertView()
        alertView.title = "clear-guest"
        alertView.message = "登陆成功！"
        alertView.addButtonWithTitle("确认")
        
        Alamofire.request(.POST, "https://webauth-redirect.oracle.com/login.html", parameters: parameters).response { (request, response, data, error) in
            self.stopWaitingImg()
            if(response?.statusCode == 200){
                alertView.delegate=self
                alertView.show()
            }else{
                alertView.message = "登陆失败！"
                alertView.show()
            }
        }
        
    }
}

