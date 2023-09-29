//
//  PhotoViewController.swift
//  test-visualizer
//
//  Created by Eric Mao on 2023-09-27.
//
//TODO
// finish call to stabiltiy API (add json header)
// test call to gpt
// test call to stablediffusion
// check if api keys are there
// put parameters into the api calls
// check if api call body json is right.

import Foundation
import UIKit

let stable_diffusion_api = "https://api.stability.ai/"
let gpt_api = "https://api.openai.com/v1/chat/completions"

class PhotoViewController: UIViewController {
    var receivedHighlightedTexts: String?
    
    func extractPromptSection(from input: String) -> [[String: Any]] {
        // Define regular expression patterns for "text" and "weight" values
        let textPattern = #""text":\s*"(.*?)"\s*,\s*""#
        let weightPattern = #""weight":\s*([0-9]+(?:\.[0-9]+)?)"#
        
        // Create regular expression objects
        guard let textRegex = try? NSRegularExpression(pattern: textPattern, options: []),
              let weightRegex = try? NSRegularExpression(pattern: weightPattern, options: []) else {
            return []
        }
        
        // Extract matches for "text" and "weight" values
        let textMatches = textRegex.matches(in: input, options: [], range: NSRange(location: 0, length: input.count))
        let weightMatches = weightRegex.matches(in: input, options: [], range: NSRange(location: 0, length: input.count))
        
        // Extract strings for each match
        let textResults = textMatches.map { (input as NSString).substring(with: $0.range(at: 1)) }
        let weightResults = weightMatches.map { (input as NSString).substring(with: $0.range(at: 1)) }
        
        // Combine the results using `zip` to ensure safe iteration
        var output: [[String: Any]] = []
        for (text, weightString) in zip(textResults, weightResults) {
            if let weight = Double(weightString) {
                output.append(["text": text, "weight": weight])
            }
        }
        
        return output
    }







    
    func generatePrompt(selectedText: String, completion: @escaping (String?) -> Void) {
        
        guard let urlstring = URL(string: gpt_api) else { return }
        guard let gptKey = Bundle.main.infoDictionary?["GPT_API_KEY"] as? String else {return}
        var request = URLRequest(url: urlstring)
        
        request.httpMethod = "POST"
        
        request.setValue("Bearer \(gptKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant. You can call functions like `fetch_weather` to get weather information."], // CHANGE THIS
                ["role": "user", "content": "\(selectedText)"]
            ]
        ]
        
//        turn requestbody into json
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
//
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }

            if let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        completion(content)
                    } else {
                        completion(nil)
                    }
                } catch {
                    print("Error parsing JSON: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume()
        
        
    }
    
//    Assumes prompt comes in this form:
//    [[text: "sunny", weight: 1.0], [text: "medium", weight: 1.6]]
    func generateImage(prompt: [[String: Any]], completion: @escaping (Data?) -> Void) {
        let engine_id = "stable-diffusion-512-v2-1"
        guard let urlstring = URL(string: stable_diffusion_api + "/v1/generation/" + engine_id + "/text-to-image") else { return }
        guard let stablediffusionKey  = Bundle.main.infoDictionary?["STABILITY_API_KEY"] as? String else {return}
        var request = URLRequest(url: urlstring)
        request.httpMethod = "POST"
        
        request.setValue("application/json)", forHTTPHeaderField: "Content-Type")
        request.setValue("image/png", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(stablediffusionKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody: [String: Any] = [
            "cfg_scale": 7,
            "clip_guidance_preset": "FAST_BLUE",
            "height": 512,
            "width": 512,
            "sampler": "K_DPMPP_2M",
            "samples": 1,
            "steps": 24,
            "text_prompts": prompt
        ]

//        turn requestbody into json
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        
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
    
    override func viewDidAppear(_ animated: Bool) {
        print("The view has appeared!")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("I'm PhotoView!")

        if let text = receivedHighlightedTexts {
            // Use the text, e.g., display it in a label or process it
            print(text)
            
            
            let chatGPTOutput = """
            Based on the provided book scene, I'll extract the essence of it to fit the format you're looking for. Here's a snapshot description before forming the final prompt:

            Character: A scrawny boy in the sixth grade with some physical attributes making him stand out.
            Details: Acne, beginnings of a wispy beard, muscular disease in legs, unique walk, running towards the cafeteria.
            Setting: School environment, possibly near a cafeteria.
            Prompt:

            css
            Copy code
            [["text": "Concept art", "weight": 1],
            ["text": "Digital painting", "weight": 1],
            ["text": "1boy", "weight": 1],
            ["text": "scrawny", "weight": 1],
            ["text": "sixth grade", "weight": 1],
            ["text": "acne", "weight": 1],
            ["text": "wispy beard", "weight": 1],
            ["text": "unique walk", "weight": 1],
            ["text": "running", "weight": 1],
            ["text": "school environment", "weight": 1],
            ["text": "near cafeteria", "weight": 1],
            ["text": "sharp focus", "weight": 1],
            ["text": "cinematic lighting", "weight": 1]]
            
            I've included "Concept art" and "Digital painting" because they fit the illustrative nature of the scene. Additionally, I've added "sharp focus" to emphasize the character and his uniqueness, and "cinematic lighting" to give depth to the environment.
            """

            // Extract the desired section
            let extractedSection = extractPromptSection(from: chatGPTOutput)
            print(extractedSection)

            
//            generatePrompt(selectedText: receivedHighlightedTexts) { promptResult in
//                if let prompt = promptResult {
//                    // Use 'prompt' value here. For example:
//                    print("Received prompt: \(prompt)")
//                    
//                    // You can also call your other function here if needed:
//                    generateImage(prompt: prompt) { imageData in
//                        if let data = imageData, let image = UIImage(data: data) {
//                            DispatchQueue.main.async {
//                                yourImageView.image = image
//                            }
//                        } else {
//                            print("Failed to generate or load the image.")
//                        }
//                    }
//
//                } else {
//                    print("Failed to generate a prompt.")
//                }
//            }


            
        }
    }
}



