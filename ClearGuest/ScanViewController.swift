//
//  ScanViewController.swift
//  ClearGuest
//
//  Created by Kobe on 14/12/11.
//  Copyright (c) 2014年 kobe. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import Alamofire

class ScanViewController: UIViewController, UIAlertViewDelegate, AVCaptureMetadataOutputObjectsDelegate {
    
    
    let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    let session = AVCaptureSession()
    var layer: AVCaptureVideoPreviewLayer?
    let opaqueview : UIView = UIView()
    let activityIndicator : UIActivityIndicatorView  = UIActivityIndicatorView()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.title = "二维码扫描登录"
        self.view.backgroundColor = UIColor.grayColor()
        
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.setupCamera()
        self.session.startRunning()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
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
    
    func setupCamera(){
        self.session.sessionPreset = AVCaptureSessionPresetHigh
        var error : NSError?
        let input = AVCaptureDeviceInput(device: device, error: &error)
        if (error != nil) {
            println(error!.description)
            return
        }
        if session.canAddInput(input) {
            session.addInput(input)
        }
        layer = AVCaptureVideoPreviewLayer(session: session)
        layer!.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        layer!.frame = self.view.bounds
        
        self.view.layer.insertSublayer(self.layer, atIndex: 0)
        let output = AVCaptureMetadataOutput()
        output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.metadataObjectTypes = [AVMetadataObjectTypeQRCode];
        }
        
        session.startRunning()
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject], fromConnection connection: AVCaptureConnection!){
        self.session.stopRunning()
        var stringValue:String?
        if metadataObjects.count > 0 {
            var metadataObject = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            stringValue = metadataObject.stringValue
        }
        
        println("code is \(stringValue)")
        loginToClearGuest(stringValue!)
    }
    
    //处理alert 的button click。 关闭程序
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int){
        abort()
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