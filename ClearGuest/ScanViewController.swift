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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.title = "二维码扫描"
        self.view.backgroundColor = UIColor.grayColor()
        
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.Default
        let item0 = UIBarButtonItem(image:(UIImage(named:"ocrBack.png")), style:(UIBarButtonItemStyle.Bordered), target:self, action:(Selector("backClick")))
        let flexibleSpaceItem = UIBarButtonItem(barButtonSystemItem : (UIBarButtonSystemItem.FlexibleSpace), target: self, action: nil)
        toolBar.items = [item0,flexibleSpaceItem,flexibleSpaceItem]
        toolBar.frame = CGRectMake(0, UIScreen.mainScreen().bounds.size.height-44, 320, 44)
        self.view.addSubview(toolBar)
    }
    
    func backClick(){
        self.dismissViewControllerAnimated(true, completion: nil)
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
            var metadataObject = metadataObjects[0] as AVMetadataMachineReadableCodeObject
            stringValue = metadataObject.stringValue
        }
        
        println("code is \(stringValue)")
        loginToClearGuest(stringValue!)
    }
    
    //处理alert 的button click。 关闭程序
    func alertView(alertView: UIAlertView!, clickedButtonAtIndex buttonIndex: Int){
        abort()
    }
    
    //包装Form表单 提交login
    func loginToClearGuest(qrCode : String){
        let parameters = [
            "username": "guest",
            "password": qrCode,
            "buttonClicked" : "4"
        ]
        
        println("teset here:" + qrCode)
        
        var alertView = UIAlertView()
        alertView.delegate=self
        alertView.title = "clear-guest"
        alertView.message = "登陆成功！"
        alertView.addButtonWithTitle("确认")
        
        Alamofire.request(.POST, "https://webauth-redirect.oracle.com/login.html", parameters: parameters).response { (request, response, data, error) in
            if(response?.statusCode == 200){
                alertView.show()
            }
        }
    
    }
    
    
}