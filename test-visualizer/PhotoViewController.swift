//
//  PhotoViewController.swift
//  test-visualizer
//
//  Created by Eric Mao on 2023-09-27.
//

import Foundation
import UIKit


class PhotoViewController: UIViewController {
    var receivedHighlightedTexts: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let text = receivedHighlightedTexts {
            // Use the text, e.g., display it in a label or process it
            print(text)
        }
    }
}
