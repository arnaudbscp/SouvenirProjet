//
//  ViewController.swift
//  SouvenirProjet
//
//  Created by Arnaud Bascop on 14/12/2019.
//  Copyright © 2019 Arnaud Bascop. All rights reserved.
//

import UIKit

class Accueil: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    var imagePicker: UIImagePickerController?
    
    @IBOutlet var selectionnerImage: UIButton!
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

