//
//  UIColor+AGAudioPlayer.swift
//  AGAudioPlayer
//
//  Created by Jacob Farkas on 3/25/19.
//  Copyright © 2019 Alec Gorge. All rights reserved.
//

import Foundation

// Copied from BCColor https://github.com/boycechang/BCColor
// That framework is abandoned and provides much more functionality than AGAudioPlayer needs, so the necessary functions are copied here.
extension UIColor {
    
    /**
     Lightens the color by a given `percentage`.
     - Parameter percentage: The `percentage` to lighten by. Values between 0–1.0 are accepted.
     - Returns: A new `UIColor` lightened by a given `percentage`.
     */
    public func lightenByPercentage(_ percentage: CGFloat) -> UIColor {
        // get the hue, sat, brightness, and alpha values
        var h : CGFloat = 0.0
        var s : CGFloat = 0.0
        var b : CGFloat = 0.0
        var a : CGFloat = 0.0
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        // increase the brightness value, max makes sure brightness does not go below 0 and min ensures that the brightness value does not go above 1.0
        b = max(min(b + percentage, 1.0), 0.0)
        
        // return a new UIColor with the new values
        return UIColor(hue: h, saturation: s, brightness: b, alpha: a)
    }
    
    /**
     Darkens the color by a given `percentage`.
     - Parameter percentage: The `percentage` to darken by. Values between 0–1.0 are accepted.
     - Returns: A new `UIColor` darkened by a given `percentage`.
     */
    public func darkenByPercentage(_ percentage: CGFloat) -> UIColor {
        return self.lightenByPercentage(-percentage)
    }
}
