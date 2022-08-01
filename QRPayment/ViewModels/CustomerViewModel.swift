//
//  CustomerViewModel.swift
//  QRPayment
//
//  Created by Erdoğan Turpcu on 2022-07-30.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAnalytics

class CustomerViewModel {

    struct Constant {
        static let ciFilterName = "CIQRCodeGenerator"
        static let filterKey = "inputMessage"
        static let statusKey = "status"
        static let qrCodeGenetareString = "QRCode/%@"
        static let qrGenerateError = "QR kod oluşturulurken bir hata oluştu"
        static let firebaseReadError = "Veri okunurken bir hata oluştu"
        static let firebaseEventMessage = "QR Kod oluşturuldu"
        static let firebaseEventKey = "Oluşturma"
    }

    // MARK: Published variable
    @Published var status: QrStatus = .waiting
    @Published var qrImage: UIImage?

    // MARK: Private variable
    private let database = Firestore.firestore()
    private let id = "QRP-\(UUID().uuidString)"

    // MARK: Private func
    private func pushFirebase() {
        let documentRef = database.document(String(format: Constant.qrCodeGenetareString, id))
        documentRef.setData([Constant.statusKey: status.id])
    }

    // MARK: Public func
    /**
     Generate qr kod with unique id and push generated qr to firebase
     */
    func generateQr() {
        let idData = id.data(using: String.Encoding.ascii)

        guard let filter = CIFilter(name: Constant.ciFilterName)
        else {
            status = .error(message: Constant.qrGenerateError)
            return
        }
        filter.setValue(idData, forKey: Constant.filterKey)
        let transform = CGAffineTransform(scaleX: 7, y: 7)
        guard let output = filter.outputImage?.transformed(by: transform)
        else {
            status = .error(message: Constant.qrGenerateError)
            return
        }
        qrImage = UIImage(ciImage: output)
        pushFirebase()
        Analytics.logEvent(AnalyticsEventShare,
                           parameters: [Constant.firebaseEventKey :Constant.firebaseEventMessage])
    }
    
    /**
     Read payment status from firebase and update status variable
     */
    func readDataFromFirebase() {
        let documentRef = database.document(String(format: Constant.qrCodeGenetareString, id))
        
        documentRef.addSnapshotListener { [weak self] snapshot, error in
            guard let data = snapshot?.data(), error == nil, let self = self else {
                return
            }
            
            guard let paymentStatus = data["status"] as? Int else {
                self.status = .error(message: Constant.firebaseReadError)
                return
            }
            
            DispatchQueue.main.async {
                self.status = self.status.getStatus(with: paymentStatus)
            }
        }
    }
}

// MARK: Nested extension
extension CustomerViewModel {
    enum QrStatus: CustomStringConvertible {
        case waiting
        case succeed
        case unsucceed
        case continues
        case error(message: String)
        
        var id: Int {
            switch self {
            case .waiting:
                return 0
            case .succeed:
                return 1
            case .unsucceed:
                return -1
            case .continues:
                return 2
            default:
                return -1
            }
        }
        
        var description: String {
            switch self {
            case .waiting:
                return ""
            case .succeed:
                return "Başarılı"
            case .unsucceed:
                return "Başarısız"
            case .continues:
                return "Devam Ediyor"
            case .error:
                return "Qr generate edilirken hata"
            }
        }
        
        var backgorundColor: UIColor {
            switch self {
            case .waiting:
                return .white
            case .succeed:
                return .green
            case .unsucceed:
                return .red
            case .continues:
                return .yellow
            case .error:
                return .white
            }
        }
        
        func getStatus(with value: Int) -> QrStatus {
            switch value {
            case -1:
                return .unsucceed
            case 0:
                return .waiting
            case 1:
                return .succeed
            case 2:
                return .continues
            default:
                return .waiting
            }
        }
    }
}
