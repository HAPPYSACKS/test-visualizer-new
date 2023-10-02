//
//  PhotoViewController.swift
//  test-visualizer
//
//  Created by Eric Mao on 2023-09-27.
//
//TODO
// test call to gpt
// test call to stablediffusion


import Foundation
import UIKit

let stable_diffusion_api = "https://api.stability.ai/"
let gpt_api = "https://api.openai.com/v1/chat/completions"

class PhotoViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    
    
    
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
                ["role": "system", "content": gptContext], // CHANGE THIS
                ["role": "user", "content": "\(selectedText)"]
            ]
        ]
        
//        turn requestbody into json
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
//      print out contents of request
        print("request:\(request)")
        print("request method: \(String(describing: request.httpMethod))")
        if let httpBody = request.httpBody, let bodyString = String(data: httpBody, encoding: .utf8) {
            print("Request Body: \(bodyString)")
        } else {
            print("No request body or failed to convert body to string.")
        }
        
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
            } else {
                print("no chatgpt data")
            }
        }
        
        task.resume()
        
        
    }
    
//    Assumes prompt comes in this form:
//    [[text: "sunny", weight: 1.0], [text: "medium", weight: 1.6]]
    func generateImage(prompt: String?, completion: @escaping (Data?) -> Void) {
        let engine_id = "stable-diffusion-512-v2-1"
        guard let urlstring = URL(string: stable_diffusion_api + "v1/generation/" + engine_id + "/text-to-image") else { return }
        guard let stablediffusionKey  = Bundle.main.infoDictionary?["STABILITY_API_KEY"] as? String else {return}
        var request = URLRequest(url: urlstring)
        request.httpMethod = "POST"
        
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("image/png", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(stablediffusionKey)", forHTTPHeaderField: "Authorization")
        
        let formatted_prompt = extractPromptSection(from: prompt ?? "")
        

        
        let requestBody: [String: Any] = [
            "cfg_scale": 7,
            "clip_guidance_preset": "FAST_BLUE",
            "height": 512,
            "width": 512,
            "sampler": "K_DPM_2_ANCESTRAL",
            "samples": 1,
            "steps": 50,
            "text_prompts": formatted_prompt,
            "style_preset": "fantasy-art"
        ]

//        turn requestbody into json
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
//        print out contents of request
        
        print("request:\(request)")
        print("request method: \(String(describing: request.httpMethod))")
        if let httpBody = request.httpBody, let bodyString = String(data: httpBody, encoding: .utf8) {
            print("Request Body: \(bodyString)")
        } else {
            print("No request body or failed to convert body to string.")
        }
        
        
//            make request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print("Error fetching data in SD API: \(String(describing: error))")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    // Successful request, directly pass the image data to the completion handler
                     completion(data)
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
        print("I'm PhotoView!")

        if let text = receivedHighlightedTexts {
            // Use the text, e.g., display it in a label or process it
            print("recieved text: \(text)")

            


            generatePrompt(selectedText: receivedHighlightedTexts!) { promptResult in
                if let prompt = promptResult {
                    // Use 'prompt' value here. For example:
                    print("Received prompt: \(prompt)")
                    
                    // You can also call your other function here if needed:
                    self.generateImage(prompt: prompt) { imageData in
                        if let data = imageData, let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                self.imageView.image = image
                            }
                        } else {
                            print("Failed to generate or load the image.")
                        }
                    }

                } else {
                    print("Failed to generate a prompt.")
                }
            }


            
        }
    }
    let gptContext = """
I need you to create a prompt for AI art generation. Here is a guide on how to create a prompt:
    
keyword:
\"Portrait drawings that are very realistic. Good to use with people
Digital painting: Digital art style
Concept art: Illustration style, 2D
Ultra realistic: illustration drawing that are very realistic. Good to use with people
Underwater portrait: Use with people. Underwater. Hair floating
Underwater steampunk: underwater with wash color\"

These keywords further refine the art style.
keyword: Note
hyperrealistic: Increases details and resolution
pop-art: Pop-art style
Modernist: vibrant color, high contrast
art nouveau: Add ornaments and details, building style\"

artstation: Modern illustration, fantasy\"

\"Resolution
keyword    Note
unreal engine: Very realistic and detailed 3D
sharp focus: Increase resolution
8k:    Increase resolution, though can lead to it looking more fake.
vray: 3D rendering best for objects, landscape and building.\"

\"Lighting
keyword    Note
rim lighting: light on edge of an object
cinematic lighting: A generic term to improve contrast by using light
crepuscular rays: sunlight breaking through the cloud"

\"Additional details

Add specific details to your image.
keyword    Note
dramatic: shot from a low angle
silk: Add silk to clothing
expansive: More open background, smaller subject
low angle shot: shot from low angle
god rays: sunlight breaking through the cloud
psychedelic: vivid color with distorti

\"Color

Add an additional color scheme to the image.
keyword    Note
iridescent gold    : shinny gold
silver: silver color
vintage: vintage effect"



I want you to return only the prompt in this format :

\"
[\"text\": \"Attribute 1\", \"weight\": 1], [\"text\": \"Attribute 2\", \"weight\": 1], [\"text\": \"Attribute 3\", \"weight\": 1]...
\"



I will give a scene in a book. Turn this scene in a book into a prompt.
"""
}



