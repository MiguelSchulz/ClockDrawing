/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Makes predictions from images using the MobileNet model.
*/

import Vision
import UIKit

class WatchImagePredictor {
    
    static func createImageClassifier() -> VNCoreMLModel {
        
        let defaultConfig = MLModelConfiguration()
        let imageClassifierWrapper = try? own_time(configuration: defaultConfig)

        guard let imageClassifier = imageClassifierWrapper else {
            fatalError("App failed to create an image classifier model instance.")
        }

        let imageClassifierModel = imageClassifier.model

        guard let imageClassifierVisionModel = try? VNCoreMLModel(for: imageClassifierModel) else {
            fatalError("App failed to create a `VNCoreMLModel` instance.")
        }

        return imageClassifierVisionModel
    }

    private static let imageClassifier = createImageClassifier()

    var watchPredictionHandler: (_ hour: Int, _ minute: Int) -> Void = { _,_ in }

    private func createImageClassificationRequest() -> VNImageBasedRequest {

        let imageClassificationRequest = VNCoreMLRequest(model: WatchImagePredictor.imageClassifier, completionHandler: visionRequestHandler)

        imageClassificationRequest.imageCropAndScaleOption = .centerCrop
        return imageClassificationRequest
    }

    func makePredictions(image: UIImage, completionHandler: @escaping (_ hour: Int, _ minute: Int) -> Void) throws {
        let newImage = image//.resizeImageTo(size: CGSize(width: 100, height: 100))!
        let orientation = CGImagePropertyOrientation(newImage.imageOrientation)
        guard let photoImage = newImage.cgImage else {
            fatalError("Photo doesn't have underlying CGImage.")
        }
        //UIImageWriteToSavedPhotosAlbum(newImage, nil, nil, nil)
        let imageClassificationRequest = createImageClassificationRequest()
        watchPredictionHandler = completionHandler

        let handler = VNImageRequestHandler(cgImage: photoImage, orientation: orientation)
        
        let requests: [VNRequest] = [imageClassificationRequest]

      
        try handler.perform(requests)
    }

    private func visionRequestHandler(_ request: VNRequest, error: Error?) {

        if let error = error {
            print("Vision image classification error...\n\n\(error.localizedDescription)")
            return
        }

        if request.results == nil {
            print("Vision request had no results.")
            return
        }
        guard let observations = request.results as? [VNCoreMLFeatureValueObservation] else {
            print("VNRequest produced the wrong result type: \(type(of: request.results)).")
            return
        }
        var minute = 0
        var hour = 0
        for observation in observations {
            if observation.featureName == "minute" {
                /*if let multiArray = observation.featureValue.multiArrayValue {
                    minute = Int(multiArray[0] as! Double)
                    
                }*/
                if let multiArray = observation.featureValue.multiArrayValue {
                    var confidences: [Double] = []
                    for i in 0..<multiArray.count {
                        confidences.append(multiArray[i] as! Double)
                    }
                    if let maxConfidence = confidences.max() {
                        if let maxIndice = confidences.firstIndex(where: {$0 == maxConfidence}) {
                            minute = maxIndice*5
                        }
                        
                    }
                }
            } else if observation.featureName == "hour" {
                if let multiArray = observation.featureValue.multiArrayValue {
                    var confidences: [Double] = []
                    for i in 0..<multiArray.count {
                        confidences.append(multiArray[i] as! Double)
                    }
                    if let maxConfidence = confidences.max() {
                        if let maxIndice = confidences.firstIndex(where: {$0 == maxConfidence}) {
                            if maxIndice == 0 {
                                hour = 12
                            } else {
                                hour = maxIndice
                            }
                        }
                        
                    }
                }
            }
            // TODO: SAVE CONFIDENCES IN MODEL
        }
        
        self.watchPredictionHandler(hour, minute)
        
    }
}
