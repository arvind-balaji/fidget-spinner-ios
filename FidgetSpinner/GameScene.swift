import SpriteKit
import UIKit
import StoreKit
//import AudioToolbox


class GameScene: SKScene, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    var viewController : UIViewController!
    var startingAngle:CGFloat = 0.0;
    var startingTime:TimeInterval = 0;
    var spinsLeft = 50;
    var startingPoint = CGPoint(x: 0, y: 0)
    var touchIsDown = false;
    let spinsLeftLabel = SKLabelNode(fontNamed: "Helvetica Neue UltraLight")
    let spinTimerLabel = SKLabelNode(fontNamed: "Helvetica Neue UltraLight")
    let restorePurchaseLabel = SKLabelNode(fontNamed: "Helvetica Neue UltraLight")
    let spinnerTexture = SKTexture(imageNamed: "spinner")
    let spinner = SKSpriteNode(imageNamed: "spinner")
    var spinTimerValue: Int = 30 {
        didSet {
            spinTimerLabel.text = "More spins in \(spinTimerValue)s"
        }
    }
    var product_id: String?
    var unlimitedSpinsPurchased = false;
    
    override func didMove(to view: SKView) {
        product_id = "com.company.unlimitedspins"
        
        let defaults = UserDefaults.standard;
        SKPaymentQueue.default().add(self)
        
        //Check if product is purchased
        if (defaults.bool(forKey: "purchased")){
            print("Unlimited Spins")
            unlimitedSpinsPurchased = true;
        }

        if(defaults.object(forKey: "spinsLeft") == nil){
            defaults.set(50, forKey: "spinsLeft");
            spinsLeft = defaults.object(forKey: "spinsLeft") as! Int;
        }else{
            print(defaults.object(forKey: "spinsLeft") as! Int)
            spinsLeft = defaults.object(forKey: "spinsLeft") as! Int;
        }
        
        spinTimerLabel.fontSize = 72;
        spinTimerLabel.fontColor = UIColor(red:0.97, green:0.58, blue:0.12, alpha:1.0)
        spinTimerLabel.text = "More spins in \(spinTimerValue)s"
        spinTimerLabel.position = CGPoint(x: frame.midX, y: frame.midY-450)
        spinTimerLabel.isHidden = true;
        addChild(spinTimerLabel)
        
        spinsLeftLabel.fontSize = 72;
        spinsLeftLabel.fontColor = UIColor(red:0.97, green:0.58, blue:0.12, alpha:1.0)
        print(spinsLeft)
        spinsLeftLabel.position = CGPoint(x: frame.midX, y: frame.midY-450)
        spinsLeftLabel.name = "testLabel";
        addChild(spinsLeftLabel)
        
        restorePurchaseLabel.fontSize = 32;
        restorePurchaseLabel.fontColor = UIColor(red:0.97, green:0.58, blue:0.12, alpha:1.0)
        restorePurchaseLabel.position = CGPoint(x: frame.midX, y: frame.midY-500)
        restorePurchaseLabel.name = "restorePurchaseLabel";
        restorePurchaseLabel.text = "Restore Purchase"

        
        if(unlimitedSpinsPurchased){
            spinsLeftLabel.text = "Unlimited Spins"
            //restorePurchaseLabel.isHidden = true;
        }else{
            spinsLeftLabel.text = "\(spinsLeft) Spins Left"
        }
        
        addChild(restorePurchaseLabel)

        //let spinner = SKSpriteNode(texture: spinnerTexture)
        spinner.name = "spinner"
        spinner.setScale(1.3)
        spinsLeftLabel.position = CGPoint(x: frame.midX, y: frame.midY-450)
        spinner.physicsBody = SKPhysicsBody(texture: spinnerTexture, size: CGSize(width: spinner.size.width, height: spinner.size.height))
        spinner.physicsBody!.angularDamping = 0.1;
        spinner.physicsBody?.pinned = true
        spinner.physicsBody?.affectedByGravity = false;
        addChild(spinner)
        if(spinsLeft < 1){
            spinTimerValue = defaults.object(forKey: "spinTimerValue") as! Int;
            startTimer();
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //touchIsDown = true;
        for touch in touches {
            let location = touch.location(in:self)
            let node = atPoint(location)
            if node.name == "spinner" {
                
                let dx = location.x - node.position.x
                let dy = location.y - node.position.y
                // Store angle and current time
                startingAngle = atan2(dy, dx)
                startingTime = touch.timestamp
                node.physicsBody?.angularVelocity = 0
            } else if node.name == "testLabel"{
                print("About to fetch the product...")
                
                

            }
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches{
            let location = touch.location(in:self)
            let node = atPoint(location)
            if node.name == "spinner" {
                if(spinsLeft < 1 && !unlimitedSpinsPurchased){
                    startTimer();
                    promptPurchase();
                    return;
                }

                if(!touchIsDown && !unlimitedSpinsPurchased){
                    touchIsDown = true;
                    spinsLeft -= 1;
                    UserDefaults.standard.set(self.spinsLeft, forKey: "spinsLeft");
                    print(UserDefaults.standard.object(forKey: "spinsLeft") as! Int)
                    spinsLeftLabel.text = String(spinsLeft) + " Spins Left";

                }

                let dx = location.x - node.position.x
                let dy = location.y - node.position.y
                
                let angle = atan2(dy, dx)
                // Calculate angular velocity; handle wrap at pi/-pi
                var deltaAngle = angle - startingAngle
                if abs(deltaAngle) > CGFloat.pi {
                    if (deltaAngle > 0) {
                        deltaAngle = deltaAngle - CGFloat.pi
                    }
                    else {
                        deltaAngle = deltaAngle + CGFloat.pi 
                    }
                }
                let dt = CGFloat(touch.timestamp - startingTime)
                let velocity = deltaAngle / dt
                
                node.physicsBody?.angularVelocity = velocity * 0.6
                
                // Update angle and time
                startingAngle = angle
                startingTime = touch.timestamp
                
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchIsDown = false;
        startingAngle = 0.0
        startingTime = 0
        for touch in touches{
            let location = touch.location(in:self)
            let node = atPoint(location)
            if node.name == "restorePurchaseLabel"{
                if (SKPaymentQueue.canMakePayments()) {
                    SKPaymentQueue.default().restoreCompletedTransactions()
                }
            }
        }

    }
//    var tmp = 0;
//    override func update(_ currentTime: TimeInterval){
//        let angularVelocity = Double(fabs(spinner.physicsBody?.angularVelocity ?? 0))
//        let angle = Double(fabs(round(100 * (spinner.zRotation)) / 100))
//        //0.00...0.10 ~= angle)
//        print(angularVelocity)
//        print(tmp)
//        if angularVelocity > 0 {
//            if tmp == 0 {
//                vibrate()
//                tmp = 5000 - Int(angularVelocity*20)
//            }else{
//                tmp -= tmp
//            }
//            //vibrate()
//        }
//    }

    //helper functions
    func vibrate() {
        if true {
            //AudioServicesPlaySystemSound(1519);
        }
    }
    func unlockUnlimitedSpins(){
        UserDefaults.standard.set(true , forKey: "purchased")
        unlimitedSpinsPurchased = true;
        spinTimerValue = 0;
        UserDefaults.standard.set(self.spinTimerValue, forKey: "spinTimerValue");
        print("Unlimited Spins")
        spinsLeftLabel.text = "Unlimited Spins"
        spinsLeftLabel.isHidden = false;
        spinTimerLabel.isHidden = true;
        restorePurchaseLabel.isHidden = true;
    }
    func startTimer(){
        spinTimerLabel.isHidden = false;
        spinsLeftLabel.isHidden = true;
        let wait = SKAction.wait(forDuration: 1.0) //change countdown speed here
        let block = SKAction.run({
            [unowned self] in
            
            if self.unlimitedSpinsPurchased{
                self.removeAction(forKey: "countdown")
                self.spinTimerLabel.isHidden = true;
                self.spinsLeftLabel.isHidden = false;

            }
            else if self.spinTimerValue > 0{
                self.spinTimerValue -= 1
                UserDefaults.standard.set(self.spinTimerValue, forKey: "spinTimerValue");
                
            }else{
                self.removeAction(forKey: "countdown")
                self.spinTimerLabel.isHidden = true;
                self.spinsLeftLabel.isHidden = false;
                self.spinsLeft = 50;
                UserDefaults.standard.set(self.spinsLeft, forKey: "spinsLeft");
                
                self.spinTimerValue = 30;
                self.spinsLeftLabel.text = "\(self.spinsLeft) Spins Left"
                
            }
        })
        let sequence = SKAction.sequence([wait,block])
        
        run(SKAction.repeatForever(sequence), withKey: "countdown")
        
    }

    //IAP implemntation and helper functions
    func promptPurchase(){
        let alertController = UIAlertController(title: "Out of Spins", message: "Unlock Unlimited Spins for $0.99?", preferredStyle: UIAlertControllerStyle.alert) //Replace UIAlertControllerStyle.Alert by UIAlertControllerStyle.alert
        let DestructiveAction = UIAlertAction(title: "Later", style: UIAlertActionStyle.cancel) {
            (result : UIAlertAction) -> Void in
            print("Later")
        }
        
        // Replace UIAlertActionStyle.Default by UIAlertActionStyle.default
        let okAction = UIAlertAction(title: "Buy!", style: UIAlertActionStyle.default) {
            (result : UIAlertAction) -> Void in
            print("Buy")
            //let skView = self.view as! SKView;
            self.makePurchase();
        }
        
        alertController.addAction(DestructiveAction)
        alertController.addAction(okAction)
        
        self.view?.window?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
    func makePurchase(){
        // Can make payments
        if (SKPaymentQueue.canMakePayments())
        {
            let productID:NSSet = NSSet(object: self.product_id!);
            let productsRequest:SKProductsRequest = SKProductsRequest(productIdentifiers: productID as! Set<String>);
            productsRequest.delegate = self;
            productsRequest.start();
            print("Fetching Products");
        }else{
            print("Can't make purchases");
        }
    }
    func buyProduct(product: SKProduct){
        print("Sending the Payment Request to Apple");
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment);
        
    }
    func productsRequest (_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        
        let count : Int = response.products.count
        if (count>0) {
            let validProduct: SKProduct = response.products[0] as SKProduct
            if (validProduct.productIdentifier == self.product_id) {
                print(validProduct.localizedTitle)
                print(validProduct.localizedDescription)
                print(validProduct.price)
                buyProduct(product: validProduct);
            } else {
                print(validProduct.productIdentifier)
            }
        } else {
            print("nothing")
        }
    }
    
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Error Fetching product information");
    }
    
    func paymentQueue(_ queue: SKPaymentQueue,
                      updatedTransactions transactions: [SKPaymentTransaction])
        
    {
        print("Received Payment Transaction Response from Apple");
        
        for transaction:AnyObject in transactions {
            if let trans:SKPaymentTransaction = transaction as? SKPaymentTransaction{
                switch trans.transactionState {
                case .purchased:
                    print("Product Purchased");
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    // Handle the purchase
                    unlockUnlimitedSpins();
                    //adView.hidden = true
                    break;
                case .failed:
                    print("Purchased Failed");
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    break;
                    
                    
                    
                case .restored:
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    // Handle the purchase
                    unlockUnlimitedSpins();
                    //adView.hidden = true	
                    break;
                default:
                    break;
                }
            }
        }
        
    }
}
