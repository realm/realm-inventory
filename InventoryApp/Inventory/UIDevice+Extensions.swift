//
//  UIDevice+Extensions.swift
//  Inventory
//
//  Created by David Spector on 2/25/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import UIKit


extension UIDevice {
    static var isSimulator: Bool {
        return ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil
    }
}
