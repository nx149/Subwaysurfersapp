//
//  BadgeView.swift
//  Subwaysurfersapp
//
//  Created by T Krobot on 23/8/25.
//

import SwiftUI

struct BadgeView: View {
    var body: some View {
        HStack {
            VStack{
                Text("Badge")
                    .bold()
                    .font(.system(size: 35))
                Text("Customise your own badge!")
                    .foregroundStyle(Color.gray)
                Text("Accessories:")
                    .padding()
                    .font(.system(size: 20))
            Spacer()
            }
            .padding()
        }
        .padding()
        
    }
}
    
    
    #Preview {
        BadgeView()
    }
