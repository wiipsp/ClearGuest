//
//  AppDelegate.swift
//  Demo
//
//  Created by Quant on 14-8-29.
//  Copyright (c) 2014年 Quant. All rights reserved.
//

import UIKit

var kAppId:String = "vSlF5VVrfrAhFuxNCkfDv1"
var kAppKey:String = "BBgDzeNiFy5N5t81KJ1zW5"
var kAppSecret:String = "ModuVvpfhKAl9Og18sH1k1"

enum SdkStatus {
    case Stoped
    case Starting
    case Started
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GexinSdkDelegate {
    
    var window: UIWindow!
    
    var _gexinPusher: GexinSdk?
    var _appID: String?
    var _appKey: String?
    var _appSecret: String?
    var _clientId: String?
    var _sdkStatus: SdkStatus = SdkStatus.Stoped
    
    var _lastPayloadIndex: Int = -1
    var _payloadId: String?
    var _lastPaylodIndex: Int = 0
    var _deviceToken: String?
    
    // UIApplicationDelegate Method
    
    func registerRemoteNotification() {
        let result = UIDevice.currentDevice().systemVersion.compare("8.0.0", options: NSStringCompareOptions.NumericSearch)
        if (result != NSComparisonResult.OrderedAscending) {
            UIApplication.sharedApplication().registerForRemoteNotifications()
            
            let notificationType = UIUserNotificationType.Alert | UIUserNotificationType.Badge | UIUserNotificationType.Sound
            let setting: UIUserNotificationSettings = UIUserNotificationSettings(forTypes: notificationType, categories: nil)
            UIApplication.sharedApplication().registerUserNotificationSettings(setting)
        } else {
            let notificationType = UIRemoteNotificationType.Alert | UIRemoteNotificationType.Badge | UIRemoteNotificationType.Sound
            UIApplication.sharedApplication().registerForRemoteNotificationTypes(notificationType)
        }
        
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // [1]:使用APPID/APPKEY/APPSECRENT创建个推实例
        self.startSdkWith(kAppId, appKey:kAppKey, appSecret:kAppSecret)
        
        // [2]:注册APNS
        self.registerRemoteNotification()
        
        // [2-EXT]: 获取启动时收到的APN
        
        if (launchOptions != nil) {
            let message: AnyObject! = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? NSDictionary;
            if (message != nil) {
                let payloadMsg = message["payload"];
                
                let record = String("[APN] \(NSDate()), \(payloadMsg)")
                
//                logMsg(record)
            }
            
            UIApplication.sharedApplication().cancelAllLocalNotifications()
            UIApplication.sharedApplication().applicationIconBadgeNumber = 0;
        }
        return true
    }
    
    func applicationDidEnterBackground(application: UIApplication!) {
        self.stopSdk()
    }
    
    func applicationDidBecomeActive(application: UIApplication!) {
        self.startSdkWith(_appID, appKey: _appKey, appSecret: _appSecret)
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        
        let token = deviceToken.description.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "<>"));
        
        _deviceToken = nil
        _deviceToken = token.stringByReplacingOccurrencesOfString(" ", withString: "");
        
        // [3]:向个推服务器注册deviceToken
        if (_gexinPusher != nil) {
            _gexinPusher?.registerDeviceToken(_deviceToken);
        }
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        // [3-EXT]:如果APNS注册失败，通知个推服务器
        if (_gexinPusher != nil) {
            _gexinPusher?.registerDeviceToken("");
        }
        
        logMsg("didFailToRegisterForRemoteNotificationsWithError:\(error.localizedDescription)");
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        UIApplication.sharedApplication().cancelAllLocalNotifications();
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0;
        
        // [4-EXT]:处理APN
        let payloadMsg: AnyObject? = userInfo["payload"];
        let record = "[APN]\(NSDate()),\(payloadMsg)";
//        logMsg(record);
    }
    
    //private Method
    func startSdkWith(appID: String!, appKey: String!, appSecret: String!) {
        if (_gexinPusher == nil) {
            _sdkStatus = SdkStatus.Stoped
            self._appID = appID;
            self._appKey = appKey;
            self._appSecret = appSecret;
            
            _clientId = nil
            
            var err: NSError?
            _gexinPusher = GexinSdk.createSdkWithAppId(_appID, appKey:_appKey, appSecret:_appSecret, appVersion:"0.0.0", delegate:self, error:&err)
            
            if (_gexinPusher == nil) {
                logMsg(err!.description)
            } else {
                _sdkStatus = SdkStatus.Starting;
            }
            
            updateStatusView()
        }
        
    }
    
    func stopSdk() {
        if (_gexinPusher != nil) {
            _gexinPusher!.destroy()
            _gexinPusher = nil;
            
            _sdkStatus = SdkStatus.Stoped;
            
            updateStatusView()
            
            _clientId = nil
        }
    }
    
    func checkSdkInstance() ->Bool {
        if (_gexinPusher == nil) {
            let alert = UIAlertView(title: "错误", message: "SDK未启动", delegate: nil, cancelButtonTitle: "Ok")
            alert.show()
            return false;
        }
        return true;
    }
    
    func setDeviceToken(aToken: String!) {
        if(self.checkSdkInstance() == false) {
            return
        }
        
        _gexinPusher!.registerDeviceToken(aToken)
    }
    
    func setTags(aTags: NSArray)->Bool {
        if(self.checkSdkInstance() == false) {
            return false
        }
        
        return _gexinPusher!.setTags(aTags as [AnyObject]);
    }
    
    
    func sendMessage(msg: NSData)->(body: String?, error: NSError?) {
        if(self.checkSdkInstance() == false) {
            return (nil, nil)
        }
        
        var err: NSError?
        var str = _gexinPusher!.sendMessage(msg, error: &err)
        
        return (str, err)
    }
    
    func logMsg(record: String) {
        let values = ["record": record]
        NSNotificationCenter.defaultCenter().postNotificationName("logMsg", object: nil, userInfo: values)
    }
    
    func updateStatusView() {
        let values = ["appDelegate": self]
        NSNotificationCenter.defaultCenter().postNotificationName("updateStatusView", object: nil, userInfo: values)
    }
    
    // - GexinSdkDelegate
    func GexinSdkDidRegisterClient(clientId: String) {
        // [4-EXT-1]: 个推SDK已注册
        self._sdkStatus = SdkStatus.Started;
        
        _clientId = clientId as String
        
        self.updateStatusView()
    }
    
    func GexinSdkDidReceivePayload(payloadId: String!, fromApplication appId: String!) {
        self._payloadId = payloadId as String;
        
        let payload = self._gexinPusher!.retrivePayloadById(payloadId as String)
        
        var payloadMsg: NSString?
        
        if (payload != nil) {
            payloadMsg = NSString(bytes: payload.bytes, length: payload.length, encoding: NSUTF8StringEncoding)
        }
        
        let record: String = "\(payloadMsg!)"
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0;
        logMsg(record)
    }
    
    func GexinSdkDidSendMessage(messageId: String!, result: Int32) {
        let record: String = "Received sendmessage:\(messageId) result:\(result)"
        logMsg(record)
    }
    
    func GexinSdkDidOccurError(error: NSError) {
        // [EXT]:个推错误报告，集成步骤发生的任何错误都在这里通知，如果集成后，无法正常收到消息，查看这里的通知。
        logMsg(">>>[GexinSdk error]:\(error.localizedDescription)")
    }
    
}

