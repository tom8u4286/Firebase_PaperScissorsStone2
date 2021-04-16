//
//  GameViewController.swift
//  Firebase_PaperScissorsStone2
//
//  Created by 曲奕帆 on 2021/4/15.
//

import UIKit
import Firebase

class GameViewController: UIViewController {

    var myDocRef: DocumentReference!
    var opponentDocRef: DocumentReference!
    var quoteListener: ListenerRegistration!
    
    var playerName = ""
    var opponentName = ""
    var opponentGestureBuffer: String? = nil
    let gestureEmoji = ["✌️", "👊", "✋"]
    
    var playerIsInRoom = false
    var gotACK = false
    var gotHello = false
    var gameIsOn = false{
        didSet{
            if gameIsOn{
                statusLabel.text = "對手已連線，請出拳"
                opponentGestureLabel.text = "🤝"
                myGestureLabel.text = nil
                showGestureButtons()
            }else{
                statusLabel.text = "等待對手連線中..."
                gotHello = false
                gotACK = false
                hideGestureButtons()
                newGameButton.isHidden = true
            }
        }
    }
    
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var myGestureLabel: UILabel!
    @IBOutlet weak var opponentGestureLabel: UILabel!
    
    @IBOutlet weak var scissorsButton: UIButton!
    @IBOutlet weak var stoneButton: UIButton!
    @IBOutlet weak var paperButton: UIButton!
    @IBOutlet weak var newGameButton: UIButton!
    
    
    @IBAction func scissorsButton(_ sender: UIButton) {
        print("✌️scissorsButton tapped.")
        outgoGestureHandler("✌️")
        hideGestureButtons()
        
    }
    @IBAction func stoneButton(_ sender: UIButton) {
        print("👊stoneButton tapped.")
        outgoGestureHandler("👊")
        hideGestureButtons()
        
    }
    @IBAction func paperButton(_ sender: UIButton) {
        print("✋paperButton tapped.")
        outgoGestureHandler("✋")
        hideGestureButtons()
    }
    
    func hideGestureButtons(){
        paperButton.isHidden = true
        stoneButton.isHidden = true
        scissorsButton.isHidden = true
    }
    func showGestureButtons(){
        paperButton.isHidden = false
        stoneButton.isHidden = false
        scissorsButton.isHidden = false
    }
    
    
    @IBAction func newGameButton(_ sender: UIButton) {
        print("newGameButton tapped.")
        
        let data = ["message": "new"]
        sendData(data)
        
        myGestureLabel.text = nil
        opponentGestureLabel.text = nil
        opponentGestureBuffer = nil
        
        statusLabel.text = "開始新遊戲，請出拳"
        
        newGameButton.isHidden = true
        showGestureButtons()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("========= Player entered the room. =========")
        print("player: \(playerName), opponent: \(opponentName)")
        playerIsInRoom = true
        newGameButton.isHidden = true
        
        myDocRef = Firestore.firestore().document("game1/\(playerName)")
        opponentDocRef = Firestore.firestore().document("game1/\(opponentName)")
        
        //開始handshake程序
        let data = ["message": "Hello"]
        sendData(data)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "離開遊戲", style: .plain, target: self,action: #selector(backViewBtnFnc))
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        quoteListener = opponentDocRef.addSnapshotListener{ (docSnapshot, error) in
            if self.playerIsInRoom{
                guard let docSnapshot = docSnapshot, docSnapshot.exists else { return }
                let data = docSnapshot.data()
                let incomeData = data?["message"] as? String ?? ""
                
                //如果傳進來的Data是Emoji，且遊戲已經開始gameIsOn，就會被存到opponentGestureBuffer
                //如果傳進來的Data不是Emoji(就會是某個字串)，就會被存到opponentMessage
                print("↓↓↓↓↓↓↓↓↓↓ Message got from \(self.opponentName) ↓↓↓↓↓↓↓↓↓↓")
                print("Message: \(incomeData)")
                if self.gameIsOn{
                    if self.gestureEmoji.contains(incomeData){
                        self.incomeGestureHandler(incomeData)
                    }else{
                        self.otherMessageHandler(incomeData)
                    }
                }else{
                    self.handshake(incomeData)
                }
            }
        }
    }
    
    func sendData(_ data: [String: Any]){
        if playerIsInRoom{
            myDocRef.setData(data){ error in
                if let error = error{
                    print("⚠️ Got an error sending data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    
    func handshake(_ message: String){
        if message == "Hello"{
            print("handshake(): Got Hello. Sending ACK")
            gotHello = true
            let data = ["message": "ACK"]
            sendData(data)
        }
        if message == "ACK"{
            print("handshake(): Got ACK. Sending Hello2")
            gotACK = true
            let data = ["message": "Hello2"]
            sendData(data)
        }
        if message == "Hello2"{
            print("handshake(): Got Hello2.  Check if got Hello before...")
            if gotHello{
                print("Had gotten Hello. Sending ACK2. The game is on!")
                let data = ["message": "ACK2"]
                sendData(data)
                gameIsOn = true
            }else{
                print("Didn't get Hello first. The opponent is not online.")
            }
            
        }
        if message == "ACK2"{
            print("handshake(): Got Ack2. Check if got ACK before...")
            if gotACK{
                print("Had gotten ACK. The game is on!")
                gameIsOn = true
            }else{
                print("Didn't get ACK first. The opponent is not online.")
            }
        }
    }
    
    func incomeGestureHandler(_ gesture:String){
        print("incomeGestureHandler()")
        opponentGestureBuffer = gesture
        if myGestureLabel.text == nil{
            print("對手已出拳")
            statusLabel.text = "對手已出拳"
            opponentGestureLabel.text = "🥱"
        }else{
            print("雙方皆已出拳")
            opponentGestureLabel.text = opponentGestureBuffer
            checkWinningStatus()
            opponentGestureBuffer = nil
            newGameButton.isHidden = false
        }
    }
    
    func otherMessageHandler(_ message: String){
        if message == "new"{
            let data = ["message": "accept"]
            sendData(data)
            
            myGestureLabel.text = nil
            opponentGestureLabel.text = nil
            opponentGestureBuffer = nil
            
            statusLabel.text = "對手邀請新遊戲，請出拳"
            
            newGameButton.isHidden = true
            showGestureButtons()
        }
        if message == "Disconnect"{
            print("handshake(): Got Disconnect. The opponent is not online.")
            gameIsOn = false
            myGestureLabel.text = "🥱"
            opponentGestureBuffer = nil
            opponentGestureLabel.text = "❓"
            hideGestureButtons()
        }
    }
    
    func outgoGestureHandler(_ gesture: String){
        myGestureLabel.text = gesture
        let data = ["message": gesture]
        sendData(data)
        
        if opponentGestureBuffer != nil{
            print("雙方皆已出拳")
            opponentGestureLabel.text = opponentGestureBuffer
            checkWinningStatus()
            opponentGestureBuffer = nil
            newGameButton.isHidden = false

        }else{
            print("等待對手出拳...")
            statusLabel.text = "等待對手出拳..."
            opponentGestureLabel.text = nil
        }
        
        
    }
    
    func checkWinningStatus(){
        if myGestureLabel.text == opponentGestureLabel.text{
            print("checkWinningStatus(): Tie")
            statusLabel.text = "平手！"
        }else{
            if myGestureLabel.text == "✋"{
                print("checkWinningStatus(): myGesture✋")
                if opponentGestureLabel.text == "✌️" {statusLabel.text = "你輸了！"}
                if opponentGestureLabel.text == "👊" {statusLabel.text = "你贏了！"}
            }
            if myGestureLabel.text == "✌️"{
                print("checkWinningStatus(): myGesture✌️")
                if opponentGestureLabel.text == "👊" { statusLabel.text = "你輸了！"}
                if opponentGestureLabel.text == "✋" { statusLabel.text = "你贏了！"}
            }
            if myGestureLabel.text == "👊"{
                print("checkWinningStatus(): myGesture👊")
                if opponentGestureLabel.text == "✋" { statusLabel.text = "你輸了！"}
                if opponentGestureLabel.text == "✌️" { statusLabel.text = "你贏了！"}
            }
        }
        
    }
    
    
    @objc func backViewBtnFnc(){
        self.navigationController?.popViewController(animated: true)
        let data = ["message": "Disconnect"]
        self.sendData(data)
        print("=========Player has leaved the room.==========")
        
        newGameButton.isHidden = true
        
        gameIsOn = false
        playerIsInRoom = false
    }
    
    
}
