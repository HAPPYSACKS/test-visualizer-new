//
//  ViewController.swift
//  test-visualizer
//
//  Created by Eric Mao on 2023-09-26.
//

import UIKit
import VisionKit
import Vision


class ViewController: UIViewController {
    
    static let resultsViewIdentifier = "ResultsViewController"

    var scannerAvailable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }
    
    @IBAction func startScan(_ sender: Any) {
        startScanning()
    }
    
    var resultsViewController: (UIViewController & RecognizedTextDataSource)?
    
    func instantiateResultsViewController() {
//        define resultsViewController in the main thread b/c swift complains really badly if it isn't.
        DispatchQueue.main.async {
            self.resultsViewController = self.storyboard?.instantiateViewController(withIdentifier: "ResultsViewController") as? (UIViewController & RecognizedTextDataSource)
        }
    }




    var textRecognitionRequest = VNRecognizeTextRequest()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        instantiateResultsViewController()
        textRecognitionRequest = VNRecognizeTextRequest(completionHandler: { (request, error) in
            guard let resultsViewController = self.resultsViewController else {
                print("resultsViewController is not set")
                return
            }
            if let results = request.results, !results.isEmpty {
                if let requestResults = request.results as? [VNRecognizedTextObservation] {
                    DispatchQueue.main.async {
                        resultsViewController.addRecognizedText(recognizedText: requestResults)
                    }
                }
            }
        })
        // This doesn't require OCR on a live camera feed, select accurate for more accurate results.
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection = true
    }
    


    func startScanning() {
        let documentCameraViewController = VNDocumentCameraViewController()
        documentCameraViewController.delegate = self
        present(documentCameraViewController, animated: true)
    }

    
    func processImage(image: UIImage) {
//      use vision to analyze images
        guard let cgImage = image.cgImage else {
            print("Failed to get cgimage from input image")
            return
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([textRecognitionRequest])
        } catch {
            print(error)
        }
    }
}



extension ViewController: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {

        
        controller.dismiss(animated: true) {
            DispatchQueue.global(qos: .userInitiated).async {
                for pageNumber in 0 ..< scan.pageCount {
                    let image = scan.imageOfPage(at: pageNumber)
                    self.processImage(image: image)
                }
                DispatchQueue.main.async {
                    if let navigationController = self.navigationController {
                        // Check if the resultsViewController is already on the stack
                        if navigationController.viewControllers.contains(where: { $0 is ResultsViewController }) {
                            // It's on the stack, don't push a new one
                            print("ResultsViewController is already on the stack.")
                        } else {
                            // It's not on the stack, push it
                            navigationController.pushViewController(self.resultsViewController!, animated: true)
                            print("Trying to push ResultsViewController")

                        }
                    }
                    
                }
            }
        }
        
    }
}
