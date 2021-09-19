#!/usr/bin/env xcrun -sdk macosx swift

import Foundation
import SwiftUI
import Combine
import Cocoa

let app = NSApplication.shared
let title = "github.com/alja7dali/swift-timer"

enum Sound: String, CaseIterable {
  case
    basso,
    blow,
    bottle,
    frog,
    funk,
    glass,
    hero,
    morse,
    ping,
    pop,
    purr,
    sosumi,
    submarine,
    tink

  var name: String {
    return "\(rawValue.first!.uppercased())\(rawValue.dropFirst().map(String.init).joined())"
  }

  var soundPlayer: Optional<NSSound> {
    return .init(named: name)
  }
}

let scaleFactor: CGFloat = {
  let factor = CGFloat(
    CommandLine.arguments.count > 1 ?
      Int(CommandLine.arguments[1]) ?? 1 : 1
  )
  return factor > 5 ? 5 : factor
}()

let origin = CGPoint(x: 1, y: 1)

class AppDelegate: NSObject, NSApplicationDelegate {

  let window = NSWindow(
    contentRect: NSRect(
      origin: origin,
      size: CGSize(
        width: 1,
        height: .zero
      )
    ),
    styleMask: [.titled, .closable, .fullScreen],
    backing: .buffered,
    defer: false,
    screen: .main
  )

  func applicationDidFinishLaunching(_: Notification) {
    window.setFrameAutosaveName("Main Window")
    window.contentView = NSHostingView(rootView: 
      ApplicationView()
      .preferredColorScheme(.dark)
    )

    window.makeKeyAndOrderFront(nil)
    window.title = title

    NSApp.setActivationPolicy(.regular)
    NSApp.activate(ignoringOtherApps: true)
  }

  func applicationDockMenu(_: NSApplication) -> Optional<NSMenu> {
    return .init(title: title)
  }

  func applicationDidResignActive(_: Notification) {
    // always on front
    if scaleFactor < 3 {
      window.level = .floating
    }
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }

  func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
    return true
  }
}

let delegate: Optional<AppDelegate> = AppDelegate()
app.delegate = delegate

app.run()

extension ColorScheme {
  var foregroundColor: Color {
    if case .light = self {
      return .black
    } else {
      return .white
    }
  }
}

struct ApplicationView: SwiftUI.View {
  @Environment(\.colorScheme) var colorScheme
  @State private var isCountingDown: Bool = false
  @State private var showResetButton: Bool = false
  @State private var showStartButton: Bool = false

  @State private var playSoundEffectWhenDoneCountingdown: Bool = true
  @State private var soundEffect: Sound = .ping
  var player: Optional<NSSound> {
    return soundEffect.soundPlayer
  }

  @State var didStartPlayingSoundEffect: Bool = false
  var shouldPlaySoundEffect: Bool {
    return !didStartPlayingSoundEffect && playSoundEffectWhenDoneCountingdown
  }

  var shouldStartFlashing: Bool {
    return clock[H] == 0 && clock[M] == 0 && clock[S] <= 5
  }

  @State var timer: Publishers.Autoconnect<Timer.TimerPublisher>!

  @State var clock: Array<Int> = [0, 0, 0] {
    didSet {
      if shouldStartFlashing && shouldPlaySoundEffect {
        didStartPlayingSoundEffect = true
        player?.loops = true
        player?.play()
        Timer.scheduledTimer(withTimeInterval: Double(clock[S]), repeats: false) { (timer) in
          player?.stop()
        }
      } 
    }
  }

  let H: Int = 0 // HOURS
  let M: Int = 1 // MINUTES
  let S: Int = 2 // SECONDS

  var prettyClock: String {
    let h: String = clock[H] < 10 ? "0\(clock[H])" : "\(clock[H])"
    let m: String = clock[M] < 10 ? "0\(clock[M])" : "\(clock[M])"
    let s: String = clock[S] < 10 ? "0\(clock[S])" : "\(clock[S])"
    return "\(h):\(m):\(s)"
  }

  var body: some View {
    if isCountingDown {
      displayClock()
        .onReceive(timer!, perform: updateClock)
    } else {
      displayClock()
    }
  }

  func updateClock(_: Date) {
    if clock[S] > 0 {
      clock[S] -= 1
    } else {
      clock[S] = 59
      if clock[M] > 0 {
        clock[M] -= 1
      } else {
        clock[M] = 59
        if clock[H] > 0 {
          clock[H] -= 1
        } else {
          stopTimer()
        }
      }
    }
  }

  func displayClock() -> some View {
    return ZStack {
      VStack {
        if isCountingDown {
          if shouldStartFlashing {
            Text(prettyClock)
              .foregroundColor(clock[S] % 2 == 0 ? .white : .white.opacity(0.5))
              .font(.system(size: 80 * scaleFactor, weight: .ultraLight))
          } else {
            Text(prettyClock)
              .font(.system(size: 80 * scaleFactor, weight: .ultraLight))
          }
        } else {
          makeClockPicker()
        }
      }
      makeStartButton()
      makeSoundEffectSelection()
    }
    .frame(width: 324 * scaleFactor, height: 156 * scaleFactor)
    .padding(.bottom, 20)
  }

  func stopTimer() {
    timer.upstream.connect().cancel()
    isCountingDown = false
    showStartButton = false
    showResetButton = false
    clock = [0, 0, 0]
    clockSelection = ["", "", ""]
    didStartPlayingSoundEffect = false
  }

  func startTimer() {
    isCountingDown = true
    timer = Timer
      .publish(every: 1, on: .main, in: .common)
      .autoconnect()
  }

  func makeStartButton() -> some View {
    VStack {
      if showStartButton {
        Spacer()
        HStack {
          Spacer()
          Button(action: {
            if isCountingDown {
              stopTimer()
            } else {
              startTimer()
            }
          }, label: {
            if isCountingDown {
              Text("Reset")
            } else {
              Text("Start")
            }
          })
          .cornerRadius(20)
          .clipped()
          Spacer()
        }
      }
    }
  }

  func makeSoundEffectSelection() -> some View {
    let sounds = Sound.allCases
    return VStack {
      HStack {
        if !isCountingDown {
          Button(action: {
            playSoundEffectWhenDoneCountingdown.toggle()
          }, label: {
            Image(systemName: playSoundEffectWhenDoneCountingdown ? "speaker.wave.3.fill" : "speaker.slash.fill")
              .resizable()
              .scaledToFit()
              .frame(width: 16, height: 16)
              .foregroundColor(.white)
          })
          if playSoundEffectWhenDoneCountingdown {
            Picker("Sound", selection: $soundEffect, content: {
              ForEach(0..<sounds.count) { i in
                Text(sounds[i].rawValue).tag(sounds[i])
                  .foregroundColor(.white)
              }
            })
            .pickerStyle(MenuPickerStyle())
          }
        } else {
          Image(systemName: playSoundEffectWhenDoneCountingdown ? "speaker.wave.3.fill" : "speaker.slash.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
            .foregroundColor(.white)
          Text(soundEffect.name)
            .foregroundColor(.white)
        }
        Spacer()
      }
      .padding()
      Spacer()
    }
  }

  func shouldShowStartButton() {
    showStartButton = !(clock[H] == 0 && clock[M] == 0 && clock[S] == 0)
  }

  func makeTextfield(
    text: Binding<String>,
    placeholder: String,
    validate: @escaping (Binding<String>) -> Void
  ) -> some View {
    return ZStack {
      Text(placeholder)
        .font(.system(size: 44 * scaleFactor, weight: .light))
        .foregroundColor(colorScheme.foregroundColor.opacity(text.wrappedValue.isEmpty ? 0.5 : 0))

      TextField("", text: text)
        .font(.system(size: 44 * scaleFactor, weight: .light))
        .onChange(of: text, perform: validate)
        .background(Color.clear)
        .frame(width: 60 * scaleFactor)
    }
  }
    
  @State var clockSelection: Array<String> = ["", "", ""]

  enum ClockUnit: Int {
    case
      hour,
      minute,
      second
    
    var maxValue: Int {
      switch self {
      case .second, .minute:
        return 59
      case .hour:
        return 23
      }
    }

    var minValue: Int {
      return 0
    }
  }
  
  func makeClockUnitPicker(for unit: ClockUnit) -> some View {
    return makeTextfield(text: $clockSelection[unit.rawValue], placeholder: "00", validate: { _ in
      if let val = Int(clockSelection[unit.rawValue]) {
        if val < unit.minValue {
          clockSelection[unit.rawValue] = "\(unit.minValue)"
          clock[unit.rawValue] = unit.minValue
        } else if val > unit.maxValue {
          clockSelection[unit.rawValue] = "\(unit.maxValue)"
          clock[unit.rawValue] = unit.maxValue
        } else {
          clockSelection[unit.rawValue] = String(val)
          clock[unit.rawValue] = val
        }
      } else {
        clockSelection[unit.rawValue] = ""
        clock[unit.rawValue] = 0
      }
      shouldShowStartButton()
    })
  }
  
  func makeClockPicker() -> some View {
    return HStack {
      makeClockUnitPicker(for: .hour)
      Text(":")
        .font(.system(size: 50 * scaleFactor, weight: .light))
      makeClockUnitPicker(for: .minute)
      Text(":")
        .font(.system(size: 50 * scaleFactor, weight: .light))
      makeClockUnitPicker(for: .second)
    }
  }
}

extension Binding: Equatable where Value == String {
  public static func ==(lhs: Self, rhs: Self) -> Bool {
    return lhs.wrappedValue == rhs.wrappedValue
  }
}
