//
//  TutorialsView.swift
//  Subwaysurfersapp
//
//  Created by Tan Xin Tong Joy on 16/8/25.
//

import SwiftUI

struct TutorialsView: View {
    var body: some View {
        VStack {
            Spacer()
            HStack{
                ZStack{
                    Rectangle()
                        .frame(width: 167.5, height: 267.5)
                    
                    Image("Womansquating")
                        .resizable()
                        .frame(width:150,height:250)
                }
                VStack{
                    Spacer()
                    Text("Half Squat")
                        .font(.title2)
                        .bold()
                    
                    Text("Tips:")
                        .font(.title2)
                        .bold()
                    
                    Text("- Stand with feet shoulder-width apart.")
                   Spacer()
                    Text("- Sit down into a squat position, keeping your heels and toes on the ground, chest up, and shoulders back.")
                       Spacer()
                    Text("- Straighten your legs to lift back to a standing position.")
                       Spacer()
                    Text("_________________________")
                        . offset(x:-90)
                    Spacer()
                }
            }
        }
        Spacer()
        HStack{
            ZStack{
                Rectangle()
                    .frame(width: 167.5, height: 267.5)
                
                Image("jumpingjacks")
                    .resizable()
                    .frame(width:150,height:250)
            }
            VStack{
                Text("Half Squat")
                    .font(.title2)
                    .bold()
                
                Text("Tips:")
                    .font(.title2)
                    .bold()
                
                Text("- Stand with feet shoulder-width apart.")
                  Spacer()
                Text("- Sit down into a squat position, keeping your heels and toes on the ground, chest up, and shoulders back.")
                Spacer()
                Text("- Straighten your legs to lift back to a standing position.")
                Spacer()
             Text("_________________________")
                    . offset(x:-90)
                Spacer()
            }
        }
    }
    
}

#Preview {
    TutorialsView()
}

