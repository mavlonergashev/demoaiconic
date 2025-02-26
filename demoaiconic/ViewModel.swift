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
    
}
