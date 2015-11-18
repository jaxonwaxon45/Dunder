//
//  GamePlayController.swift
//  DwindleDating
//
//  Created by Yunas Qazi on 1/27/15.
//  Copyright (c) 2015 infinione. All rights reserved.
//

//TODO:
//Add a boolean isOpponentFound
//Run a timer for 15 secs
//On player found set flag isOpponentFound to true
//Timer will call a method and check the value of flag 
//if its true then ignore else show an alert and call back button pressed 


import UIKit
//import corelocation

//, KDCycleBannerViewDelegate
class GamePlayController: JSQMessagesViewController,
UIActionSheetDelegate,
KDCycleBannerViewDataource,
KDCycleBannerViewDelegate,
SocketIODelegate {

    @IBOutlet var scroller : KDCycleBannerView!
    
    @IBOutlet weak var btn1: RoundButtonView!
    @IBOutlet weak var btn2: RoundButtonView!
    @IBOutlet weak var btn3: RoundButtonView!
    @IBOutlet weak var btn4: RoundButtonView!
    @IBOutlet weak var btn5: RoundButtonView!
    
    
    var playersDict:[String:AnyObject]! = [:]
    
    var playerMain : Player!
    var playerOpponent: Player!
    var playerOther1 : Player!
    var playerOther2 : Player!
    var playerOther3 : Player!
    var playerOther4 : Player!
    var socketIO     :SocketIO?
    var isPlayerFound : Bool?
    
    var randomPlayers:[String]! = []
    
    
    let dwindleSocket = DwindleSocketClient.sharedInstance
    
    @IBOutlet weak var galleryHeightConstraint : NSLayoutConstraint?
    
    @IBOutlet var imagesViewContainer : UIView!
    
    var galleryOpenerButton : RoundButtonView!
    var demoData: DemoModelData!
    
    func handleNoMatchFound (){

        let delay = 10 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            
            if (self.isPlayerFound == false){
                // not found popout
                ProgressHUD.showError("No match found around your area. Please try again later.")
                let delay = 3.5 * Double(NSEC_PER_SEC)
                let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                dispatch_after(time, dispatch_get_main_queue()) {
//                    self.navigationController?.popViewControllerAnimated(true)
                }

            }
            
//            self.resetGameViews()
        }
    }
    
    func alertView(alertView: UIAlertView!, clickedButtonAtIndex buttonIndex: Int){
        switch buttonIndex{
        case 0:
            print("1st")
            if (alertView.tag == 1){
                self.performSkipPressed()
            }
            else{
                self.navigationController?.popViewControllerAnimated(true)
            }

        case 1:
            print("2nd")
        default:
            print("error")
        }
    }

    
    func showAlertWithDelay(shouldPop: Bool){
        let alert: UIAlertView = UIAlertView()
        if (!shouldPop){
            alert.tag = 1;
        }
        
        alert.delegate = self
        
        alert.title = "Quit Game"
        alert.message = "This will end your current game, are you sure?"
        alert.addButtonWithTitle("Yes")
        alert.addButtonWithTitle("Cancel")
        alert.show()
    }
    
    func showBackAlertFromSkip(shouldPop: Bool){
        self.hideKeyboard()
        let delay = 0.5 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            self.showAlertWithDelay(shouldPop)
        }

    }

    override func navigationShouldPopOnBackButton() -> Bool {
        //ASK AGAIN IF USER WANTS TO QUIT THE GAME
        // IF YES THEN pop it
        self.showBackAlertFromSkip(true)
        return false
    }


    func performSkipPressed(){
        
//        let isConnected:Bool = self.socketIO?.isConnected
        
        if let socket = self.socketIO where socket.isConnected == true {
            socket.sendEvent("skip", withData:[])
        }
        
        self.resetGameViews()
    }
    
    func skipPressed(sender: UIBarButtonItem){
        self.showBackAlertFromSkip(false)
    }
    
    // MARK:- KDCycleBannerView DataSource
    func numberOfKDCycleBannerView(bannerView: KDCycleBannerView!) -> [AnyObject]! {
       
        var imagesList:AnyObject = []
        var selectedPlayer: Player!
        
        if var tmpOpener = galleryOpenerButton{
            selectedPlayer = self.getPlayerAgainstId(galleryOpenerButton.playerId)
        }
        
        if var tmpSelectedPlayer = selectedPlayer{

            imagesList = (selectedPlayer.galleryImages as NSArray as? [NSURL])!
            
        }
        else{
            // is nil
                let imagesList   = [UIImage(named:"signup_01")!]
        }
        
        return imagesList as! [AnyObject]
    }
    
    func contentModeForImageIndex(index: UInt) -> UIViewContentMode {
        return UIViewContentMode.ScaleAspectFit;
    }

    
    // MARK: - PlayersManagement - PLAYERS
    
    func handleDeleteUser(response:[String:AnyObject]){

        let deleteUserDict:AnyObject = (response["DeletedUser"] as? Dictionary<String,AnyObject>)!
        let deleteUserFbId:String = (deleteUserDict["fb_id"] as? String)!
        print("DeleteUserFbId => \(deleteUserFbId))")
        
        let btn = self.getPlayerButtonAgainstId(deleteUserFbId)
        btn.selected = false
        btn.enabled = false
        btn.setImage(nil, forState: UIControlState.Normal)

    }

    func handleAddUser(response:[String:AnyObject], key:String){
        
        let userDict:AnyObject = (response[key] as? Dictionary<String,AnyObject>)!
        let userFbId:String = (userDict["fb_id"] as? String)!
        let userImgPath:String = (userDict["pic_path"] as? String)!
        
        let player = self.getPlayerAgainstId(userFbId)
        player.addImageUrlToGallery(userImgPath)
        
        
    }

    func handleFinalDwindleDown (){

        //Close Keyboard
        self.hideKeyboard()

        let button: RoundButtonView = self.getPlayerButtonAgainstId(playerOpponent.fbId)
        let dp = button.imageForState(UIControlState.Normal)

        let dialog = FinalDwindleDownDialog.loadWithNib() as? FinalDwindleDownDialog
//        let dp = UIImage(named: "demo_avatar_woz")
        dialog?.showWithImage(dp, successBlock: { (index: Int32) -> Void in
            //Open Matches Listing
            dialog?.dismissView(true)
            print("Selected Option: \(index)")
            if (index == 0){
                self.performSegueWithIdentifier("pushMatchListing", sender: nil)
            }
            else{
                // Restart Game
                self.socketIO?.sendEvent("restartGamePlay", withData: [])
                self.resetGameViews()
            }
        })

    }
    
    func handleDwindleDown(respDict:[String:AnyObject]){
        

        let ddDict:[String:AnyObject] = (respDict["DwindleDown"] as? Dictionary<String,AnyObject>)!

        
        for (key, value) in ddDict {
            
            if (key == "DeletedUser"){
                //        1. Delete User
                self.handleDeleteUser(ddDict as [String : AnyObject])
            }
            else if (key == "DwindleCount"){
                let dCount = ddDict["DwindleCount"] as! Int
                print("DwindleCount => \(dCount)")
                
                if (dCount == 4){
                    //ProgressHUD.showSuccess("Congratulations you have found your dwindle match")
                    self.handleFinalDwindleDown()
                }
                else{
                    
                    ProgressHUD.showSuccess("Round \(dCount) Complete! Additional photo unlocked, tap above to view")
                }

            }
            else{
                //        2. Add picture to Remaining Users
                self.handleAddUser(ddDict as [String : AnyObject], key: key)
            }
            
        }

    }

    func getPlayerButtonAgainstId(fbId:String)-> RoundButtonView{
        
        if(btn1.playerId == fbId){
            return btn1
        }
        else if (btn2.playerId == fbId){
            return btn2
        }
        else if (btn3.playerId == fbId){
            return btn3
        }
        else if (btn4.playerId == fbId){
            return btn4
        }
        else
        {
            return btn5
        }
    }
    
    func getPlayerAgainstId(fbId: String) -> Player{

        var playerRequested : Player!
        if var tmpPlayersDict = playersDict{

                for (key, value) in playersDict {
                    let player  = playersDict[key] as? Player
                    if (player?.fbId == fbId){
                        playerRequested = player
                        break
                    }
                }
            }
        else{
            // is nil
        }
        return playerRequested
        
    }
    
    // MARK: - HANDLE UI - DwindleDown
    
    func resetGameViews(){
        
        self.hideKeyboard()
        self.title = "Finding Match"
        ProgressHUD.show("Finding match")

        playersDict.removeAll(keepCapacity: false)
        
        btn1.playerId = ""
        btn2.playerId = ""
        btn3.playerId = ""
        btn4.playerId = ""
        btn5.playerId = ""
        
        btn1.enabled = true
        btn2.enabled = true
        btn3.enabled = true
        btn4.enabled = true
        btn5.enabled = true

        btn1.selected = true
        btn2.selected = true
        btn3.selected = true
        btn4.selected = true
        btn5.selected = true
        
        
        btn1.sd_cancelImageLoadForState(UIControlState.Normal)
        btn2.sd_cancelImageLoadForState(UIControlState.Normal)
        btn3.sd_cancelImageLoadForState(UIControlState.Normal)
        btn4.sd_cancelImageLoadForState(UIControlState.Normal)
        btn5.sd_cancelImageLoadForState(UIControlState.Normal)
        
        btn1.setImage(nil, forState: UIControlState.Normal)
        btn2.setImage(nil, forState: UIControlState.Normal)
        btn3.setImage(nil, forState: UIControlState.Normal)
        btn4.setImage(nil, forState: UIControlState.Normal)
        btn5.setImage(nil, forState: UIControlState.Normal)
        
        self.playerMain = nil
        self.playerOpponent = nil
        self.playerOther1 = nil
        self.playerOther2 = nil
        self.playerOther3 = nil
        self.playerOther4 = nil
        
        self.demoData.clearChat()
        self.collectionView!.reloadData()
        
    }
    
    func randomInt(min: Int, max:Int) -> Int {
        return min + Int(arc4random_uniform(UInt32(max - min + 1)))
    }
    
    func getPlayerIdRandomly() -> String{
        
//        let random = Int(arc4random_uniform(UInt32(randomPlayers.count - i))) + i
        let rIndex = self.randomInt(0, max: randomPlayers.count-1)
        let playerId: String = randomPlayers[rIndex]
        randomPlayers.removeAtIndex(rIndex)
        return playerId
    }
    
    func setPlayerImages(){
        
        playersDict["main"] = self.playerMain
        playersDict["opponent"] = self.playerOpponent
        playersDict["other1"] = self.playerOther1
        playersDict["other2"] = self.playerOther2
        playersDict["other3"] = self.playerOther3
        playersDict["other4"] = self.playerOther4
        
        // Create method that will have all player's id
        // it will then assign 1 id to 1 user 
        // and remove it from list
        
        btn1.playerId = self.getPlayerIdRandomly()
        btn2.playerId = self.getPlayerIdRandomly()
        btn3.playerId = self.getPlayerIdRandomly()
        btn4.playerId = self.getPlayerIdRandomly()
        btn5.playerId = self.getPlayerIdRandomly()
        
        var player = self.getPlayerAgainstId(btn1.playerId)
        btn1.sd_setImageWithURL(player.imgPath, forState:.Normal)
        
        player = self.getPlayerAgainstId(btn2.playerId)
        btn2.sd_setImageWithURL(player.imgPath, forState:.Normal)
        
        player = self.getPlayerAgainstId(btn3.playerId)
        btn3.sd_setImageWithURL(player.imgPath, forState:.Normal)
        
        player = self.getPlayerAgainstId(btn4.playerId)
        btn4.sd_setImageWithURL(player.imgPath, forState:.Normal)
        
        player = self.getPlayerAgainstId(btn5.playerId)
        btn5.sd_setImageWithURL(player.imgPath, forState:.Normal)
        
    }
    
    // MARK: - HANDLE UI - OpenGallery
    func hideKeyboard(){

//        if(self.inputToolbar.contentView.textView.isFirstResponder()){
            self.inputToolbar!.contentView!.textView!.resignFirstResponder()
//        self.hideKeyboardForcefully()
        
//        }
    }
    
    func shouldOpenGallery(sender:AnyObject) -> Bool{
        var button = sender as? RoundButtonView
        
        if let playerId = button?.playerId{
            
            if (playerId == ""){
                return false
            }
        }
        else{
            return false
        }

        return true
    }
    
    @IBAction func openImageGallery(sender: AnyObject) {

        //Close Keyboard
        self.hideKeyboard()

        if(!self.shouldOpenGallery(sender)){
            return
        }
        
        
        var button = sender as? UIButton
        
        print("tagId\(button?.tag)")
        
        if let prevButton = galleryOpenerButton{
            if (prevButton.isEqual(button)){
                print("Same Button")
            }
            else{
                galleryOpenerButton.tag = 0
                galleryOpenerButton = button as? RoundButtonView
                print("Different Button")
            }
        }
        else{
            // cacheId is nil
            
            galleryOpenerButton = button as? RoundButtonView
            print("Setting Button")
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
        
        scroller.reloadDataWithCompleteBlock { () -> Void in
            //code
        }
    }
    
    // MARK: - Utilty Methods
    
    func JSONParseArray(jsonString: String) -> [AnyObject] {
        if let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding) {

            let arrayResp: [AnyObject]!
            do{
                arrayResp = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as! [AnyObject]
                return arrayResp

            }catch let err as NSError {
                print("JSON Error \(err.localizedDescription)")
            }
        }
        return [AnyObject]()
    }

    func JSONParseDictionary(jsonString: String) -> [String: AnyObject] {
        if let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding) {
            
            let dictionary: [String: AnyObject]!
            do{
                dictionary = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))  as! [String: AnyObject]
                return dictionary
            }
            catch let err as NSError{
                print("JSON Error \(err.localizedDescription)")
            }
        }
        return [String: AnyObject]()
    }
    
    // MARK: - SOCKETS & SOCKET SocketIODelegate
    
    func releaseSockets(){
        self.socketIO?.delegate = nil;
        self.socketIO = nil
    }
    
    func initSocketConnection(){
        
        dwindleSocket.EventHandler(true) { (socketClient: SocketIOClient) -> Void in
            
            if socketClient.status == .Connected { // We are save to proceed
                print("Hmmmmmmmm")
                
                socketClient.on("startgame", callback: { (data:[AnyObject], ack:SocketAckEmitter) -> Void in
                    
                })
                
                socketClient.on("getChatLogForPageResult", callback: { (data:[AnyObject], ack:SocketAckEmitter) -> Void in
                    
                })
                
                socketClient.on("updatechat", callback: { (data:[AnyObject], ack:SocketAckEmitter) -> Void in
                    
                })
                
                socketClient.on("disconnect", callback: { (data:[AnyObject], ack:SocketAckEmitter) -> Void in
                    
                })
                
                socketClient.onAny({ (SocketAnyEvent) -> Void in
                    
                })
            }
        }

        
        // create socket.io client instance
        
        self.socketIO = SocketIO(delegate: self)
        
        let properties = [NSHTTPCookieDomain:"159.203.245.103",
                          NSHTTPCookiePath:"/",
                          NSHTTPCookieName:"auth",
                          NSHTTPCookieValue:"56cdea636acdf132"]
        
    

        let cookie:NSHTTPCookie = NSHTTPCookie(properties: properties)!
        let cookies = [cookie]
        
        self.socketIO?.cookies = cookies
        
        self.socketIO?.connectToHost("159.203.245.103", onPort: 3000)
    }
    
    
    func startGame(){
        
        ProgressHUD.show("Starting Game...")
        self.initSocketConnection();
    }
    
    func sendChat(message:String){
        self.socketIO?.sendEvent("sendchat", withData: [message])
        self.sendgamePlayEvent()
    }
    
    func sendgamePlayEvent() {
        let settings = UserSettings.loadUserSettings()
        ProgressHUD.show("Finding match")
        let manager = ServiceManager()
        
        manager.getUserLocation({ (location: CLLocation!) -> Void in
            //code
            print("FBID =>\(settings.fbId) and lon => \(location.coordinate.longitude) and lat => \(location.coordinate.latitude) ")
            
            let data = [settings.fbId,location.coordinate.longitude,location.coordinate.latitude, 0]
            
            self.socketIO?.sendEvent("Play", withData: data)
            
            self.dwindleSocket.sendEvent("Play", data: data as [AnyObject], ack: { (timeoutAfter, callback) -> Void in
                print(callback)
            })
            
            self.isPlayerFound = false
            self.handleNoMatchFound()
            
            }, failure: { (error:NSError!) -> Void in
                //code
                print("Error Message =>\(error.localizedDescription)")
                ProgressHUD.showError("Please turn on your location from Privacy Settings in order to play the game.")
                let delay = 3.5 * Double(NSEC_PER_SEC)
                let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                dispatch_after(time, dispatch_get_main_queue()) {
                    self.navigationController?.popViewControllerAnimated(true)
                }
        })
    }
    
    func socketIODidConnect(socket: SocketIO!) {
        print("socket.io connected.")
        self.sendgamePlayEvent()
    }
    
    func socketIO(socket: SocketIO!, didReceiveMessage packet: SocketIOPacket!) {
        //code
        print("PacketName \(packet.name)")
        
    }
    
    func socketIO(socket: SocketIO!, didReceiveEvent packet: SocketIOPacket!) {
        //code
        print("PacketName \(packet.name)")
        
        if (packet.name == "startgame") {
            
            self.isPlayerFound = true
            
            print("\n startgame data as string looks like \(packet.data)")

            let responseArr:AnyObject =  packet.dataAsJSON()
            let dataStr: String = responseArr[1] as! String
            
            let roomUserInfoDict: AnyObject =  self.JSONParseDictionary(dataStr)
            let roomName:String = (roomUserInfoDict["RoomName"] as? String)!

            self.playerMain      =  Player(dict: roomUserInfoDict["MainUser"]! as? Dictionary)
            self.playerOpponent  = Player(dict: roomUserInfoDict["SecondUser"]! as? Dictionary)

            let secondUserDict: [String: String] = roomUserInfoDict["SecondUser"] as! NSDictionary as! [String : String]
            let name = secondUserDict["user_name"]
            print("second user name\(name)")
            self.title = secondUserDict["user_name"]
            
            var otherData:AnyObject = roomUserInfoDict["OtherUsers"] as! NSArray
            self.playerOther1 = Player(dict: otherData[0]! as? Dictionary)
            self.playerOther2 = Player(dict: otherData[1]! as? Dictionary)
            self.playerOther3 = Player(dict: otherData[2]! as? Dictionary)
            self.playerOther4 = Player(dict: otherData[3]! as? Dictionary)

            randomPlayers.append(self.playerOpponent.fbId)
            randomPlayers.append(self.playerOther1.fbId)
            randomPlayers.append(self.playerOther2.fbId)
            randomPlayers.append(self.playerOther3.fbId)
            randomPlayers.append(self.playerOther4.fbId)
            randomPlayers.shuffled()
            
            ProgressHUD.showSuccess("Game Started. Say Hello!")
            
            self.setPlayerImages()
            
            print("\n RoomName ==>  \(roomName)")
            
            self.socketIO?.sendEvent("addUser", withData: [roomName])
        
        }
        else if (packet.name == "updatechat"){
            print("\n \(packet.name) data as string looks like \(packet.data)")
            
            //["updatechat","A","Hi"]

            let responseArr:AnyObject =  packet.dataAsJSON()
            
            var _senderId:String = ""
            if let tmpSenderId = responseArr[1]  as? String! {
                _senderId = tmpSenderId
            }
            var _message:String = (responseArr[2] as? String)!
           
            if let tmpPlayer = self.playerOpponent{
                if let tmpPlayerId = self.playerOpponent.fbId{
                    if (_senderId == self.playerOpponent.fbId){
                        self.receivedMessagePressed(_senderId, _displayName: "", _message: _message)
                    }
                }
            }
            
        }
        else if (packet.name == "dwindledown"){
            print("\n \(packet.name) data as string looks like \(packet.data)")

            let responseArr:AnyObject =  packet.dataAsJSON()
            let dataStr: String = responseArr[1] as! String
            
            let dwindledownDict: AnyObject =  self.JSONParseDictionary(dataStr)
            self.handleDwindleDown(dwindledownDict as! [String : AnyObject])
            
        }
        else if (packet.name == "useradded"){
            
            print("\n UserAdded data as string looks like \(packet.data)")
        }
        else if (packet.name == "disconnectResponse"){
            
            print("\n disconnectResponse data as string looks like \(packet.data)")
            ProgressHUD.showError("The other user has left the game. Connecting to new users.")
            let delay = 3.5 * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            dispatch_after(time, dispatch_get_main_queue()) {
                self.resetGameViews()
            }
        }
        else if (packet.name == "skip"){
            
            print("\n Skip data as string looks like \(packet.data)")
        }
        else if (packet.name == "skipchat"){
            
            print("\n Skipchat data as string looks like \(packet.data)")
            ProgressHUD.showError("The other user has left the game. Connecting to new users.")
            let delay = 3.5 * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            dispatch_after(time, dispatch_get_main_queue()) {
                self.resetGameViews()
            }

//            self.resetGameViews()
        }
        else if (packet.name == "loggedoutResponse"){
            ProgressHUD.showError("The other user has left the game. Connecting to new users.")
            let delay = 3.5 * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            dispatch_after(time, dispatch_get_main_queue()) {
                self.resetGameViews()
            }
        }

    }
    
    func socketIO(socket: SocketIO!, onError error: NSError!) {
        //
        print("GAMEPLAY CHAT => socket onError with error \(error.localizedDescription)");
        let errorCode = error.code as Int
        if (errorCode == -8) { //SocketIOUnauthorized
            print("not authorized");
        } else {
            print("onError()\(error)");
        }
//        self.releaseSockets()
    }
    
    func socketIODidDisconnect(socket: SocketIO!, disconnectedWithError error: NSError!) {
        //code
        
        print("GAMEPLAY CHAT => socket.io disconnected. did error occur \(error)");
        let state:UIApplicationState  = UIApplication.sharedApplication().applicationState
        if (state == UIApplicationState.Background) {//UIApplicationStateBackground
            print("Application is in background and SIO disconnected.");
        }
        
        if (error.code == 57){
            ProgressHUD.showError("You are disconnected. Please check your internet connection")

            let delay = 3.5 * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            dispatch_after(time, dispatch_get_main_queue()) {
                self.navigationController?.popViewControllerAnimated(true)
            }
        }
        self.releaseSockets()
    }
    
        // MARK: -   VIEW LIFE CYCLE
    func initContentView(){
        // Scroll Initialization
        scroller.autoPlayTimeInterval = 0;
        scroller.continuous = true;
        
        // Message Controller Stuff
        
        let settings = UserSettings.loadUserSettings()
        self.senderId = settings.fbId
        self.senderDisplayName = settings.fbName
        
        self.demoData = DemoModelData()
        
        if (!NSUserDefaults.incomingAvatarSetting()){
            self.collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
        }
        
        if (!NSUserDefaults.outgoingAvatarSetting()) {
            self.collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
        }
        
        self.showLoadEarlierMessagesHeader = false
        self.jsq_configureMessagesViewController();
        self.jsq_registerForNotifications(true);
    
    }
    
    override func viewDidDisappear(animated: Bool) {
        let delay = 1.5 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            ProgressHUD.dismiss()
        }
        super.viewDidDisappear(animated)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        ProgressHUD.dismiss()
        
//        if let socket = self.socketIO where socket.isConnected == true {
//                print("loggedout Called");
//                socket.sendEvent("loggedout", withData:[])
//                self.releaseSockets()
//        }
        
        super.viewWillDisappear(animated)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.collectionView!.collectionViewLayout.springinessEnabled = NSUserDefaults.springinessSetting();
        self.startGame()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.title = "Finding Match"
        self.initContentView()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Skip", style:UIBarButtonItemStyle.Plain , target: self, action: "skipPressed:")

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
    
//    func receivedMessagePressed(sender: UIBarButtonItem) {
    func receivedMessagePressed(_senderId:String, _displayName:String, _message:String) {
        // Simulate reciving message
        showTypingIndicator = !showTypingIndicator
        scrollToBottomAnimated(true)
        var newMessage : JSQMessage ;

        newMessage = JSQMessage(senderId: _senderId, displayName: " ", text: _message)
        JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
        self.demoData.messages.addObject(newMessage)
        self.finishReceivingMessageAnimated(true)
        
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
        
        let message = JSQMessage(senderId: senderId, senderDisplayName: senderDisplayName, date: date, text: text)
        
        self.demoData.messages.addObject(message);
        
        self.finishSendingMessageAnimated(true);
        
        self.sendChat(text)
//        self.handleFinalDwindleDown()

    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        
        
        let sheet = UIActionSheet(title: "Quick messages", delegate:self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles:
            "What actor would best play the role of you?",
            "You can live anyplace in the world, where?",
            "Have you had any success with dating apps?",
            "What's the worst job you've ever had?     ",
            "What movie title describes your sex life?",
            "Drink with anyone throughout history, who?",
            "What about you surprises people the most?",
            "  Do you have any nicknames?                      ",
            "What's the worst part about modern dating?",
            "You're cooking me dinner, what's the menu?");
        
        sheet.showFromToolbar(self.inputToolbar!);
    }
    
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        if (buttonIndex == actionSheet.cancelButtonIndex) {
            return;
        }
        let sampleMessagesArr = ["What actor would best play the role of you?",
                                "You can live anyplace in the world, where?",
                                "Have you had any success with dating apps?",
                                "What's the worst job you've ever had?",
                                "What movie title describes your sex life?",
                                "Drink with anyone throughout history, who?",
                                "What about you surprises people the most?",
                                "Do you have any nicknames?",
                                "What's the worst part about modern dating?",
                                "You're cooking me dinner, what's the menu?"]
        
        let text = sampleMessagesArr[buttonIndex-1]
        
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound();
        
        let message = JSQMessage(senderId: senderId, senderDisplayName: senderDisplayName, date: NSDate(), text: text)
        
        self.demoData.messages.addObject(message);
        
        self.finishSendingMessageAnimated(true);
        
        self.sendChat(text)
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
        
        let message : JSQMessage = self.demoData.messages [indexPath.item] as! JSQMessage
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
        
        //        var message : JSQMessage = self.demoData.messages [indexPath.item] as! JSQMessage
        //        
        //        if (message.senderId == self.senderId) {
        //            if (!NSUserDefaults.outgoingAvatarSetting()) {
        //                return nil;
        //            }
        //        }
        //        else {
        //            if (!NSUserDefaults.incomingAvatarSetting()) {
        //                return nil;
        //            }
        //        }
        
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
            let message : JSQMessage = self.demoData.messages [indexPath.item] as! JSQMessage
            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(message.date)
        }
        
        return nil;
    }
    
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        
        let message : JSQMessage = self.demoData.messages [indexPath.item] as! JSQMessage
        
        /**
        *  iOS7-style sender name labels
        */
        if (message.senderId  == self.senderId) {
            return nil;
        }
        
        if (indexPath.item - 1 > 0) {
            let previousMessage: JSQMessage = self.demoData.messages[indexPath.item - 1]as! JSQMessage;
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
            let message = self.demoData.messages[indexPath.item] as! JSQMessage
            if message.senderId == self.senderId {
                textView.textColor = UIColor.whiteColor()
            } else {
                textView.textColor = UIColor.blackColor()
            }
            
            let attributes = [NSForegroundColorAttributeName:textView.textColor!, NSUnderlineStyleAttributeName: 1]
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
        
        let currentMessage :JSQMessage = self.demoData.messages[indexPath.item] as! JSQMessage;
        
        if (currentMessage.senderId == self.senderId) {
            return 0.0;
        }
        
        if (indexPath.item - 1 > 0) {
            let previousMessage :JSQMessage = self.demoData.messages[indexPath.item - 1] as! JSQMessage;
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
        print("Load earlier messages!");
        
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, atIndexPath indexPath: NSIndexPath!) {
        print("Tapped avatar!");
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAtIndexPath indexPath: NSIndexPath!) {
        print("Tapped message bubble!");
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapCellAtIndexPath indexPath: NSIndexPath!, touchLocation: CGPoint) {
        print("Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
    }
    
    
    
}

