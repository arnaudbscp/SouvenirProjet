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

class View2Controller: UIViewController {
    
    @IBOutlet var resultat: UILabel!
    
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
                if top5 < 1 {
                    top5 = top5+1
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
        
        // Run the googlenetplaces classifier
        let handler = VNImageRequestHandler(ciImage: ciImage)
        DispatchQueue.global().async {
            do {
                try handler.perform([request])
            } catch {
                print(error)
            }
        }
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

extension View2Controller: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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
}
