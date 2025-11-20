//
//  ValidationFuncs.swift
//  FlashcardAI
//
//  Created by Daniel Eror on 10/30/25.
//

import Foundation

func isValidName(_ name: String) -> Bool {
    let parts = name.split(separator: " ")
    return parts.count >= 2 && parts.allSatisfy { part in
        return !part.isEmpty
    }
}

func isValidEmail(_ email: String) -> Bool {
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

    let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailPred.evaluate(with: email)
}

func getPasswordStrength(_ pw: String) -> Int {
    let hasUppercase : Bool = pw.range(of: "[A-Z]", options: .regularExpression) != nil
    let hasLowercase : Bool = pw.range(of: "[a-z]", options: .regularExpression) != nil
    let hasNumber : Bool = pw.range(of: "[0-9]", options: .regularExpression) != nil
    let hasSpecial : Bool = pw.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        
    let features = [hasUppercase, hasLowercase, hasNumber, hasSpecial].filter { feature in feature }.count
        
    if pw.count >= 10 && features == 4 {
        return 2
    } else if pw.count >= 8 && features >= 2 {
        return 1
    } else {
        return 0
    }
}

