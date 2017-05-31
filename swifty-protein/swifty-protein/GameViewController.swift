//
//  GameViewController.swift
//  swifty-protein
//
//  Created by Antoine JOUANNAIS on 5/26/17.
//  Copyright © 2017 Antoine JOUANNAIS. All rights reserved.
//

import UIKit
import SceneKit
import Foundation

extension String {
    func substring(from: Int?, to: Int?) -> String {
        if let start = from {
            guard start < self.characters.count else {
                return ""
            }
        }
        
        if let end = to {
            guard end >= 0 else {
                return ""
            }
        }
        
        if let start = from, let end = to {
            guard end - start >= 0 else {
                return ""
            }
        }
        
        let startIndex: String.Index
        if let start = from, start >= 0 {
            startIndex = self.index(self.startIndex, offsetBy: start)
        } else {
            startIndex = self.startIndex
        }
        
        let endIndex: String.Index
        if let end = to, end >= 0, end < self.characters.count {
            endIndex = self.index(self.startIndex, offsetBy: end + 1)
        } else {
            endIndex = self.endIndex
        }
        
        return self[startIndex ..< endIndex]
    }
}

class Atom : NSObject {
/*
     Record Format
     
     COLUMNS        DATA  TYPE    FIELD        DEFINITION
     -------------------------------------------------------------------------------------
     1 -  6        Record name   "ATOM  "
     7 - 11        Integer       serial       Atom  serial number.
     13 - 16        Atom          name         Atom name.
     17             Character     altLoc       Alternate location indicator.
     18 - 20        Residue name  resName      Residue name.
     22             Character     chainID      Chain identifier.
     23 - 26        Integer       resSeq       Residue sequence number.
     27             AChar         iCode        Code for insertion of residues.
     31 - 38        Real(8.3)     x            Orthogonal coordinates for X in Angstroms.
     39 - 46        Real(8.3)     y            Orthogonal coordinates for Y in Angstroms.
     47 - 54        Real(8.3)     z            Orthogonal coordinates for Z in Angstroms.
     55 - 60        Real(6.2)     occupancy    Occupancy.
     61 - 66        Real(6.2)     tempFactor   Temperature  factor.
     77 - 78        LString(2)    element      Element symbol, right-justified.
     79 - 80        LString(2)    charge       Charge  on the atom.
*/
    var serial : String
    var name : String
    
    var linkedAtoms : [Atom]?
    init(record : String) {
        // on recupere un "record" complet et on le transforme en objet
        print("init : record = \(record)")
        self.serial = record.substring(from: 6, to: 10)
        self.name = record.substring(from: 12, to: 15)
    }
    
    override var description : String {
        let str = "serial: \(serial), name: \(name)"
        return str
    }
    
}

class GameViewController: UIViewController {
    var scnView: SCNView!
    var scnScene: SCNScene!
    var ligand: String = ""
    var atoms : [Atom] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScene()
        getLigand()
       }
   
    func processLigandFile(_ data : String) {
        print(data)
        let records : [String] = data.components(separatedBy: "\n")
        // je recupere tous les records de type ATOM
        var searchString = "ATOM"
        let atomRecords = records.filter({ (record) -> Bool in
            let recordText: String = record
            return (recordText.range(of: searchString) != nil)
        })
        
        // on remet la liste a zero
        self.atoms = []
        // on charge la liste des atomes
        for atom in atomRecords {
            print("atom : \(atom)")
            self.atoms.append(Atom(record: atom))
        }
        // je recupere tous les records de type CONECT
        searchString = "CONECT"
        let conectRecords = records.filter({ (record) -> Bool in
            let recordText: String = record
            return (recordText.range(of: searchString) != nil)
        })
        for conect in conectRecords {
            print("conect : \(conect)")
            // TODO : modifier les objets de type Atom
        }
        
        // debug
        for atom in self.atoms {
            print(atom)
        }
    }
   
    func getLigand() {
        print("getLigang \(self.ligand)")
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let urlString = "https://files.rcsb.org/ligands/view/\(self.ligand)_model.pdb"
        guard let requestUrl = URL(string:urlString) else {
            print("url is incorrect : \(urlString)")
            return
        }
        let request = URLRequest(url:requestUrl)
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if let err = error {
                // DispatchQueue.main.async
                let errMsg = NSLocalizedString("Network error", comment: "An error message")
                print("\(errMsg) : \(err)")
                let alert = UIAlertController(title: "Error", message: errMsg, preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "Ok", style: .destructive, handler: nil)
                alert.addAction(alertAction)
                
                self.present(alert, animated: true, completion: nil)
            }
            else if let usableData = data {
                let returnData = String(data: usableData, encoding: .utf8)
                if let resp = response as? HTTPURLResponse {
                    print("Status code de la reponse : \(resp.statusCode)")
                }
                self.processLigandFile(returnData!)
            }
        }
        task.resume()
    }
    
    // je veux garder la status bar pour pouvoir afficher la roue d'activité réseau
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    func setupView() {
        scnView = self.view as! SCNView
    }

    func setupScene() {
        scnScene = SCNScene()
        scnView.scene = scnScene
    }
}
