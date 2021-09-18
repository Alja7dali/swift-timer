#!/usr/bin/env xcrun -sdk macosx swift

import Foundation
import SwiftUI
import Combine
import Cocoa

let app = NSApplication.shared
let title = "github.com/alja7dali/swift-timer"

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
    window.contentView = NSHostingView(rootView: ApplicationView())

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
    window.level = .floating
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

struct ApplicationView: SwiftUI.View {
  @State private var isCountingDown: Bool = false
  @State private var showResetButton: Bool = false
  @State private var showStartButton: Bool = false

  @State var timer: Publishers.Autoconnect<Timer.TimerPublisher>!

  @State var clock: Array<Int> = [0, 0, 0]

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
        .onReceive(timer!, perform: { _ in
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
        })
    } else {
      displayClock()
    }
  }

  func displayClock() -> some View {
    ZStack {
      VStack {
        if isCountingDown {
          Text(prettyClock)
            .font(.system(size: 50))
        } else {
          makeSelectButtons()
        }
      }
      VStack {
        Spacer()
        HStack {
          Spacer()
          if showStartButton {
            makeStartButton()
          }
          Spacer()
        }
      }
    }
    .frame(width: 300, height: 150)
    .padding(.bottom, 20)
  }

  func stopTimer() {
    timer.upstream.connect().cancel()
    isCountingDown = false
    showStartButton = false
    showResetButton = false
    clock = [0, 0, 0]
  }

  func makeStartButton() -> some View {
    Button(action: {
      if isCountingDown {
        stopTimer()
      } else {
        isCountingDown = true
        timer = Timer
          .publish(every: 1, on: .main, in: .common)
          .autoconnect()
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
  }

  func shouldShowStartButton() {
    showStartButton = !(clock[H] == 0 && clock[M] == 0 && clock[S] == 0)
  }

  @State private var timesUp = Date()

  func makeSelectButtons() -> some View {
    return HStack {
      VStack {
        Button(action: {
          clock[H] = clock[H] < 23 ? clock[H] + 1 : clock[H]
          shouldShowStartButton()
        }, label: {
          Image(systemName: "plus")
        })
        .frame(width: 20, height: 20)
        .cornerRadius(10)
        .clipped()
        Text(clock[H].description)
        Button(action: {
          clock[H] = clock[H] > 0 ? clock[H] - 1 : clock[H]
          shouldShowStartButton()
        }, label: {
          Image(systemName: "minus")
        })
        .frame(width: 20, height: 20)
        .cornerRadius(10)
        .clipped()
      }
      Text(":")
      VStack {
        Button(action: {
          clock[M] = clock[M] < 59 ? clock[M] + 1 : clock[M]
          shouldShowStartButton()
        }, label: {
          Image(systemName: "plus")
        })
        .frame(width: 20, height: 20)
        .cornerRadius(10)
        .clipped()
        Text(clock[M].description)
        Button(action: {
          clock[M] = clock[M] > 0 ? clock[M] - 1 : clock[M]
          shouldShowStartButton()
        }, label: {
          Image(systemName: "minus")
        })
        .frame(width: 20, height: 20)
        .cornerRadius(10)
        .clipped()
      }
      Text(":")
      VStack {
        Button(action: {
          clock[S] = clock[S] < 59 ? clock[S] + 1 : clock[S]
          shouldShowStartButton()
        }, label: {
          Image(systemName: "plus")
        })
        .frame(width: 20, height: 20)
        .cornerRadius(10)
        .clipped()
        Text(clock[S].description)
        Button(action: {
          clock[S] = clock[S] > 0 ? clock[S] - 1 : clock[S]
          shouldShowStartButton()
        }, label: {
          Image(systemName: "minus")
        })
        .frame(width: 20, height: 20)
        .cornerRadius(10)
        .clipped()
      }
    }
  }
}