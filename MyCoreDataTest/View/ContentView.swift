//
//  ContentView.swift
//  MyCoreDataTest
//
//  Created by t&a on 2024/01/05.
//

import SwiftUI
import CoreData

struct ContentView: View {
    
    @State private var name: String = ""
    @State private var companys: Array<Company> = []
    
    var body: some View {
        
        List {
            
            TextField("Input", text: $name)
            
            Button {
                DispatchQueue(label: "com.amefure.queue", qos: .background).async {
                    addCompany()
                }
            } label: {
                Label("Add Item Company", systemImage: "plus")
            }
            
            Button {
//                DispatchQueue(label: "com.amefure.queue", qos: .background).async {
                    updateCompany(index: 0)
//                }
            } label: {
                Label("Update Company", systemImage: "plus")
            }
            
            ForEach(companys, id: \.self) { item in
                HStack {
                    Text(item.name ?? "none")
                }
            }
            .onDelete(perform: deleteItems)
            
        }.onAppear {
            DispatchQueue(label: "com.amefure.queue", qos: .background).async {
                companys = CoreDataRepository.shared.fetch()
            }
        }
    }
    
    private func addCompany() {
        guard !name.isEmpty else { return }
        //        let newCompany: Company = CoreDataRepository.shared.newEntity(onBackgroundThread: true)
        //        // エンティティをバックグラウンドスレッドで生成したので、そのスレッドでデータを設定する
        //
        //        print("---------------Company",Thread.current)
        //        newCompany.id = UUID()
        //        newCompany.name = name
        //        newCompany.location = "東京都"
        //
        //        // 新しいエンティティを保存
        //        CoreDataRepository.shared.insert(newCompany, onBackgroundThread: true)
        //
        //        CoreDataRepository.shared.fetch { (result: [Company]) in
        //            companys = result
        //        }
        
        CoreDataRepository.shared.newEntity(onBackgroundThread: true) { (newCompany: Company) in
            // 新しいエンティティにデータを設定
            newCompany.id = UUID()
            newCompany.name = name
            newCompany.location = "東京都"
            
            // 新しいエンティティを保存
            CoreDataRepository.shared.insert(newCompany, onBackgroundThread: true)
            
            CoreDataRepository.shared.fetch { (result: [Company]) in
                companys = result
            }
        }
    }
    
    /// バックグラウンドでアップデートできない？
    private func updateCompany(index: Int) {
        guard let company = companys[safe: index] else { return }
        let predicate = NSPredicate(format: "id == %@", company.id! as CVarArg)
        CoreDataRepository.shared.fetchSingle(predicate: predicate) { (company: Company?) in
            guard let company = company else { return }
            company.name = String(Date().timeIntervalSince1970)
            CoreDataRepository.shared.update(onBackgroundThread: false)
            
            companys = CoreDataRepository.shared.fetch()
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let companyToDelete = companys[index]
            CoreDataRepository.shared.delete(companyToDelete)
        }
        companys = CoreDataRepository.shared.fetch()
    }
}

#Preview {
    ContentView()
}
