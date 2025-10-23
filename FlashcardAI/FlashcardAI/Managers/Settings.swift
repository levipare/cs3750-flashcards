//
//  Settings.swift
//  FlashcardAI
//
//  Created by Daniel Eror on 10/23/25.
//

import SwiftUI

class Settings : ObservableObject {
    @Published var colorScheme : ColorScheme = .light
    @Published var darkModeToggleState : Bool {
        didSet{
            colorScheme = darkModeToggleState ? .dark : .light
        }
    }
    
    init() {
        darkModeToggleState = false;
    }
}
