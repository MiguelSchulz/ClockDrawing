/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Makes predictions from images using the MobileNet model.
*/

import Vision
import UIKit

class MNISTImagePredictor {
    
    static func createImageClassifier() -> VNCoreMLModel {
        
        let defaultConfig = MLModelConfiguration()
        let imageClassifierWrapper = try? MNISTClassifier(configuration: defaultConfig)

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

    typealias ImagePredictionHandler = (_ classifiedDigit: ClassifiedDigit) -> Void

    private var predictionHandlers = [VNRequest: ImagePredictionHandler]()

    private var classifiedDigit: ClassifiedDigit!
    private func createImageClassificationRequest() -> VNImageBasedRequest {

        let imageClassificationRequest = VNCoreMLRequest(model: MNISTImagePredictor.imageClassifier, completionHandler: visionRequestHandler)

        imageClassificationRequest.imageCropAndScaleOption = .centerCrop
        return imageClassificationRequest
    }

    func makePredictions(for digit: ClassifiedDigit, completionHandler: @escaping ImagePredictionHandler) throws {
        let orientation = CGImagePropertyOrientation(digit.digitImage.imageOrientation)
        guard let photoImage = digit.digitImage.cgImage else {
            fatalError("Photo doesn't have underlying CGImage.")
        }
        self.classifiedDigit = digit

        let imageClassificationRequest = createImageClassificationRequest()
        predictionHandlers[imageClassificationRequest] = completionHandler

        let handler = VNImageRequestHandler(cgImage: photoImage, orientation: orientation)
        
        let requests: [VNRequest] = [imageClassificationRequest]

      
        try handler.perform(requests)
    }

    private func visionRequestHandler(_ request: VNRequest, error: Error?) {
       
        guard let predictionHandler = predictionHandlers.removeValue(forKey: request) else {
            fatalError("Every request must have a prediction handler.")
        }


        defer {
            predictionHandler(self.classifiedDigit)
        }

        if let error = error {
            print("Vision image classification error...\n\n\(error.localizedDescription)")
            return
        }

        if request.results == nil {
            print("Vision request had no results.")
            return
        }

        guard let observations = request.results as? [VNClassificationObservation] else {
            print("VNRequest produced the wrong result type: \(type(of: request.results)).")
            return
        }

        self.classifiedDigit.predictions = observations.map { observation in
            
            Prediction(classification: observation.identifier,
                       confidencePercentage: Double(observation.confidence))
            
            
        }
    }
}
