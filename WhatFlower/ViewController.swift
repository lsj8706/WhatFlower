//
//  ViewController.swift
//  WhatFlower
//
//  Created by User on 2021/08/24.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {


    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"

    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        
        #if targetEnvironment(simulator)
        imagePicker.sourceType = .photoLibrary
        #else
        imagePicker.sourceType = .camera
        #endif
        
        imagePicker.allowsEditing = true

    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
            
            //self.imageView.image = userPickedImage
            
            guard let ciimage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert UIImage to CIImage")
            }
            
            detect(image: ciimage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }

    func detect(image: CIImage){
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier(configuration: .init()).model) else {
            fatalError("Loading CoreML Model Failed")
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Model failed to process image.")
            }
            
            if let firstResult = results.first {
                self.navigationItem.title = firstResult.identifier.capitalized
                self.requestInfo(flowerName: firstResult.identifier)
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do{
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func requestInfo(flowerName: String){
        
        let parameters : [String:String] = [
         "format" : "json",
         "action" : "query",
         "prop" : "extracts|pageimages",
         "exintro" : "",
         "explaintext" : "",
         "titles" : flowerName,
         "indexpageids" : "",
         "redirects" : "1",
            "pithumbsize" : "500"
         ]
        
        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { response in
            if response.result.isSuccess{
                print("Got the wikipedia info.")
                print(response)
                
                let flowerJSON: JSON = JSON(response.result.value!)
                
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                
                let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                
                self.label.text = flowerDescription
            }
        }
    }
    
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    
}

