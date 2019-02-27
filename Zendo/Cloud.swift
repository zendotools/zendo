//
//  Cloud.swift
//  zendoArena
//
//  Created by Douglas Purdy on 2/12/19.
//  Copyright © 2019 Zendo Tools. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase
import FBSDKCoreKit
import Mixpanel

class Cloud
{
    static var enabled = false

    static func updateSample(email: String, content: String, sample: [String : Any])
    {
        
        let value = ["data" : sample,
            "updated" : Date().description,
            "content" : content,
            "email" : email] as [String : Any]
     
        let database = Database.database().reference()
     
        let sample = database.child("samples")
     
        let key = sample.child(email.replacingOccurrences(of: ".", with: "_"))
     
        key.setValue(value)
        {
            (error, ref) in
     
            if let error = error
            {
                print("Data could not be saved: \(error).")
            }
        }
     }
    
    static func updateProgress(email: String, content: String, progress: [String])
    {
        
        let value = ["data" : progress,
                     "updated" : Date().timeIntervalSince1970.description,
                     "content" : content,
                     "email" : email] as [String : Any]
        
        let database = Database.database().reference()
        
        let sample = database.child("progress")
        
        let key = sample.child(email.replacingOccurrences(of: ".", with: "_"))
        
        key.setValue(value)
        {
            (error, ref) in
            
            if let error = error
            {
                print("Data could not be saved: \(error).")
            }
        }
    }

    static func enable(_ application: UIApplication, _ options : [UIApplicationLaunchOptionsKey : Any]?)
    {
        FirebaseApp.configure()
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: options)
        
        Mixpanel.initialize(token: "73167d0429d8da0c05c6707e832cbb46")
        
        BuddyBuildSDK.setup()
        
        CommunityDataLoader.load()
        
        self.enabled = true
    }
    
    typealias SamplesChangedHandler = (_ samples : [String : [String : AnyObject]], _ error: Error? ) -> Void

    static func registerSamplesChangedHandler(handler: @escaping SamplesChangedHandler) -> DatabaseHandle?
    {
        if(!enabled)
        {
            print ("Cloud disabled")
            return nil
        }
        
        let database = Database.database().reference()
        
        let sample = database.child("samples")
        
        let refHandle = sample.observe(DataEventType.value)
        {
            (snapshot) in
            
            if let samples = snapshot.value as? [String : [String : AnyObject]]
            {
                handler(samples, nil)
            }
        }
        
        return refHandle
    }
    
    typealias ProgressChangedHandler = (_ progress : [String : [String : AnyObject]], _ error: Error? ) -> Void
    
    static func registerProgressChangedHandler(handler: @escaping ProgressChangedHandler) -> DatabaseHandle?
    {
        if(!enabled)
        {
            print ("Cloud disabled")
            return nil
        }
        
        let database = Database.database().reference()
        
        let sample = database.child("progress")
        
        let refHandle = sample.observe(DataEventType.value)
        {
            (snapshot) in
            
            if let samples = snapshot.value as? [String : [String : AnyObject]]
            {
                handler(samples, nil)
            }
        }
        
        return refHandle
    }
    
}