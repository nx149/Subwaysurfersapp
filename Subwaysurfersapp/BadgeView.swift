//
//  BadgeView.swift
//  Subwaysurfersapp
//
//  Created by T Krobot on 23/8/25.
//

import SwiftUI

struct BadgeView: View {
    @State private var Banner = false
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
                
                ZStack{
                    
                    Image("Badge")
                        .resizable()
                        .frame(width: 300 , height: 350)
                    
                }
                
                
                    Button("banner") {
                        if Banner == false {
                            Banner = true
                        }
                        else if Banner == true {
                            Banner = false
                        }
                    }
                    .padding()
                    
                if Banner == true {
       
                            Image("Banner")
                                .offset(x: 0, y: -300)
                                .padding()
                        
                    }
                    else if Banner == false {
    
                    }
                    
                
                Spacer()
            }
        }
        .padding()
        
    }
}


#Preview {
    BadgeView()
}
