//
//  TimelapseAppApp.swift
//  TimelapseApp
//
//  Created by A K on 11/10/24.
//

import SwiftUI

@main
struct TimelapseAppApp: App {
    @StateObject private var menuBarController = MenuBarController()
    
    var body: some Scene {
        MenuBarExtra("Timelapse", systemImage: "camera") {
            MenuBarView(menuBarController: menuBarController)
                .environmentObject(menuBarController)
        }
        .menuBarExtraStyle(.window)
    }
}
