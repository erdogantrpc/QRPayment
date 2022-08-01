//
//  CashierViewModel.swift
//  QRPayment
//
//  Created by Erdoğan Turpcu on 31.07.2022.
//

import Foundation
import Combine
import FirebaseFirestore
import AVFoundation
import FirebaseAnalytics

class CashierViewModel: NSObject {

    private struct Constant {
        static let pickerSectionCount = 1
        static let qrCodeKey = "QRCode"
        static let statusKey = "status"
        static let checkQRKey = "QRP"
        static let firebaseEventMessage = "QR kod okundu"
        static let firebaseEventKey = "Okuma"
    }

    // MARK: Published variable
    @Published var hasError = false
    @Published var openPicker = false

    // MARK: Private variable
    private var paymentStatus:  PaymentStatus = .continues
    private let database = Firestore.firestore()
    private var captureSession = AVCaptureSession()
    private var previewLayer = AVCaptureVideoPreviewLayer()
    private let pickerView = ToolbarPickerView()
    private var qrCode: String = ""
    

    // MARK: Private func
    private func pushFirebase() {
        if let statusStore = [Constant.statusKey : paymentStatus.id] as? [String : Any] {
            database.collection(Constant.qrCodeKey).document(qrCode).setData(statusStore, merge: true)
        }
    }

    private func setupPreviewView() -> AVCaptureVideoPreviewLayer? {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return nil }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return nil
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            hasError = true
            return nil
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            hasError = true
            return nil
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)

        return previewLayer
    }

    private func setupPickerView() {
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.toolbarDelegate = self
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.backgroundColor = .white
    }

    // MARK: Public func
    func setupUI() -> AVCaptureVideoPreviewLayer? {
        setupPickerView()
        captureSession.startRunning()
        return setupPreviewView()
    }

    func showPicker() -> ToolbarPickerView? {
        return pickerView
    }
    
    func reActivedCapture() {
        if !captureSession.isRunning {
            openPicker = false
            captureSession.startRunning()
        }
    }
    
}

// MARK: Nested extension
extension CashierViewModel {
    enum PaymentStatus: CaseIterable, CustomStringConvertible {
        case succeed
        case unsucceed
        case continues

        var id: Int {
            switch self {
            case .succeed:
                return 1
            case .unsucceed:
                return -1
            case .continues:
                return 2
            }
        }
        
        var description: String {
            switch self {
            case .succeed:
                return "Başarılı"
            case .unsucceed:
                return "Başarısız"
            case .continues:
                return "Devam Ediyor"
            }
        }

        func getStatus(with value: String) -> PaymentStatus {
            switch value {
            case "Başarılı":
                return .succeed
            case "Başarısız":
                return .unsucceed
            case "Devam Ediyor":
                return .continues
            default:
                return .continues
            }
        }
    }
}

// MARK: UIPicker extensions
extension CashierViewModel: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return Constant.pickerSectionCount
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        PaymentStatus.allCases.count
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        paymentStatus = paymentStatus.getStatus(with: PaymentStatus.allCases[row].description)
        //pushFirebase()
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return PaymentStatus.allCases[row].description
    }
}

// MARK: AVCaptureMetadataOutputObjects extensions
extension CashierViewModel: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            qrCode = stringValue
            if qrCode.contains(Constant.checkQRKey) {
                openPicker = true
                Analytics.logEvent(AnalyticsEventShare,
                                   parameters: [Constant.firebaseEventKey :Constant.firebaseEventMessage])
            } else {
                hasError = true
            }
        }
    }
}

// MARK: ToolbarPickerView extensions
extension CashierViewModel: ToolbarPickerViewDelegate {
    func didTapDone() {
        pushFirebase()
        reActivedCapture()
    }
    
    func didTapCancel() {
        reActivedCapture()
    }
}
