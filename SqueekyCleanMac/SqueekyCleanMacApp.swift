//
//  SqueekyCleanMacApp.swift
//  SqueekyCleanMac
//
//  Created by Fabien Brocklesby on 14/05/2026.
//

import SwiftUI

@main
struct SqueekyCleanMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel = CleaningLockViewModel()

    var body: some Scene {
        WindowGroup {
            CleaningLockView(viewModel: viewModel)
                .frame(width: 420, height: 520)
                .onAppear {
                    appDelegate.configureWindow()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 420, height: 520)

        MenuBarExtra("Squeeky Clean Mac", systemImage: viewModel.menuBarSystemImage) {
            MenuBarLockView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
