# Polyfill Interstitials
The purpose of this framework is to attempt to polyfill the functionality introduced by HLS Interstitials (and the accompanying AVFoundation additions) into previous versions of iOS and tvOS. The methodology used is a dual player approach and effort is taken to stay as close to the API presented by AVFoundation as possible. The implementation details are mainly following the descriptions given in revision `1.0b3` of the [Getting Started With HLS Interstitials](https://developer.apple.com/streaming/GettingStartedWithHLSInterstitials.pdf) guide.

## Usage
Usage is intended to be very similar to AVFoundation types introduced for HLS Interstitials. For the most part, instances of `AVPlayer` in interstitial type names have been replaced with `PF` (which represents `Polyfill`).

### Scheduling Interstitials
The main point of interaction is the `PFInterstitialEventController`. An example integration (following a similar format to the `Scheduling Interstitials` example in the guide) can be seen as follows:
```swift
let player = AVPlayer(url: movieURL)
let controller = PFInterstitialEventController(primaryPlayer: player, renderingTarget: playerController)
let adPodItems = [AVPlayerItem(url: ad1URL), AVPlayerItem(url: ad2URL)]
let event = PFInterstitialEvent(
    primaryItem: player.curentItem, 
    time: CMTime(seconds: 10, preferredTimescale: 1),
    templateItems: adPodItems,
    restrictions: [],
    resumptionOffset: .zero
)
controller.events = [event]
player.play()
```
While the interaction is quite similar, there is an important difference, which is that with `PFInterstitialEventController` a `RenderingTarget` must be provided. The reason for this is that we don't have underlying system access to control the output of the `AVPlayer` to a layer, and so the framework has to be given a method for controlling which player (primary vs interstitial) is active at any time. In the example above the assumption is that an `extension` has been made on `AVPlayerViewController` to implement `RenderingTarget` and perhaps looks something like the following:
```swift
extension AVPlayerViewController: RenderingTarget {
    public func updatePlayerReference(player: AVPlayer) {
        self.player = player
    }
}
```

###  Monitoring Interstitial Playback
Monitoring events is again very similar to the AVFoundation methodology. Events are published to `NotificationCenter.default` and observers can be added to the `primaryPlayer` and `interstitialPlayer` as normal (for example to track transitions between items). Following the same example from the guide we would have:
```swift
NotificationCenter.default.addObserver(
    forName: PFInterstitialEventController.currentEventDidChangeNotification,
    object: observer,
    queue: OperationQueue.main
) { _ in
    self.updateUI(observer.currentEvent)
}
```

## Project Status
This is still in development stage. The functionality works to a certain degree and is demonstrated as such in the `ReferenceApp` contained within the repo. As of writing there are a few features I would like to accomplish before I consider this useful:
- Scheduling events by `Date`
- Resumption offset (currently always `.zero`)
- Playout limit (currently always `.indefinite`)
- Automatic handling of `EXT-X-DATERANGE` in manifest
- Seek rules _(stretch goal given `AVPlayerInterstitialEventController` doesn’t handle this)_
- Block access to queue modification (perhaps with class extension on `AVQueuePlayer`)
