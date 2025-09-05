//
//  LeaderboardView.swift
//  Subwaysurfersapp
//
//  Created by Tan Xin Tong Joy on 23/8/25.
//

import SwiftUI

struct LeaderboardView: View {
    var body: some View {
        let janScore = 100
        let febScore = 92
        let marScore = 72
        let aprScore = 42
        let mayScore = 2
        let junScore = 90
        let julScore = 22
        let augScore = 34
        let sepScore = 84
        let octScore = 12
        let novScore = 82
        let decScore = 73
        
        ScrollView{
            VStack{
                Text("Compete against yourself!")
                Text("Personal scores:")
                
                HStack{
                    Image("goldtrophy")
                        .resizable()
                        .frame(width:50,height:50)
                    Text("1. 100(20/8/25)")
                }
                
                HStack{
                    Image("bronzetrophy")
                        .resizable()
                        .frame(width: 50, height: 50)
                    Text("2. 88(28/8/25)")
                }
                
                HStack{
                    Image("slivertrophy")
                        .resizable()
                        .frame(width: 50, height: 50)
                    Text("3. 87(28/8/25)")
                }
                
                Text("Average score for the month: 208")
                VStack{
                    Text("Jan: \(janScore)")
                    Text("Feb: \(febScore)")
                    Text("Mar: \(marScore)")
                    Text("Apr: \(aprScore)")
                    Text("May: \(mayScore)")
                    Text("Jun: \(junScore)")
                    Text("Jul: \(julScore)")
                    Text("Aug: \(augScore)")
                    Text("Sep: \(sepScore)")
                    Text("Oct: \(octScore)")
                    Text("Nov: \(novScore)")
                    Text("Dec: \(decScore)")
                }
            }
        }
    }
}

#Preview {
    LeaderboardView()
}
