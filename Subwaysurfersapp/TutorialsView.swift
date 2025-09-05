//
//  TutorialsView.swift
//  Subwaysurfersapp
//
//  Created by Tan Xin Tong Joy on 16/8/25.
//

import SwiftUI

struct TutorialsView: View {
    var body: some View {
      
        ScrollView{
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
                        Text("________________________")
                            . offset(x:-90, y: 0)
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
                    Text("________________________")
                        . offset(x:-90)
                    Spacer()
                }
            }
            Spacer()
            HStack{
                ZStack{
                    Rectangle()
                        .frame(width: 167.5, height: 267.5)
                    
                    Image("baldlungesguy")
                        .resizable()
                        .frame(width:150,height:250)
                }
                VStack{
                    Text("Lunges")
                        .font(.title2)
                        .bold()
                    
                    Text("Tips:")
                        .font(.title2)
                        .bold()
                    
                    Text("- Torso straight and core engaged yup yup")
                    Spacer()
                    Text("- Bend your kneesyup yupyupyupyupyup")
                    Spacer()
                    Text("- Lower your body towards the ground")
                    Spacer()
                    Text("________________________")
                        . offset(x:-90)
                    Spacer()
                }
            }
            Spacer()
            HStack{
                ZStack{
                    Rectangle()
                        .frame(width: 167.5, height: 267.5)
                    
                    Image("mountainerclimberguy")
                        .resizable()
                        .frame(width:150,height:250)
                }
                VStack{
                    Text("Mountain climbers")
                        .font(.title2)
                        .bold()
                    
                    Text("Tips:")
                        .font(.title2)
                        .bold()
                    
                    Text("- Keep your core engaged at all times")
                    Spacer()
                    Text("- Emsure your back is aligned with your neck")
                    Spacer()
                    Text("- Do not lower your back, glutes or hips.")
                    Spacer()
                    Text("________________________")
                        . offset(x:-90)
                    Spacer()
                }
            }
            
        }
        
    }
}

#Preview {
    TutorialsView()
}

