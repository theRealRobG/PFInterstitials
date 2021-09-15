//
//  ViewController.swift
//  ReferenceApp
//
//  Created by Robert Galluccio on 15/09/2021.
//

import UIKit
import AVFoundation
import PFInterstitials

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func testPressed(_ sender: Any) {
        let event = PFInterstitialEvent(
            primaryItem: nil,
            identifier: nil,
            time: .zero,
            templateItems: []
        )
        print(event.identifier)
    }
}
