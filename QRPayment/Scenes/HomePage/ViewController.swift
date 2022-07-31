//
//  ViewController.swift
//  QRPayment
//
//  Created by Erdoğan Turpcu on 28.07.2022.
//

import UIKit

class ViewController: UIViewController {

    struct Constant {
        static let customerText = "Müşteriyim"
        static let cashierText = "Kasiyerim"
        static let buttonTextColor = UIColor.white
        static let customerButtonBackgroundColor = UIColor.red
        static let cashierButtonBackgroundColor = UIColor.black
    }

    // MARK: @IBOutlet variables
    @IBOutlet weak var customerButton: UIButton!
    @IBOutlet weak var cashierButton: UIButton!

    // MARK: override methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.setupUI()
    }

    // MARK: Private functions
    private func setupUI() {
        customerButton.layer.cornerRadius = customerButton.bounds.height / 2
        customerButton.tintColor = Constant.buttonTextColor
        customerButton.backgroundColor = Constant.customerButtonBackgroundColor
        customerButton.titleLabel?.text = Constant.customerText

        cashierButton.layer.cornerRadius = cashierButton.bounds.height / 2
        cashierButton.tintColor = Constant.buttonTextColor
        cashierButton.backgroundColor = Constant.cashierButtonBackgroundColor
        cashierButton.titleLabel?.text = Constant.cashierText
    }

    // MARK: @IBAction functions
    @IBAction func customerButtonClicked(_ sender: Any) {
        let destinationVC = CustomerViewController(nibName: String(describing: CustomerViewController.self), bundle: nil)
        self.navigationController?.pushViewController(destinationVC, animated: true)
    }

    @IBAction func cashierButtonClicked(_ sender: Any) {
        let destinationVC = CashierViewController(nibName: String(describing: CashierViewController.self), bundle: nil)
        self.navigationController?.pushViewController(destinationVC, animated: true)
    }
}

