//
//  ViewController.swift
//  PeerToPeerApp
//
//  Created by Corentin Medina on 13/10/2020.
//  Copyright © 2020 Corentin Medina. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, MCSessionDelegate, MCBrowserViewControllerDelegate {
    var sendMsg:String!
    var receivedMsg:String!
    var localPeerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    
    @IBOutlet weak var labelText: UILabel!
    @IBOutlet weak var sendTextBtn: UIButton!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var textView: UITextView!
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected: //Si on a pu se connecter a l'autre appareil
            print("Connecté : \(peerID.displayName)")
            DispatchQueue.main.async {
                self.textView.text = ""
                self.labelText.text = "Connecté à \(peerID.displayName)"
            }
        case .connecting: //Connexion en cours
            print("Connexion en cours : \(peerID.displayName)")
        case .notConnected: //Erreur/perte de connexion
            print("Pas connecté \(peerID.displayName)")
            DispatchQueue.main.async {
                self.labelText.text = "Déconnecté"
                self.textView.text += "\(peerID.displayName) a perdu la connexion"
                
                //Alerte perte de connexion
                let refreshAlert = UIAlertController(title: "Information", message: "La connexion a été perdue", preferredStyle: UIAlertController.Style.alert)
                
                refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default))
                self.present(refreshAlert, animated: true, completion: nil)
            }
        default:
            print("Etat inconnu : \(peerID.displayName)")
        }
        
        //Si il y a un connecté alors on peut écrire
        DispatchQueue.main.async {
            if self.mcSession.connectedPeers.count == 0 {
                self.sendTextBtn.isEnabled = false
                self.textField.isEnabled = false
            }
            else {
                self.sendTextBtn.isEnabled = true
                self.textField.isEnabled = true
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.receivedMsg = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue)! as String
            self.textView.text += self.receivedMsg
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        labelText.text = "PeerToPeerApp"
        localPeerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: .none)
        mcSession.delegate = self
        textField.returnKeyType = UIReturnKeyType.done
        textView.text = nil
        
    }
    //Envoyer un texte
    @IBAction func pressOk(_ sender: Any) {
        if textField.text != "" {
            sendMsg = "\n\(localPeerID.displayName): \(textField.text!)\n" //récupération du nom du telephone
            let message = sendMsg.data(using: String.Encoding.utf8, allowLossyConversion: false)
            
            do
            {
                try self.mcSession.send(message!, toPeers: self.mcSession.connectedPeers, with: .reliable) //envoi du message
            }
            catch
            {
                print("Error sending message")
            }
            textView.text += "\nMe: \(textField.text!)\n"
            textField.text = ""
        }
    }

    @IBAction func buttonAction(_ sender: Any) {
        let action = UIAlertController(title: "Connexion vers un appareil", message: nil, preferredStyle: .alert)
        
        //Bouton créer une session
        action.addAction(UIAlertAction(title: "Créer une session", style: .default) {
            (UIAlertAction) in
            self.mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType:"try", discoveryInfo: nil, session: self.mcSession)
            self.mcAdvertiserAssistant.start()
        })
        
        //Bouton rejoindre une session
        action.addAction(UIAlertAction(title: "Rejoindre une session", style: .default) {
            (UIAlertAction) in
            let mcBrowser = MCBrowserViewController(serviceType: "try", session: self.mcSession)
            mcBrowser.delegate = self
            self.present(mcBrowser, animated: true, completion: nil)
        })
        action.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(action, animated: true)
    }
    
}

