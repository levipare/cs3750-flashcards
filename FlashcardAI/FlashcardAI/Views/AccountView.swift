//
//  AccountView.swift
//  FlashcardAI
//
//  Created by Daniel Eror on 10/29/25.
//

import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct AccountView: View {
    @EnvironmentObject var viewModel : AuthViewModel
    var body: some View {
        VStack {
            HStack {
                Text("Display name:").font(.system(size: 16))
                Spacer()
            }.padding(.horizontal)
            HStack {
                Text(viewModel.userProfile?.displayName ?? "").font(.system(size: 32))
                Spacer()
//                Image(systemName: "pencil")
//                    .foregroundColor(.primary)
//                    .font(.system(size: 36))
            }.padding(.horizontal)
            .padding(.bottom)
            
            
            
            HStack {
                Text("Current email:").font(.system(size: 16))
                Spacer()
            }.padding(.horizontal)
            HStack {
                Text(viewModel.userProfile?.email ?? "").font(.system(size: 24))
                Spacer()
//                Image(systemName: "pencil")
//                    .foregroundColor(.primary)
//                    .font(.system(size: 36))
            }.padding(.horizontal)
            
            Spacer()
            
        }.task {
            await viewModel.fetchUserProfile(for: Auth.auth().currentUser?.uid ?? "")
        }
        .padding()
    }
}
