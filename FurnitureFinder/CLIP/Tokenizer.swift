//
//  Tokenizer.swift
//  FurnitureFinder
//
//  Created by Daniel Shin on 8/11/25.
//

import Foundation

public struct Tokenizer {

    let merges: [TokenPair : Int]
    let vocabulary: [String: Int]
    let startToken: String = "<|startoftext|>"
    let endToken: String = "<|endoftext|>"
    let padToken: String = "[PAD]"
    let unknownToken: String = "[UNK]"

    var unknownTokenID: Int {
        vocabulary[unknownToken, default: 0]
    }
    
    var padTokenID: Int {
        vocabulary[padToken, default: 0]
    }
    
    public init(merges: [TokenPair: Int], vocabulary: [String: Int]) {
        self.merges = merges
        self.vocabulary = vocabulary
    }

    public init(mergesAt mergesURL: URL, vocabularyAt vocabularyURL: URL) throws {
        self.merges = try Self.readMerges(url: mergesURL)
        self.vocabulary = try! Self.readVocabulary(url: vocabularyURL)
    }

    public func tokenize(input: String, minCount: Int? = nil) -> (tokens: [String], tokenIDs: [Int]) {
        var tokens: [String] = []

        tokens.append(startToken)
        tokens.append(contentsOf: encode(input: input))
        tokens.append(endToken)

        // Pad if there was a min length specified
        if let minLen = minCount, minLen > tokens.count {
            tokens.append(contentsOf: repeatElement(padToken, count: minLen - tokens.count))
        }

        let ids = tokens.map({ vocabulary[$0, default: unknownTokenID] })
        return (tokens: tokens, tokenIDs: ids)
    }

    public func tokenID(for token: String) -> Int? {
        vocabulary[token]
    }
    
    public func token(id: Int) -> String? {
        vocabulary.first(where: { $0.value == id })?.key
    }

    public func decode(tokens: [String]) -> String {
        String(tokens.joined())
            .replacingOccurrences(of: "</w>", with: " ")
            .replacingOccurrences(of: startToken, with: "")
            .replacingOccurrences(of: endToken, with: "")
    }

    func encode(input: String) -> [String] {
        let normalized = input.basicClean()
        let words = normalized.split(separator: " ")
        return words.flatMap({ encode(word: $0) })
    }
    
    func encode(word: Substring) -> [String] {
        var tokens = word.map { String($0) }
        if let last = tokens.indices.last {
            tokens[last] = tokens[last] + "</w>"
        }

        while true {
            let pairs = pairs(for: tokens)
            let canMerge = pairs.filter { merges[$0] != nil }

            if canMerge.isEmpty {
                break
            }

            // If multiple merges are found, use the one with the lowest rank
            let shouldMerge = canMerge.min { merges[$0]! < merges[$1]! }!
            tokens = update(tokens, merging: shouldMerge)
        }
        return tokens
    }

    func pairs(for tokens: [String]) -> Set<TokenPair> {
        guard tokens.count > 1 else {
            return Set()
        }

        var pairs = Set<TokenPair>(minimumCapacity: tokens.count - 1)
        var prev = tokens.first!
        for current in tokens.dropFirst() {
            pairs.insert(TokenPair(prev, current))
            prev = current
        }
        return pairs
    }

    func update(_ tokens: [String], merging bigram: TokenPair) -> [String] {
        guard tokens.count > 1 else {
            return []
        }

        var newTokens = [String]()
        newTokens.reserveCapacity(tokens.count - 1)

        var index = 0
        while index < tokens.count {
            let remainingTokens = tokens[index...]
            if let startMatchIndex = remainingTokens.firstIndex(of: bigram.first) {
                // Found a possible match, append everything before it
                newTokens.append(contentsOf: tokens[index..<startMatchIndex])

                if index < tokens.count - 1 && tokens[startMatchIndex + 1] == bigram.second {
                    // Full match, merge
                    newTokens.append(bigram.first + bigram.second)
                    index = startMatchIndex + 2
                } else {
                    // Only matched the first, no merge
                    newTokens.append(bigram.first)
                    index = startMatchIndex + 1
                }
            } else {
                // Didn't find any more matches, append the rest unmerged
                newTokens.append(contentsOf: remainingTokens)
                break
            }
        }
        return newTokens
    }
}

extension Tokenizer {

    /// A hashable tuple of strings
    public struct TokenPair: Hashable {
        let first: String
        let second: String

        init(_ first: String, _ second: String) {
            self.first = first
            self.second = second
        }
    }
}

extension Tokenizer {
    enum FileReadError: Error {
        case invalidMergeFileLine(Int)
    }

    /// Read vocab.json file at URL into a dictionary mapping a String to its Int token id
    static func readVocabulary(url: URL) throws -> [String: Int] {
        let content = try Data(contentsOf: url)
        return try JSONDecoder().decode([String: Int].self, from: content)
    }

    /// Read merges.txt file at URL into a dictionary mapping bigrams to the line number/rank/priority
    static func readMerges(url: URL) throws -> [TokenPair: Int] {
        let content = try String(contentsOf: url)
        let lines = content.split(separator: "\n")

        let merges: [(TokenPair, Int)] = try lines.enumerated().compactMap { (index, line) in
            if line.hasPrefix("#") {
                return nil
            }
            let pair = line.split(separator: " ")
            if pair.count != 2 {
                throw FileReadError.invalidMergeFileLine(index+1)
            }
            return (TokenPair(String(pair[0]), String(pair[1])),index)
        }
        return [TokenPair : Int](uniqueKeysWithValues: merges)
    }
}


extension String {
    func basicClean() -> String {
        let cleaned = self.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()  // Python example used `.lower()`
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned
    }
}
