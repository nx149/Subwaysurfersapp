//
//  ContentView.swift
//  Subwaysurfersapp
//
//  Created by T Krobot on 16/8/25.
//

import SwiftUI
var currentStreak = 5

struct ContentView: View {
    var body: some View {
        
        
        TabView {
            Tab("Home", systemImage: "house") {
                
                VStack {
                    
                    HStack {
                        Text("Welcome, User!")
                            .bold()
                            .font(.system(size: 30))
                        Text("Streak \(currentStreak)")
                            .padding()
                            .foregroundStyle(Color.red)
                        Spacer()
                    }
                    
                    Text("Current Badge:")
                        .bold()
                        .font(.system(size:30))
                        .padding()
                    
                    Image("Badge")
                        .resizable()
                        .frame(width: 300 , height: 350)
                    
                    
                    Button("edit...") {
                    }
                    .font(.system(size: 25))
                    
                    
                    Button("Start") {
                        
                    }
                    .bold()
                    .padding(30)
                    .font(.system(size:50))
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    Spacer()
                    
                }
                .padding()
                
            }
            
            Tab("Leaderboard", systemImage: "trophy") {
                
            LeaderboardView()
            }
            Tab("exercise", systemImage: "heart") {
                TutorialsView()
            }
        }
    }
}


#Preview {
    ContentView()
}
