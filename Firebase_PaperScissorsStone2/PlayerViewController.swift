//
//  ViewController.swift
//  Firebase_PaperScissorsStone2
//
//  Created by 曲奕帆 on 2021/4/15.
//

import UIKit

class PlayerViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AliceEnterGame" {
            let controller = segue.destination as! GameViewController
            controller.playerName = "Alice"
            controller.opponentName = "Bob"
            
        }
        if segue.identifier == "BobEnterGame" {
            let controller = segue.destination as! GameViewController
            controller.playerName = "Bob"
            controller.opponentName = "Alice"
            
        }
    }
}
