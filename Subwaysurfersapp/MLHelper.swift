import CoreML

func featuresToMultiArray(_ features: [[Double]]) -> MLMultiArray? {
    guard let array = try? MLMultiArray(shape: [60, 3, 1], dataType: .float32) else { return nil }

    for i in 0..<60 {
        array[[i as NSNumber, 0, 0]] = NSNumber(value: features[i][0])
        array[[i as NSNumber, 1, 0]] = NSNumber(value: features[i][1])
        array[[i as NSNumber, 2, 0]] = NSNumber(value: features[i][2])
    }
    return array
}

func predictJumpingJacks(from multiArray: MLMultiArray) -> String {
    do {
        let model = try Jumpingjacks(configuration: MLModelConfiguration())
        let modelInput = JumpingjacksInput(poses: multiArray)
        let prediction = try model.prediction(input: modelInput)
        return prediction.label
    } catch {
        print("Prediction error:", error)
        return "Error"
    }
}
