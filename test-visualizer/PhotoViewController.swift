//
//  PhotoViewController.swift
//  test-visualizer
//
//  Created by Eric Mao on 2023-09-27.
//
//TODO
// finish call to stabiltiy API (add json header)
// start working on call to chatgpt.

import Foundation
import UIKit

struct gptResponse {
    
}

struct stablediffusionResponse {
    
}

let stable_diffusion_api = "https://api.stability.ai/"

class PhotoViewController: UIViewController {
    var receivedHighlightedTexts: String?
    
    func generateImage() {
        let engine_id = "stable-diffusion-512-v2-1"
        guard let urlstring = URL(string: stable_diffusion_api + "/v1/generation/" + engine_id + "/text-to-image") else { return }
        guard let stablediffusionKey  = Bundle.main.infoDictionary?["STABILITY_API_KEY"] as? String else {return}
        var request = URLRequest(url: urlstring)
        request.httpMethod = "POST"
        
        request.setValue("application/json)", forHTTPHeaderField: "Content-Type")
        request.setValue("image/png", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(stablediffusionKey)", forHTTPHeaderField: "Authorization")
        
        
//            make request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print("Error fetching data: \(String(describing: error))")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    // Successful request
                    do {
                        if let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] {
                            // Handle your JSON here
                            print(jsonResponse)
                        }
                    } catch {
                        print("Error parsing JSON: \(error)")
                    }
                case 401:
                    print("Unauthorized. Check if your API key is valid.")
                case 500:
                    print("Server error. Something went wrong on the server's side.")
                default:
                    print("Received HTTP \(httpResponse.statusCode): \(String(describing: String(data: data!, encoding: .utf8)))")
                }
            }
        }


        task.resume()

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let text = receivedHighlightedTexts {
            // Use the text, e.g., display it in a label or process it
            print(text)


            
        }
    }
}
