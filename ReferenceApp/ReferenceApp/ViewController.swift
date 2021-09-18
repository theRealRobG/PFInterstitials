//
//  ViewController.swift
//  ReferenceApp
//
//  Created by Robert Galluccio on 15/09/2021.
//

import UIKit
import AVKit
import PFInterstitials

extension AVPlayerViewController: RenderingTarget {
    public func updatePlayerReference(player: AVPlayer) {
        self.player = player
    }
}

class ViewController: UIViewController {
    let vodURL = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8")!
    let liveURL = URL(string: "https://live.unified-streaming.com/scte35/scte35.isml/master.m3u8?hls_fmp4")!
    let advertBreak = [
        URL(string: "https://mssl.fwmrm.net/m/1/169843/59/6662075/YVWF0614000H_ENT_MEZZ_HULU_1925786_646/master_cmaf.m3u8")!,
        URL(string: "https://mssl.fwmrm.net/m/1/169843/17/6662161/SBON9969000H_ENT_MEZZ_HULU_1925782_646/master_cmaf.m3u8")!
    ]
    var interstitialEventController: PFInterstitialEventController?
    var eventsDidChangeObserver: NSObjectProtocol?
    var currentEventDidChangeObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        eventsDidChangeObserver.map { NotificationCenter.default.removeObserver($0) }
        currentEventDidChangeObserver.map { NotificationCenter.default.removeObserver($0) }
        eventsDidChangeObserver = NotificationCenter.default.addObserver(
            forName: PFInterstitialEventController.eventsDidChangeNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let controller = notification.object as? PFInterstitialEventController else { return }
            print("New events - \(controller.events.map { $0.identifier })")
        }
        currentEventDidChangeObserver = NotificationCenter.default.addObserver(
            forName: PFInterstitialEventController.currentEventDidChangeNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let controller = notification.object as? PFInterstitialEventController else { return }
            print("New current event - \(controller.currentEvent?.identifier ?? "NIL")")
        }
    }

    @IBAction func playVODPressed(_ sender: Any) {
        let player = AVPlayer(url: vodURL)
        let playerController = AVPlayerViewController()
        interstitialEventController = PFInterstitialEventController(
            primaryPlayer: player,
            renderingTarget: playerController
        )
        interstitialEventController?.events = [
            PFInterstitialEvent(
                primaryItem: player.currentItem,
                identifier: nil,
                time: CMTime(value: 10, timescale: 1),
                templateItems: advertBreak.map { AVPlayerItem(url: $0) }
            ),
            PFInterstitialEvent(
                primaryItem: player.currentItem,
                identifier: nil,
                time: CMTime(value: 20, timescale: 1),
                templateItems: advertBreak.reversed().map { AVPlayerItem(url: $0) }
            )
        ]
        present(playerController, animated: true) { player.play() }
    }

    @IBAction func playLivePressed(_ sender: Any) {
        let player = AVPlayer(url: liveURL)
        let playerController = AVPlayerViewController()
        playerController.player = player
        present(playerController, animated: true) { player.play() }
    }
}
