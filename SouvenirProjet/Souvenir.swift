//
//  View2Controller.swift
//  SouvenirProjet
//
//  Created by Arnaud Bascop on 14/12/2019.
//  Copyright © 2019 Arnaud Bascop. All rights reserved.
//

import UIKit
import Vision
import CoreML

class Souvenir: UIViewController {
    
    @IBOutlet var resultat: UILabel!
    @IBOutlet var explications: UILabel!
    @IBOutlet var titreSouvenir: UITextField!
    @IBOutlet var imageChoisie: UIImageView!
    // Image sélectionnée, on modifie l'élément imageChoisie selon les cas
    internal var selectedImage: UIImage? {
        get {
            return self.imageChoisie.image
        }
        set {
            switch newValue {
            case nil:
                self.imageChoisie.image = nil
                
            default:
                self.imageChoisie.image = newValue
                detecterImage()
            }
        }
    }
    var imagePickerController: UIImagePickerController?
    
    override func viewDidLoad() {
        explications.lineBreakMode = .byWordWrapping
        explications.numberOfLines = 0
        titreSouvenir.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    @objc func keyboardWillChange(notification: Notification) {
        print("Keyboard will show: \(notification.name.rawValue)")
        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        
        if notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillChangeFrameNotification {
            view.frame.origin.y = -keyboardRect.height
        }
        else {
            view.frame.origin.y = 0
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    
    func detecterImage() {
        resultat.text = "En réflexion..."
        resultat.numberOfLines = 10
        
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else {
                   fatalError("Modèle échoué")
        }
        
        let request = VNCoreMLRequest(model: model) {[weak self] request, error in
            let results = request.results as? [VNClassificationObservation]
            var outputText = ""
            var top5 = 0
            for res in results!{
                if top5 < 5 {
                    top5 = top5+1
                    outputText += "Tag généré : \(self!.genererTag(res.identifier)) \n"
                    outputText += "C'est un  \(res.identifier) à \(Int(res.confidence * 100))%. \n"
                }
            }
            print(outputText)
            // Update the Main UI Thread with our result
            DispatchQueue.main.async { [weak self] in
                self?.resultat.text! = outputText
            }
        }
        
        guard let ciImage = CIImage(image: self.imageChoisie.image!)
        else { fatalError("Problème lors du rendement d'image") }
        
        // Run the classifier
        let handler = VNImageRequestHandler(ciImage: ciImage)
        DispatchQueue.global().async {
            do {
                try handler.perform([request])
            } catch {
                print(error)
            }
        }
    }
    
    func genererTag(_ mot: String) -> String {
        // Correspondance de dictionnaire selon plusieurs tags, algo primitif
        let liste_tags:[String] = ["Naissance", "Décès", "Anniversaire", "Fête", "Enterrement", "Emmenagement", "Vacances", "Concert", "Mariage", "Voyage", "Catastrophe", "Guerre", "Noel", "Nouvelle année", "Saint Valentin", "Parc", "Repas", "Evenement"]
        if mot == "pot, flowerpot" {
            return liste_tags[1] // Décès
        }else if mot == "coral reef" || mot == "fountain" || mot == "cliff, drop, drop-off" || mot == "valley, vale" || mot == "corn" || mot == " ear, spike, capitulum" {
            return liste_tags[6] // Voyage
        }else if mot == "greenhouse, nursery, glasshouse" || mot == "cradle" || mot == "diaper, nappy, napkin" || mot == "crib, cot" || mot == "bath towel" {
            return liste_tags[0] // Naissance
        }else if mot == "lemon" || mot == "orange" || mot == "pomegranate" {
            return liste_tags[liste_tags.count-2]
        }else if mot == "groom, bridegroom" || mot == "suit, suit of clothes" || mot == "bow tie, bow-tie, bowtie" {
            return liste_tags[8] // Mariage
        }else if mot == "stage" || mot == "electric guitar" || mot == "spotlight, spot" || mot == "theater curtain, theatre curtain" {
            return liste_tags[7] // Concert
        }else if mot == "military uniform" {
            return liste_tags[11] // Guerre
        }
        print(mot)
        return mot
    }
    
    // Fonction qui afficher l'alerte et appelle le controller
    @IBAction func selectionnerImage(_ sender: UIButton) {
          if self.imagePickerController != nil {
              self.imagePickerController?.delegate = nil
              self.imagePickerController = nil
          }
          self.imagePickerController = UIImagePickerController.init()
          let alert = UIAlertController.init(title: "Choisir un souvenir", message: nil, preferredStyle: .actionSheet)
          if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
              alert.addAction(UIAlertAction.init(title: "Photos", style: .default, handler: { (_) in
                  self.presentImagePicker(controller: self.imagePickerController!, source: .photoLibrary)
              }))
          }
          alert.addAction(UIAlertAction.init(title: "Annuler", style: .cancel))
          self.present(alert, animated: true)
      }
    // Fonction pour se rendre dans la gallerie
    internal func presentImagePicker(controller: UIImagePickerController , source: UIImagePickerController.SourceType) {
          controller.delegate = self
          controller.sourceType = source
          self.present(controller, animated: true)
    }
    
    
}

extension Souvenir: UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    // Fonction pour sélectionner une photo et revenir avec l'image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return self.imagePickerControllerDidCancel(picker)
        }
        self.selectedImage = image
        picker.dismiss(animated: true) {
            picker.delegate = nil
            self.imagePickerController = nil
        }
    }
    // Fonction qui gère le cas "Annuler"
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            picker.delegate = nil
            self.imagePickerController = nil
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
