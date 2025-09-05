//
//  SegmentAnythingAPI.swift
//  FurnitureFinder
//
//  Created by Daniel Shin on 7/25/25.
//

import Foundation
import PhotosUI
import FirebaseAuth

private struct _SegmentAnythingAPIResponse: Decodable {
    let results: [_SegmentAnythingResult]
}

enum SegmentAnythingError: Error {
    case AuthenticationError
    case TokenRetrievalError
}

func sendToSegmentAnythingAPI(
    cropImage: UIImage,
    boxArray: [[CGFloat]],
) async throws -> [UIImage?] {
    guard let url = URL(string: "http://localhost:8080/api/v1/sam2/segment") else {
        return []
    }
    /*
    let user = try await withCheckedThrowingContinuation { cont in
        Auth.auth().signInAnonymously { result, error in
            if let user = result?.user {
                cont.resume(returning: user)
            } else {
                print("Auth Error")
                cont.resume(throwing: SegmentAnythingError.AuthenticationError)
            }
            
        }
    }
    
    let token = try await withCheckedThrowingContinuation { cont in
            user.getIDToken { token, error in
                if let token = token {
                    cont.resume(returning: token)
                } else {
                    print("Token Error")
                    cont.resume(throwing: SegmentAnythingError.TokenRetrievalError)
                }
            }
    }*/
            
    var request = URLRequest(url: url)
    let boundary = "Boundary-\(UUID().uuidString)"
    let crlf = "\r\n"
            
    request.httpMethod = "POST"
    //request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
    var body = Data()
    if let jpeg = cropImage.jpegData(compressionQuality: 0.8) {
        body.append("--\(boundary)\(crlf)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"crop.jpg\"\(crlf)".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\(crlf)\(crlf)".data(using: .utf8)!)
        body.append(jpeg)
        body.append(crlf.data(using: .utf8)!)
    }
            
    if let boxData = try? JSONSerialization.data(withJSONObject: boxArray),
       let boxString = String(data: boxData, encoding: .utf8) {
        body.append("--\(boundary)\(crlf)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"boxes\"\(crlf)\(crlf)".data(using: .utf8)!)
        body.append(boxString.data(using: .utf8)!)
        body.append(crlf.data(using: .utf8)!)
    }
    
    body.append("--\(boundary)--\(crlf)".data(using: .utf8)!)
    request.httpBody = body
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let response = try JSONDecoder().decode(_SegmentAnythingAPIResponse.self, from: data)
    return response.results.compactMap { res -> UIImage? in
        guard res.box.count == 4,
              let maskData = Data(base64Encoded: res.mask),
              let maskImg = UIImage(data: maskData)
        else { return nil }
                
        return maskImg
    }
}

func fetchMask(cropImage: UIImage, boxArray: [[CGFloat]]) async -> [UIImage?]? {
    guard let masks = try? await sendToSegmentAnythingAPI(cropImage: cropImage, boxArray: boxArray)
    else { return nil }
    return masks
    
}
