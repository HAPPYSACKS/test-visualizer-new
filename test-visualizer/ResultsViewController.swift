/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller for unstructured text.
*/

import UIKit
import Vision

class ResultsViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    var transcript: String = ""
    var highlightedTexts: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        print(textView ?? "TextView is nil")
        textView?.delegate = self
        textView?.text = transcript
        textView?.isEditable = false
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toPhotoView",
           let destinationVC = segue.destination as? PhotoViewController {
            destinationVC.receivedHighlightedTexts = self.highlightedTexts
        }
    }
    


    @IBAction func generatePressed(_ sender: Any) {
        print("generatePressed called")
    }
    
    

}
// MARK: RecognizedTextDataSource
extension ResultsViewController: RecognizedTextDataSource {
    func addRecognizedText(recognizedText: [VNRecognizedTextObservation]) {
        // Create a full transcript to run analysis on.
        let maximumCandidates = 1
        for observation in recognizedText {
            guard let candidate = observation.topCandidates(maximumCandidates).first else { continue }
            print(candidate.string)
            transcript += candidate.string
            transcript += "\n"
        }
        textView?.text = transcript
        
    }
}

extension ResultsViewController: UITextViewDelegate {
    func textViewDidChangeSelection(_ textView: UITextView) {
        if let selectedRange = textView.selectedTextRange { // textView.selectedTextRange finds hows many characters are highlighted. If no text is highlighted, then it is nil
            let highlightedText = textView.text(in: selectedRange) ?? ""
            print("Highlighted text: \(highlightedText)")
            
            // Store the highlightedText as needed
            highlightedTexts = highlightedText
//
        
        }
    }
}
