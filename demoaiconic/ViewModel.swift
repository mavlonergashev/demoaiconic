//
//  ViewModel.swift
//  demoaiconic
//
//  Created by Mavlon Ergashev on 26/02/25.
//

import SwiftUI
import CoreML
import StableDiffusion

class ViewModel: ObservableObject {
    @Published var prompt = String()
    @Published var generatedImage: Image?
    @Published var isLoading = false
    
    var generation: GenerationContext = GenerationContext()
    
    func start() async {
        let downloadsPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let modelDirectory = downloadsPath.appendingPathComponent("custommodel")
        guard FileManager.default.fileExists(atPath: modelDirectory.path) else {
            fatalError("not a valid url")
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = true
        }
        
        do {
            let configuration = MLModelConfiguration()
            
            let difPipeLine = try StableDiffusionPipeline(
                resourcesAt: modelDirectory,
                controlNet: [],
                configuration: configuration,
                disableSafety: false,
                reduceMemory: false
            )
            
            try difPipeLine.loadResources()
            
            let pipeline = Pipeline(difPipeLine, maxSeed: UInt32.max)
            generation.pipeline = pipeline
            
            let result = try await generation.generate(prompt: prompt.isEmpty ? nil : prompt)
            
            if let image = result.image {
                DispatchQueue.main.async { [weak self] in
                    self?.generatedImage = Image(decorative: image, scale: 1)
                    self?.isLoading = false
                }
            } else {
                fatalError("No image")
            }
            
        } catch {
            isLoading = false
            fatalError("error in creating StableDiffusionPipeline: \(error)")
        }
    }
    
    private func getModelPath() -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent(Constants.folderName)
    }
    
    private func checkModelExists() -> Bool {
        let modelPath = getModelPath()
        return FileManager.default.fileExists(atPath: modelPath.path)
    }
    
    private func downloadFile() {
        let remoteURL = Constants.remoteModelURL
        let localURL = getModelPath()
        
        let task = URLSession.shared.downloadTask(with: remoteURL) { tempURL, response, error in
            guard let tempURL = tempURL, error == nil else {
                print("Download failed for \(remoteURL): \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            do {
                try FileManager.default.moveItem(at: tempURL, to: localURL)
                print("File saved at: \(localURL.path)")
            } catch {
                print("Error saving file: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
}

enum Constants {
    static let folderName = "CoreMLModel"
    static let remoteModelURL = URL(string: "randomurl.com")!
}
