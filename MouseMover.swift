import AppKit
import ApplicationServices
import IOKit.pwr_mgt

private let accent = NSColor(srgbRed: 0.34, green: 0.91, blue: 0.76, alpha: 1)

@MainActor
final class CountdownView: NSView {
    var progress: Double = 0 { didSet { needsDisplay = true } }
    var running = false { didSet { needsDisplay = true } }

    override func draw(_ dirtyRect: NSRect) {
        let center = NSPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 10
        let track = NSBezierPath(ovalIn: NSRect(
            x: center.x - radius, y: center.y - radius,
            width: radius * 2, height: radius * 2
        ))
        track.lineWidth = 5
        NSColor.white.withAlphaComponent(0.07).setStroke()
        track.stroke()

        let arc = NSBezierPath()
        arc.lineWidth = 5
        arc.lineCapStyle = .round
        arc.appendArc(withCenter: center, radius: radius, startAngle: 90,
                      endAngle: 90 - 360 * max(0.002, progress), clockwise: true)
        accent.withAlphaComponent(running ? 1 : 0.35).setStroke()
        arc.stroke()

        let angle = (90 - 360 * progress) * .pi / 180
        let point = NSPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
        accent.withAlphaComponent(running ? 0.12 : 0).setFill()
        NSBezierPath(ovalIn: NSRect(x: point.x - 10, y: point.y - 10, width: 20, height: 20)).fill()
        accent.withAlphaComponent(running ? 1 : 0.35).setFill()
        NSBezierPath(ovalIn: NSRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)).fill()
    }
}

@MainActor
final class PowerButton: NSButton {
    var running = false { didSet { needsDisplay = true } }
    override var wantsUpdateLayer: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        let background = running
            ? NSColor.white.withAlphaComponent(isHighlighted ? 0.14 : 0.08)
            : accent.withAlphaComponent(isHighlighted ? 0.65 : 1)
        background.setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 14, yRadius: 14).fill()
        let text = NSAttributedString(string: title, attributes: [
            .font: NSFont.systemFont(ofSize: 15, weight: .semibold),
            .foregroundColor: running ? NSColor.white : NSColor(srgbRed: 0.06, green: 0.15, blue: 0.14, alpha: 1)
        ])
        let size = text.size()
        text.draw(at: NSPoint(x: (bounds.width - size.width) / 2, y: (bounds.height - size.height) / 2))
        if window?.firstResponder === self {
            accent.withAlphaComponent(0.5).setStroke()
            let focus = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 13, yRadius: 13)
            focus.lineWidth = 2
            focus.stroke()
        }
    }
}

@MainActor
final class MouseMoverApp: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private let countdown = NSTextField(labelWithString: "15")
    private let status = NSTextField(labelWithString: "●  READY")
    private let ring = CountdownView()
    private let toggle = PowerButton(title: "ON", target: nil, action: nil)
    private var timer: Timer?
    private var enabled = false
    private var nextMovement = 0.0
    private var movementTimer: Timer?
    private var sleepAssertion: IOPMAssertionID = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 430),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Mouse Wiggler"
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: .darkAqua)
        window.titlebarAppearsTransparent = true
        window.backgroundColor = NSColor(srgbRed: 0.055, green: 0.075, blue: 0.10, alpha: 1)
        countdown.font = .monospacedDigitSystemFont(ofSize: 64, weight: .light)
        countdown.textColor = .white
        countdown.alignment = .center
        countdown.setAccessibilityLabel("Seconds until the next mouse movement")
        status.font = .systemFont(ofSize: 10, weight: .semibold)
        status.textColor = .secondaryLabelColor
        toggle.isBordered = false
        toggle.focusRingType = .none
        toggle.setButtonType(.momentaryPushIn)
        toggle.target = self
        toggle.action = #selector(toggleMovement)
        toggle.setAccessibilityLabel("Turn mouse movement and keep-awake on or off")

        let icon = NSImageView()
        icon.image = NSImage(contentsOf: Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/MouseMover.icns"))
        icon.imageScaling = .scaleProportionallyUpOrDown
        let title = NSTextField(labelWithString: "Mouse Wiggler")
        title.font = .systemFont(ofSize: 18, weight: .semibold)
        let subtitle = NSTextField(labelWithString: "Tiny circles. Stay awake.")
        subtitle.font = .systemFont(ofSize: 11)
        subtitle.textColor = .secondaryLabelColor
        let heading = NSStackView(views: [title, subtitle])
        heading.orientation = .vertical
        heading.alignment = .leading
        heading.spacing = 4
        let header = NSStackView(views: [icon, heading])
        header.spacing = 10

        let unit = NSTextField(labelWithString: "SECONDS")
        unit.font = .systemFont(ofSize: 10, weight: .medium)
        unit.textColor = .secondaryLabelColor
        let digits = NSStackView(views: [countdown, unit])
        digits.orientation = .vertical
        digits.spacing = 0
        digits.translatesAutoresizingMaskIntoConstraints = false
        ring.addSubview(digits)
        let interval = NSTextField(labelWithString: "Every 15 seconds  ·  2 px circle")
        interval.font = .systemFont(ofSize: 11)
        interval.textColor = .secondaryLabelColor
        let stack = NSStackView(views: [header, status, ring, toggle, interval])
        stack.orientation = .vertical
        stack.spacing = 16
        stack.setCustomSpacing(6, after: status)
        stack.setCustomSpacing(12, after: toggle)
        stack.translatesAutoresizingMaskIntoConstraints = false
        window.contentView!.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: window.contentView!.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: window.contentView!.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 44),
            icon.heightAnchor.constraint(equalToConstant: 44),
            ring.widthAnchor.constraint(equalToConstant: 194),
            ring.heightAnchor.constraint(equalToConstant: 194),
            digits.centerXAnchor.constraint(equalTo: ring.centerXAnchor),
            digits.centerYAnchor.constraint(equalTo: ring.centerYAnchor, constant: 4),
            toggle.widthAnchor.constraint(equalToConstant: 208),
            toggle.heightAnchor.constraint(equalToConstant: 44)
        ])
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func toggleMovement() {
        if enabled {
            stop()
            return
        }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        guard AXIsProcessTrustedWithOptions(options as CFDictionary) else {
            let alert = NSAlert()
            alert.messageText = "Accessibility permission required"
            alert.informativeText = "Allow Mouse Wiggler in System Settings → Privacy & Security → Accessibility, then press ON again. If it isn't listed, add this app using the + button."
            alert.runModal()
            return
        }
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "Mouse Wiggler is keeping the display and Mac awake" as CFString,
            &sleepAssertion
        )
        guard result == kIOReturnSuccess else {
            sleepAssertion = 0
            let alert = NSAlert()
            alert.messageText = "Couldn't enable keep-awake"
            alert.informativeText = "macOS rejected the sleep-prevention request. Please try again."
            alert.runModal()
            return
        }
        enabled = true
        toggle.title = "OFF"
        toggle.running = true
        ring.running = true
        status.stringValue = "●  AWAKE"
        status.textColor = accent
        nextMovement = ProcessInfo.processInfo.systemUptime + 15
        let refreshInterval = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0.25 : 0.05
        timer = Timer(timeInterval: refreshInterval, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .common)
        tick()
    }

    @objc private func tick() {
        let now = ProcessInfo.processInfo.systemUptime
        if now >= nextMovement {
            guard AXIsProcessTrusted() else {
                stop()
                return
            }
            drawTinyCircle()
            nextMovement = now + 15
        }
        let remaining = max(0, nextMovement - now)
        let digits = "\(Int(ceil(remaining)))"
        if countdown.stringValue != digits {
            countdown.stringValue = digits
        }
        ring.progress = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
            ? 1 - ceil(remaining) / 15 : 1 - remaining / 15
    }

    private func drawTinyCircle() {
        guard movementTimer == nil, !mouseButtonIsDown(),
              let event = CGEvent(source: nil) else { return }
        let origin = event.location
        var previous = origin
        var frame = 0
        let animation = Timer(timeInterval: 0.02, repeats: true) { [weak self] timer in
            MainActor.assumeIsolated {
                guard let self, self.enabled, AXIsProcessTrusted(),
                      !self.mouseButtonIsDown(), let current = CGEvent(source: nil),
                      hypot(current.location.x - previous.x, current.location.y - previous.y) < 4 else {
                    timer.invalidate()
                    self?.movementTimer = nil
                    return
                }
                frame += 1
                let angle = Double(frame) / 12 * 2 * .pi
                let position = frame == 12 ? origin : CGPoint(
                    x: origin.x + cos(angle) - 1,
                    y: origin.y + sin(angle)
                )
                guard let movement = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved,
                                             mouseCursorPosition: position, mouseButton: .left) else {
                    timer.invalidate()
                    self.movementTimer = nil
                    return
                }
                movement.post(tap: .cghidEventTap)
                previous = position
                if frame == 12 {
                    timer.invalidate()
                    self.movementTimer = nil
                }
            }
        }
        movementTimer = animation
        RunLoop.main.add(animation, forMode: .common)
    }

    private func mouseButtonIsDown() -> Bool {
        [.left, .right, .center].contains {
            CGEventSource.buttonState(.combinedSessionState, button: $0)
        }
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
        movementTimer?.invalidate()
        movementTimer = nil
        if sleepAssertion != 0 {
            IOPMAssertionRelease(sleepAssertion)
            sleepAssertion = 0
        }
        enabled = false
        toggle.title = "ON"
        toggle.running = false
        ring.running = false
        ring.progress = 0
        status.stringValue = "●  READY"
        status.textColor = .secondaryLabelColor
        countdown.stringValue = "15"
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationWillTerminate(_ notification: Notification) {
        stop()
    }
}

MainActor.assumeIsolated {
    let application = NSApplication.shared
    let delegate = MouseMoverApp()
    application.delegate = delegate
    application.setActivationPolicy(.regular)
    application.run()
}
