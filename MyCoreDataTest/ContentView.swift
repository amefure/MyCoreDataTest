//
//  ContentView.swift
//  MyCoreDataTest
//
//  Created by t&a on 2024/01/05.
//

import SwiftUI
import CoreData

struct ContentView: View {
    
    @State private var companys: Array<Company> = []
    
    var body: some View {
        
        List {
            Button {
                DispatchQueue.global(qos: .background).async {
                    addCompany()
                }
            } label: {
                Label("Add Item Company", systemImage: "plus")
            }
            
            ForEach(companys, id: \.self) { item in
                HStack {
                    Text(item.name ?? "")
                }
            }
            .onDelete(perform: deleteItems)
            
        }.onAppear {
            DispatchQueue.global(qos: .background).async {
                CoreDataRepository.shared.fetch { (result: [Company]) in
                    print(companys)
                    companys = result
                }
            }
        }
    }
    
    private func addCompany() {
        CoreDataRepository.shared.newEntity(onBackgroundThread: true) { (newCompany: Company) in
            // 新しいエンティティにデータを設定
            newCompany.id = UUID()
            newCompany.name = "Web制作会社"
            newCompany.location = "東京都"
            
            // 新しいエンティティを保存
            CoreDataRepository.shared.insert(newCompany, onBackgroundThread: true)
            
            CoreDataRepository.shared.fetch { (result: [Company]) in
                companys = result
            }
        }
    }
    
    
    func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let companyToDelete = companys[index]
            CoreDataRepository.shared.delete(companyToDelete, onBackgroundThread: false)
        }
    }

}

#Preview {
    ContentView()
}
