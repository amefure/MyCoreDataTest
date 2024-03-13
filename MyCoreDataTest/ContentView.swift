//
//  ContentView.swift
//  MyCoreDataTest
//
//  Created by t&a on 2024/01/05.
//

import SwiftUI
import CoreData

struct ContentView: View {
    
    @State var persons: Array<Person> = []
    
    @State var companys: Array<Company> = []
    
    @State var selectTab = 0
    
    var body: some View {
        
        TabView(selection: $selectTab) {
            List {
                Button {
//                    DispatchQueue.global(qos: .background).async {
                        addPerson()
//                    }
                } label: {
                    Label("Add Item Person", systemImage: "plus")
                }
                
                ForEach(companys, id: \.self) { item in
                    HStack {
                        if let name = item.id?.uuidString {
                            Text(name)
                        } else if item.name == "" {
                            Text("NOne")
                        } else {
                            Text("nil")
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }.tag(0)
            
            
            List {
                Button {
//                    DispatchQueue.global(qos: .background).async {
                        addCompany()
//                    }
                    
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
                ForEach(companys, id: \.self) { item in
                    HStack {
                        Text(item.name ?? "")
                        Text("\(item.location ?? "")")
                        Text("\(item.person!.count)")
                    }
                }
            }.tag(1)
            
        }.onAppear {
//            DispatchQueue.global(qos: .background).async {
                CoreDataRepository2.shared.fetch(onBackgroundThread: true) { (result: [Person]) in
                    persons = result
                }
                CoreDataRepository2.shared.fetch(onBackgroundThread: true) { (result: [Company]) in
                    print(companys)
                    companys = result
                }
//            }
        }
    }
    
    private func addPerson() {
        CoreDataRepository2.shared.newEntity(onBackgroundThread: true) { (newCompany: Company) in
            // 新しいエンティティにデータを設定
            newCompany.id = UUID()
            newCompany.name = "Web制作会社"
            newCompany.location = "東京都"
            
            // 新しいエンティティを保存
            CoreDataRepository2.shared.insert(newCompany, onBackgroundThread: true)
            
            CoreDataRepository2.shared.fetch(onBackgroundThread: true) { (result: [Company]) in
                companys = result
            }
        }

            
        
    }
    
    private func addCompany() {
//        withAnimation {
//            let newCompany: Company = CoreDataRepository2.shared.newEntity()
//            newCompany.id = UUID()
//            newCompany.name = "ABCデザイン"
//            newCompany.location = "東京都"
//            
//            CoreDataRepository2.shared.insert(newCompany)
//            
//            companys = CoreDataRepository2.shared.fetch()
//        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        
    }
}

#Preview {
    ContentView()
}
