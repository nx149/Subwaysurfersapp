//
//  BadgeView.swift
//  Subwaysurfersapp
//
//  Created by T Krobot on 23/8/25.
//

import SwiftUI

struct BadgeView: View {
    @State private var hiHatIsShown = false
    @State private var threeArrow = false
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
                Image("Badge")
                    .resizable()
                     .frame(width: 300 , height: 350)
               
                
                HStack {
                    Button("banner") {
                        hiHatIsShown = true
                    }
                    if hiHatIsShown == true {
                        Image("Banner")
                            .offset(x: 0, y: -200)
                    }
                    
                    Button("Arrows") {
                        
                    }
                }
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
