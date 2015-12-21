//
//  AppDelegate.swift
//  DwindleDating
//
//  Created by Yunas Qazi on 1/15/15.
//  Copyright (c) 2015 infinione. All rights reserved.
//

import UIKit

//let BFTaskMultipleExceptionsException = "BFMultipleExceptionsException";
import Parse


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private(set) var playController: GamePlayController!
    private(set) var matchChatController: MatchChatController!
    var apsUserInfo: [String:AnyObject]? = nil
    
    var window: UIWindow?
    
    class func sharedAppDelegat() -> AppDelegate {
        let appdelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appdelegate
    }
    
    func setupUser() -> Void{
        
    }
    func registerForPushNotifications(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject:AnyObject]?){
        
        //Setup
        Parse.setApplicationId("HEQ0TQq0Qvqdy7BAGii05miGcVp5AcvGbnvdhxQd",
            clientKey: "nXBmYwFcFaWLnykLWFL2NQpY5XSLyC5MbnRrCUKc")
        
        // Register for Push Notitications
        if application.applicationState != UIApplicationState.Background {
            // Track an app open here if we launch with a push, unless
            // "content_available" was used to trigger a background push (introduced in iOS 7).
            // In that case, we skip tracking here to avoid double counting the app-open.
            
            let preBackgroundPush = !application.respondsToSelector("backgroundRefreshStatus")
            let oldPushHandlerOnly = !self.respondsToSelector("application:didReceiveRemoteNotification:fetchCompletionHandler:")
            var pushPayload = false
            if let options = launchOptions {
                pushPayload = options[UIApplicationLaunchOptionsRemoteNotificationKey] != nil
            }
            if (preBackgroundPush || oldPushHandlerOnly || pushPayload) {
                PFAnalytics.trackAppOpenedWithLaunchOptionsInBackground(
                    launchOptions, block: { (status:Bool, error:NSError?) -> Void in
                        //code
                })
            }
        }
        if application.respondsToSelector("registerUserNotificationSettings:") {
            
            let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
            
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let installation = PFInstallation.currentInstallation()
        installation.setDeviceTokenFromData(deviceToken)
        installation.saveInBackgroundWithBlock(nil)
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        if error.code == 3010 {
            print("Push notifications are not supported in the iOS Simulator.")
        } else {
            print("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
        }
        
    }
 
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        
        PFPush.handlePush(userInfo)
        
        if application.applicationState == UIApplicationState.Inactive {

            PFAnalytics.trackAppOpenedWithRemoteNotificationPayloadInBackground(userInfo, block: { (status:Bool, error:NSError?) -> Void in
            })
        }
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        playController = storyboard.instantiateViewControllerWithIdentifier(GamePlayController.nameOfClass) as! GamePlayController
        matchChatController = storyboard.instantiateViewControllerWithIdentifier(MatchChatController.nameOfClass) as! MatchChatController

        self.registerForPushNotifications(application, didFinishLaunchingWithOptions: launchOptions)
        
        FBLoginView.self
        FBProfilePictureView.self
        
        self.updateAppearance(application)
        
        if let launchOption = launchOptions,
            let userInfo = launchOption[UIApplicationLaunchOptionsRemoteNotificationKey] as? [String:AnyObject],
            let aps = userInfo["aps"] as? [String:AnyObject] {
                // Application is launched because of Push notification.
                print("aps: \(userInfo):\n\n\(aps)")
                
                apsUserInfo = userInfo
        }
        
        return true
    }

    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        //code
        let wasHandled:Bool = FBAppCall.handleOpenURL(url, sourceApplication: sourceApplication)
        return wasHandled
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    //MARK: UIAppearance
    
    private func updateAppearance(application:UIApplication) {
        
        application.setStatusBarStyle(UIStatusBarStyle.LightContent, animated: false)
        
        let navigationBarAppearace = UINavigationBar.appearance()
        
        navigationBarAppearace.barTintColor = UIColor(red: 0/255.0, green: 129/255.0, blue: 173/255.0 , alpha: 1.0)
        navigationBarAppearace.barStyle = UIBarStyle.Default
        
        navigationBarAppearace.tintColor = UIColor.whiteColor()
        navigationBarAppearace.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]
    }
    
    private func handlePushNotification(payload: [NSObject : AnyObject]) {
        
    }
}

