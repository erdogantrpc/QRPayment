//
//  CashierViewController.swift
//  QRPayment
//
//  Created by Erdoğan Turpcu on 31.07.2022.
//

import UIKit
import AVFoundation
import FirebaseFirestore
import Combine

class CashierViewController: UIViewController {

    struct Constant {
        static let errorTitle = "Scanning Error"
        static let errorMessage = "Error during scan"
        static let errorButton = "OK"
    }

    // MARK: @IBOutlet variables
    @IBOutlet weak var captureView: UIView!
    @IBOutlet weak var squareImageView: UIImageView!

    @IBOutlet weak var pickerTextField: UITextField!

    // MARK: Private variables
    private let viewModel: CashierViewModel = CashierViewModel()
    private var cancelable = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPage()
    }

    // MARK: Private functions
    private func setupPage() {
        // Sink to hasError
        viewModel.$hasError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasError in
                guard let self = self else { return }
                if hasError {
                    self.failed()
                }
            }.store(in: &cancelable)

        // Sink to openPicker
        viewModel.$openPicker
            .receive(on: DispatchQueue.main)
            .sink { [weak self] openPicker in
                guard let self = self else { return }
                self.showPicker(isOpen: openPicker)
            }.store(in: &cancelable)

        guard let previewView = viewModel.setupUI() else {
            failed()
            return
        }
        previewView.frame = captureView.layer.bounds
        captureView.layer.addSublayer(previewView)
        
        squareImageView.layer.borderWidth = 4
        squareImageView.layer.borderColor = UIColor.red.cgColor
        self.view.bringSubviewToFront(squareImageView)

    }


    private func failed() {
        let ac = UIAlertController(title: Constant.errorTitle, message: Constant.errorMessage, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: Constant.errorButton, style: .default) { [weak self] UIAlertAction in
            guard let self = self else { return }
            self.viewModel.reActivedCapture()
        })
        present(ac, animated: true)
    }

    private func showPicker(isOpen: Bool) {
        if isOpen {
            guard let pickerView = viewModel.showPicker()
            else {
                failed()
                return
            }
            pickerTextField.inputView = pickerView
            pickerTextField.inputAccessoryView = pickerView.toolbar
            pickerView.reloadAllComponents()
            pickerTextField.becomeFirstResponder()
        } else {
            view.endEditing(true)
        }
    }
}
