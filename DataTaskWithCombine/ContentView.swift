//
//  ContentView.swift
//  DataTaskWithCombine
//
//  Created by Apex on 15/5/2566 BE.
//

import SwiftUI
import Combine

struct MusicItemResult: Decodable {
    let results: [MusicItem]
}

struct MusicItem: Decodable {
    let trackName: String
    let artistName: String
    
    func toMusicItemModel() -> MusicItemModel {
        MusicItemModel(
            trackName: self.trackName,
            artistName: self.artistName
        )
    }
}

struct MusicItemModel: Identifiable {
    let id: String = UUID().uuidString
    let trackName: String
    let artistName: String
}

class viewModel: ObservableObject {
    @Published var word = ""
    @Published var musicItems: [MusicItemModel] = []
    private var disposedBag = Set<AnyCancellable>()
    
    init() {
        bindToWord()
    }
    
    @inline(__always)
    private func bindToWord() {
        $word
            .removeDuplicates()
            .debounce(for: .milliseconds(1000), scheduler: RunLoop.main)
            .compactMap { enteredText in
                let basePath = "https://itunes.apple.com/search?media=music&entity=song&term="
                let endPoint = basePath + "\(enteredText)"
                return URL(string: endPoint)
            }
            .flatMap(fetchNames)
            .map { $0.results.map{ $0.toMusicItemModel() }}
            .receive(on: DispatchQueue.main)
            .assign(to: \.musicItems, on: self)
            .store(in: &disposedBag)
    }
    
    @inline(__always)
    private func fetchNames(url: URL) -> AnyPublisher<MusicItemResult, Never> {
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: MusicItemResult.self, decoder: JSONDecoder())
            .replaceError(with: MusicItemResult(results: []))
            .eraseToAnyPublisher()
    }
}

struct ContentView: View {
    @ObservedObject var vm = viewModel()
    
    var body: some View {
        VStack() {
            TextField("Enter a word", text: $vm.word)
            createMusicItemView(musicItems: vm.musicItems)
            Spacer()
        }
        .padding()
    }
    
    private func createMusicItemView(musicItems:  [MusicItemModel]) -> some View {
        List(musicItems) { item in
            VStack(alignment: .leading) {
                Text(item.trackName)
                    .font(.system(.headline))
                Text(item.artistName)
                    .font(.system(.subheadline))
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
