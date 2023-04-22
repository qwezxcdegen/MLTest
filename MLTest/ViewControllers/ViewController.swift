//
//  ViewController.swift
//  MLTest
//
//  Created by Степан Фоминцев on 23.04.2023.
//

import UIKit
import Photos
import PhotosUI
import Vision
import CoreML

class ViewController: UIViewController {
    
    private lazy var classificationRequest: VNCoreMLRequest = {
        do {
            // 2
            let model = try VNCoreMLModel(for: MobileNetV2(configuration: MLModelConfiguration()).model)
            // 3
            let request = VNCoreMLRequest(model: model) { request, _ in
                if let classifications =
                    request.results as? [VNClassificationObservation] {
//                    print("Результат классификации: \(classifications)")
                    DispatchQueue.main.async {
                        self.descriptionLabel.text = classifications.prefix(1).map { $0.identifier }[0]
                    }
                }
            }
            // 4
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            // 5
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    private var imageToResearch = UIImage()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func pickPressed() {
        openPHPicker()
    }
    
}

extension ViewController: UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard results.count > 0 else { return }
        results[0].itemProvider.loadObject(ofClass: UIImage.self) { reading, error in
            guard let image = reading as? UIImage, error == nil else { return }
            DispatchQueue.main.async {
                self.imageView.image = image
            }
            self.classifyImage(image)
        }
    }
    
    func openPHPicker() {
        var phPickerConfig = PHPickerConfiguration(photoLibrary: .shared())
        phPickerConfig.selectionLimit = 1
        let phPickerVC = PHPickerViewController(configuration: phPickerConfig)
        phPickerVC.delegate = self
        present(phPickerVC, animated: true)
    }
    
    func classifyImage(_ image: UIImage) {
        // 1
        guard let orientation = CGImagePropertyOrientation(
            rawValue: UInt32(image.imageOrientation.rawValue)) else {
            return
        }
        guard let ciImage = CIImage(image: image) else {
            fatalError("Unable to create \(CIImage.self) from \(image).")
        }
        // 2
        DispatchQueue.global(qos: .userInitiated).async {
            let handler =
            VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
}
