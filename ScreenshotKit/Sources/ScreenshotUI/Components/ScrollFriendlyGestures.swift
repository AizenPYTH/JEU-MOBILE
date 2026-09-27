#if os(iOS)
import SwiftUI
import UIKit

// From iOS 18, a SwiftUI LongPressGesture / MagnifyGesture attached to an element inside a
// ScrollView wins the touch: a drag that starts on a photo, a contact or a message no longer
// scrolls the page (only the empty margins did). UIKit recognizers take part in UIKit's own
// arbitration with the scroll view's pan, so on iOS 18+ the phone's long press and pinch use them;
// iOS 17 keeps the SwiftUI gestures, which cooperate with scrolling there.

/// A long press that reports the finger going down / up (for the paper ring) and fires once
/// recognised. Fails beyond `allowableMovement`, so the scroll view takes over a drag.
@available(iOS 18.0, *)
struct PressRecognizer: UIGestureRecognizerRepresentable {
    let minimumDuration: TimeInterval
    let maximumDistance: CGFloat
    let onPressing: (Bool) -> Void
    let onRecognized: () -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> SimultaneousDelegate { SimultaneousDelegate() }

    func makeUIGestureRecognizer(context: Context) -> TouchReportingLongPress {
        let recognizer = TouchReportingLongPress()
        recognizer.cancelsTouchesInView = false
        recognizer.delaysTouchesBegan = false
        recognizer.delegate = context.coordinator
        return recognizer
    }

    func updateUIGestureRecognizer(_ recognizer: TouchReportingLongPress, context: Context) {
        recognizer.minimumPressDuration = minimumDuration
        recognizer.allowableMovement = maximumDistance
        recognizer.onPressing = onPressing
    }

    func handleUIGestureRecognizerAction(_ recognizer: TouchReportingLongPress, context: Context) {
        if recognizer.state == .began { onRecognized() }
    }
}

/// A two-finger pinch reporting its current scale, then its final scale.
@available(iOS 18.0, *)
struct PinchRecognizer: UIGestureRecognizerRepresentable {
    let onChanged: (CGFloat) -> Void
    let onEnded: (CGFloat) -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> SimultaneousDelegate { SimultaneousDelegate() }

    func makeUIGestureRecognizer(context: Context) -> UIPinchGestureRecognizer {
        let recognizer = UIPinchGestureRecognizer()
        recognizer.cancelsTouchesInView = false
        recognizer.delegate = context.coordinator
        return recognizer
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPinchGestureRecognizer, context: Context) {
        switch recognizer.state {
        case .began, .changed: onChanged(recognizer.scale)
        case .ended, .cancelled, .failed: onEnded(recognizer.scale)
        default: break
        }
    }
}

/// Lets the phone's recognizers run alongside the scroll view, buttons and taps.
final class SimultaneousDelegate: NSObject, UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
}

/// A long press that also says when a finger is down on the element and when it is gone
/// (lifted, moved away into a scroll, or recognised and reset).
final class TouchReportingLongPress: UILongPressGestureRecognizer {
    var onPressing: ((Bool) -> Void)?
    private var pressed = false

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        report(true)
    }

    override func reset() {
        super.reset()
        report(false)
    }

    private func report(_ value: Bool) {
        guard value != pressed else { return }
        pressed = value
        onPressing?(value)
    }
}

extension View {
    /// Pinch to zoom that does not stop the page from scrolling (see above).
    @ViewBuilder
    func phonePinch(changed: @escaping (CGFloat) -> Void, ended: @escaping (CGFloat) -> Void) -> some View {
        if #available(iOS 18.0, *) {
            gesture(PinchRecognizer(onChanged: changed, onEnded: ended))
        } else {
            gesture(MagnifyGesture()
                .onChanged { changed($0.magnification) }
                .onEnded { ended($0.magnification) })
        }
    }
}
#endif
