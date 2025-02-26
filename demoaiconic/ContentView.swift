//
//  ContentView.swift
//  demoaiconic
//
//  Created by Mavlon Ergashev on 25/02/25.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var vm = ViewModel()
    
    var body: some View {
        VStack {
            TextField("Prompt", text: $vm.prompt)
            
            Button("Generate") {
                Task {
                    await vm.start()
                }
            }
            .disabled(vm.isLoading)
            
            if vm.isLoading {
                ProgressView()
            }
            
            if let image = vm.generatedImage {
                image
                    .resizable()
                    .frame(width: 200, height: 200)
            }
            
        }
        .frame(width: 600, height: 600)
        .padding()
    }
    
}

#Preview {
    ContentView()
}
