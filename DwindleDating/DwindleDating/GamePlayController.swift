//
//  GamePlayController.swift
//  DwindleDating
//
//  Created by Yunas Qazi on 1/27/15.
//  Copyright (c) 2015 infinione. All rights reserved.
//

import UIKit


//, KDCycleBannerViewDelegate
class GamePlayController: JSQMessagesViewController,
UIActionSheetDelegate,
KDCycleBannerViewDataource,
KDCycleBannerViewDelegate,
SocketIODelegate {

    
    @IBOutlet var scroller : KDCycleBannerView!
    
    var playerMain : Player!
    var playerOpponent: Player!
    var playerOther1 : Player!
    var playerOther2 : Player!
    var playerOther3 : Player!
    var socketIO     :SocketIO?
    
    @IBOutlet weak var galleryHeightConstraint : NSLayoutConstraint?
    
    @IBOutlet var imagesViewContainer : UIView!
    
    var galleryOpenerButton : UIButton!
    var demoData: DemoModelData!
    
    
    
    
    func receiveMessagePressed(sender: UIBarButtonItem){
        
        
    }
    
    func closePressed(sender: UIBarButtonItem){
        
        
        
    }
    
    
    // MARK: - Scroller Stuff - KDCycleBannerView DELEGATE
    
    func placeHolderImageOfBannerView(bannerView: KDCycleBannerView!, atIndex index: UInt) -> UIImage! {
        let img = UIImage(named:"image1.png")!
        return img
    }
    
    func placeHolderImageOfZeroBannerView() -> UIImage! {
        let img = UIImage(named:"image1.png")!
        return img
    }
    
    
    // MARK : KDCycleBannerView DataSource
    func numberOfKDCycleBannerView(bannerView: KDCycleBannerView!) -> [AnyObject]! {
        let imagesList   = [UIImage(named:"signup_01")!,
                            UIImage(named:"signup_02")!,
                            UIImage(named:"signup_03")!]
        
        return imagesList
    }
    
    
    func contentModeForImageIndex(index: UInt) -> UIViewContentMode {
        return UIViewContentMode.ScaleAspectFit;
    }

    
    
        // MARK: - Action Methods

    
    @IBAction func openImageGallery(sender: AnyObject) {
  
        var button = sender as? UIButton
        println("tagId\(button?.tag)")
        
        if var prevButton = galleryOpenerButton{
            if (prevButton.isEqual(button)){
                println("Same Button")
            }
            else{
                galleryOpenerButton.tag = 0
                galleryOpenerButton = button
                println("Different Button")
            }
        }
        else{
            // cacheId is nil
            
            galleryOpenerButton = button
            println("Setting Button")
        }

        
        if (galleryOpenerButton!.tag == 0){
            galleryOpenerButton!.tag = 1
            galleryHeightConstraint!.constant = 275
        }
        else if (galleryOpenerButton!.tag == 1){
            galleryOpenerButton!.tag = 0
            galleryHeightConstraint!.constant = 0
        }
        
        UIView.animateWithDuration(0.5) {
            self.view.needsUpdateConstraints()
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Utilty Methods
    
 
    func JSONParseArray(jsonString: String) -> [AnyObject] {
        if let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding) {
            if let array = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: nil)  as? [AnyObject] {
                return array
            }
        }
        return [AnyObject]()
    }
    
    
    // MARK: -   WEBSERVICE
    
    func gamePlay(){
        var settings = UserSettings.loadUserSettings()
        
        ProgressHUD.show("Commencing Game...")
        
        var manager = ServiceManager()
        
        
        manager.getGamePlayUsersAgainstFacebookId(settings.fbId, sucessBlock: { (allPlayers:[NSObject: AnyObject]!) -> Void in
            
            var data:NSDictionary = allPlayers as NSDictionary
            println("players \(data)")
            
            // code
            self.playerMain      = data["MainPlayer"] as? Player
            self.playerOpponent  = data["OpponentPlayer"] as? Player
            
            var otherData = data["Others"] as! NSArray
            self.playerOther1 = otherData[0] as? Player
            self.playerOther2 = otherData[1] as? Player
            self.playerOther3 = otherData[2] as? Player
            
            ProgressHUD.showSuccess("Game Commenced Succesfully")
            
            
            
            println("PlayerMain = \(self.playerMain.fbId)")
            println("PlayerOpponent = \(self.playerOpponent.fbId)")
            println("PlayerOther1 = \(self.playerOther1.fbId)")
            println("PlayerOther2 = \(self.playerOther2.fbId)")
            println("PlayerOther3 = \(self.playerOther3.fbId)")
            
            //Open Socket
            
            self.startGame()
            
            }) { (error: NSError!) -> Void in
                // code
                ProgressHUD.showError("Game Commencing Failed")
        }
        
    }
 
    
    
    // MARK: - SOCKETS
    
    func initSocketConnection(){
        
        // create socket.io client instance
        
        self.socketIO = SocketIO(delegate: self)
        
        
        var properties = [NSHTTPCookieDomain:"52.11.98.82",
                          NSHTTPCookiePath:"/",
                          NSHTTPCookieName:"auth",
                          NSHTTPCookieValue:"56cdea636acdf132"]
        
    

        var cookie:NSHTTPCookie = NSHTTPCookie(properties: properties)!
        var cookies = [cookie]
        
        self.socketIO?.cookies = cookies
        
        self.socketIO?.connectToHost("52.11.98.82", onPort: 3000)

    }
    
    
    func startGame(){
        
        self.initSocketConnection();
        
    }
    
    
    func sendChat(message:String){
        self.socketIO?.sendEvent("sendchat", withData: [message])
    }
    
    // MARK: -   SOCKET DELEGATES
    
    
    
    
    func socketIODidConnect(socket: SocketIO!) {
        println("socket.io connected.")
        
        var playerId:String = self.playerMain.fbId
        println("Info\(playerId)")
        
        self.socketIO?.sendEvent("addMainUser", withData: [playerId])
//        self.socketIO?.sendEvent("addMainUser", withData: data)
//        socketIO?.sendEvent("addMainUser", withData: data)
//        [socketIO sendEvent:@"addUser" withData:@[@"yunas",@"alirajab"]];

    }
    
    
    
    func socketIO(socket: SocketIO!, didReceiveMessage packet: SocketIOPacket!) {
        //code
        println("PacketName \(packet.name)")
        
    }
    
    
    func socketIO(socket: SocketIO!, didReceiveEvent packet: SocketIOPacket!) {
        //code
        println("PacketName \(packet.name)")
        

        
        if (packet.name == "mainuseradded") {
             println("\n MainUserAdded data as string looks like \(packet.data)")
            var playerId:String = self.playerMain.fbId
            var playerOpponentId:String = self.playerOpponent.fbId
            println("playerId \(playerId) andOpponentPlayerId\(playerOpponentId)")
//            self.socketIO?.sendEvent("addUser", withData: [playerOpponentId,playerId])
        }
        else if (packet.name == "useradded"){

            println("\n UserAdded data as string looks like \(packet.data)")
//            self.socketIO?.sendEvent("sendchat", withData: ["message from yunas"])
        }
        
        else if (packet.name == "updatechat"){
            println("\n \(packet.name) data as string looks like \(packet.data)")
        }
        
        else if (packet.name == "adduserspic"){
            println("\n \(packet.name) data as string looks like \(packet.data)")
        }
        else if (packet.name == "deleteuser"){
            println("\n \(packet.name) data as string looks like \(packet.data)")
        }
        
//        if (packet.name == "updaterooms") {
//           
////            self.JSONParseArray(packet.dataAsJSON())
////            let dictionary = self.JSONParseDictionary(packet.data)
//
//            let responseArr:AnyObject = packet.dataAsJSON()
//            println("updateRooms data looks like \(responseArr)")
//            println("\n updateRooms data as string looks like \(packet.data)")
//            
//            
////            let connectedInfoDict: AnyObject! = responseArr[1]
//            let connectedInfoDict: Dictionary<String, AnyObject> = (responseArr[1] as? Dictionary)!
//            
//            let userName = connectedInfoDict["name"] as? String
//            
////            if( userName == self.playerMain.fbId){
////                var playerId:String = self.playerMain.fbId
////                var playerOpponentId:String = self.playerOpponent.fbId
////                println("playerId \(playerId) andOpponentPlayerId\(playerOpponentId)")
////                
////                self.socketIO?.sendEvent("addUser", withData: [playerOpponentId,playerId])
////
////            }
//            
//            
//        }

    }
    
    
    func socketIO(socket: SocketIO!, onError error: NSError!) {
        //
        
        var errorCode = error.code as Int
        if (errorCode == -8) { //SocketIOUnauthorized
            println("not authorized");
        } else {
            println("onError()\(error)");
        }

    }
    
    
    func socketIODidDisconnect(socket: SocketIO!, disconnectedWithError error: NSError!) {
        //code
        
        println("socket.io disconnected. did error occur? \(error)");
        var state:UIApplicationState  = UIApplication.sharedApplication().applicationState
        if (state == UIApplicationState.Background) {//UIApplicationStateBackground
            println("Application is in background and SIO disconnected.");
        }


    }

    
        // MARK: -   VIEW LIFE CYCLE
    func initContentView(){
        // Scroll Initialization
        scroller.autoPlayTimeInterval = 0;
        scroller.continuous = true;
        
        
        // Message Controller Stuff
        
        /**
        *  You MUST set your senderId and display name
        */
        self.senderId = "053496-4509-289"//kJSQDemoAvatarIdSquires;
        self.senderDisplayName = "Jesse Squires"// kJSQDemoAvatarDisplayNameSquires;
        
        self.demoData = DemoModelData()
        
        if (!NSUserDefaults.incomingAvatarSetting()){
            self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
        }
        
        if (!NSUserDefaults.outgoingAvatarSetting()) {
            self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
        }
        
        self.showLoadEarlierMessagesHeader = true
        self.jsq_configureMessagesViewController();
        self.jsq_registerForNotifications(true);
    
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.collectionView.collectionViewLayout.springinessEnabled = NSUserDefaults.springinessSetting();
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.title = "Chat Controller"
        self.initContentView()
        
//        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.jsq_defaultTypingIndicatorImage(), style: UIBarButtonItemStyle.Bordered, target: self, action: "receiveMessagePressed:")

        //        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Home", style:UIBarButtonItemStyle.Bordered , target: self, action: "receiveMessagePressed:")

        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Skip", style:UIBarButtonItemStyle.Bordered , target: self, action: "receiveMessagePressed:")

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //============================================================================================\\
    //============================================================================================\\
    //============================================================================================\\
    //============================================================================================\\
    // MARK: -   Actions
    
    func receivedMessagePressed(sender: UIBarButtonItem) {
        // Simulate reciving message
        showTypingIndicator = !showTypingIndicator
        scrollToBottomAnimated(true)
    }
    
    
    //============================================================================================\\
    //============================================================================================\\
    //============================================================================================\\
    //============================================================================================\\
    // MARK: -   JSQMessagesViewController method overrides
    
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        
        /**
        *  Sending a message. Your implementation of this method should do *at least* the following:
        *
        *  1. Play sound (optional)
        *  2. Add new id<JSQMessageData> object to your data source
        *  3. Call `finishSendingMessage`
        */
        JSQSystemSoundPlayer.jsq_playMessageSentSound();
        
        var message = JSQMessage(senderId: senderId, senderDisplayName: senderDisplayName, date: date, text: text)
        
        self.demoData.messages.addObject(message);
        
        self.finishSendingMessageAnimated(true);
        
        self.sendChat(text)
        
        
    }
    
    
    
    override func didPressAccessoryButton(sender: UIButton!) {
        
        
        var sheet = UIActionSheet(title: "Quick messages", delegate:self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Send Template Message 1", "Send Template Message 2");
        
        //    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Media messages"
        //    delegate:self
        //    cancelButtonTitle:@"Cancel"
        //    destructiveButtonTitle:nil
        //    otherButtonTitles:@"Send photo", @"Send location", @"Send video", nil];
        sheet.showFromToolbar(self.inputToolbar);
    }
    
    
    
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        if (buttonIndex == actionSheet.cancelButtonIndex) {
            return;
        }
        
        switch (buttonIndex) {
        case 1:
//            self.demoData.addPhotoMediaMessage();
            self.demoData.sendTextMessage("Sample text message 1");
            break;
            
        case 2:
            self.demoData.sendTextMessage("Sample text message 2");
            //var weakView = self.collectionView as UICollectionView;
            //self.demoData.addLocationMediaMessageCompletion({ () -> Void in
             //   weakView.reloadData();
            //});
            
            break;
            
//        case 3:
//            self.demoData.addVideoMediaMessage();
//            break;
            
        default:
            
            break;
            
        }
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound();
        self.finishSendingMessageAnimated(true);
    }
    
    //============================================================================================\\
    //============================================================================================\\
    //============================================================================================\\
    //============================================================================================\\
    // MARK: -  JSQMessages CollectionView DataSource
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return self.demoData.messages[indexPath.item] as! JSQMessageData
    }
    
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        /**
        *  You may return nil here if you do not want bubbles.
        *  In this case, you should set the background color of your collection view cell's textView.
        *
        *  Otherwise, return your previously created bubble image data objects.
        */
        
        var message : JSQMessage = self.demoData.messages [indexPath.item] as! JSQMessage
        if (message.senderId == self.senderId) {
            return self.demoData.outgoingBubbleImageData;
        }
        
        return self.demoData.incomingBubbleImageData;
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        
        /**
        *  Return `nil` here if you do not want avatars.
        *  If you do return `nil`, be sure to do the following in `viewDidLoad`:
        *
        *  self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
        *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
        *
        *  It is possible to have only outgoing avatars or only incoming avatars, too.
        */
        
        /**
        *  Return your previously created avatar image data objects.
        *
        *  Note: these the avatars will be sized according to these values:
        *
        *  self.collectionView.collectionViewLayout.incomingAvatarViewSize
        *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize
        *
        *  Override the defaults in `viewDidLoad`
        */
        
        var message : JSQMessage = self.demoData.messages [indexPath.item] as! JSQMessage
        
        if (message.senderId == self.senderId) {
            if (!NSUserDefaults.outgoingAvatarSetting()) {
                return nil;
            }
        }
        else {
            if (!NSUserDefaults.incomingAvatarSetting()) {
                return nil;
            }
        }
        
        return nil;
        //return self.demoData.avatars[message.senderId] as JSQMessageAvatarImageDataSource;
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        
        /**
        *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
        *  The other label text delegate methods should follow a similar pattern.
        *
        *  Show a timestamp for every 3rd message
        */
        if (indexPath.item % 3 == 0) {
            var message : JSQMessage = self.demoData.messages [indexPath.item] as! JSQMessage
            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(message.date)
        }
        
        return nil;
    }
    
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        
        var message : JSQMessage = self.demoData.messages [indexPath.item] as! JSQMessage
        
        /**
        *  iOS7-style sender name labels
        */
        if (message.senderId  == self.senderId) {
            return nil;
        }
        
        if (indexPath.item - 1 > 0) {
            var previousMessage: JSQMessage = self.demoData.messages[indexPath.item - 1]as! JSQMessage;
            if (previousMessage.senderId == message.senderId) {
                return nil;
            }
        }
        
        /**
        *  Don't specify attributes to use the defaults.
        */
        return NSAttributedString(string: message.senderDisplayName);
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        
        return nil;
    }
    
    //============================================================================================\\
    //============================================================================================\\
    //============================================================================================\\
    //============================================================================================\\
    // MARK: -  UICollectionView DataSource
    
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: NSInteger) -> NSInteger {
        return self.demoData.messages.count;
    }
    
    
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        if let textView = cell.textView {
            var message = self.demoData.messages[indexPath.item] as! JSQMessage
            if message.senderId == self.senderId {
                textView.textColor = UIColor.whiteColor()
            } else {
                textView.textColor = UIColor.blackColor()
            }
            
            let attributes : [NSObject:AnyObject] = [NSForegroundColorAttributeName:textView.textColor, NSUnderlineStyleAttributeName: 1]
            textView.linkTextAttributes = attributes
            
            //        cell.textView.linkTextAttributes = [NSForegroundColorAttributeName: cell.textView.textColor,
            //            NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle]
        }
        return cell
    }
    
    //============================================================================================\\
    //============================================================================================\\
    //============================================================================================\\
    //============================================================================================\\
    // MARK: - JSQMessages collection view flow layout delegate
    // MARK: - Adjusting cell label heights
    
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        /**
        *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
        */
        
        /**
        *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
        *  The other label height delegate methods should follow similarly
        *
        *  Show a timestamp for every 3rd message
        */
        
        if (indexPath.item % 3 == 0) {
            return kJSQMessagesCollectionViewCellLabelHeightDefault;
        }
        
        return 0.0;
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        /**
        *  iOS7-style sender name labels
        */
        
        var currentMessage :JSQMessage = self.demoData.messages[indexPath.item] as! JSQMessage;
        
        if (currentMessage.senderId == self.senderId) {
            return 0.0;
        }
        
        if (indexPath.item - 1 > 0) {
            var previousMessage :JSQMessage = self.demoData.messages[indexPath.item - 1] as! JSQMessage;
            if (previousMessage.senderId == currentMessage.senderId) {
                return 0.0;
            }
        }
        
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        
        return 0.0;
    }
    
    
    
    //============================================================================================\\
    //============================================================================================\\
    //============================================================================================\\
    //============================================================================================\\
    // MARK: - Responding to collection view tap events
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        println("Load earlier messages!");
        
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, atIndexPath indexPath: NSIndexPath!) {
        println("Tapped avatar!");
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAtIndexPath indexPath: NSIndexPath!) {
        println("Tapped message bubble!");
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapCellAtIndexPath indexPath: NSIndexPath!, touchLocation: CGPoint) {
        println("Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
    }
    
    
    
}

