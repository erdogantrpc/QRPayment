//
//  CustomerViewController.swift
//  QRPayment
//
//  Created by Erdoğan Turpcu on 30.07.2022.
//

import UIKit
import Combine

class CustomerViewController: UIViewController {
    
    struct Constants {
        static let statusInfo = "Ödeme Durumu: %@"
    }

    // MARK: @IBOutlet variables
    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!

    // MARK: Private variables
    private let viewModel = CustomerViewModel()
    private var cancelable = Set<AnyCancellable>()

    // MARK: Override methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPage()
    }

    // MARK: Private functions
    private func setupPage() {
        /// Subscribe qr status
        viewModel.$status.sink { [weak self] status in
            guard let self = self else { return }
            self.statusLabel.text = String(format: Constants.statusInfo, status.description)
            self.statusLabel.backgroundColor = status.backgorundColor
        }.store(in: &cancelable)

        /// Subscribe qr image
        viewModel.$qrImage.sink { [weak self] qrImage in
            guard let self = self else { return }
            self.qrImageView.image = qrImage
        }.store(in: &cancelable)

        /// Generate qr
        viewModel.generateQr()
        
        /// Read payment status
        viewModel.readDataFromFirebase()
    }
}
