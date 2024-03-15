//
//  ContentView.swift
//  MyCoreDataTest
//
//  Created by t&a on 2024/01/05.
//

import SwiftUI
import CoreData

// TODO: -
/// バックグラウンドでのUpdate
// TODO: -
struct ContentView: View {
    
    @State private var companys: Array<Company> = []
    
    var body: some View {
        
        List {
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
                CoreDataRepository.shared.fetch { (result: [Company]) in
                    companys = result
                }
            }
        }
    }
    
    private func addCompany() {
        // この形式だとidプロパティを変更時にスレッド違反でクラッシュしてしまう
        // 明示的にスレッドを指定すればすり抜けるがsaveContext > context.hasChanges で
        // 「EXC_BREAKPOINT (code=1, subcode=0x1863133d4)」 になる
        // let newCompany: Company = CoreDataRepository.shared.newEntity(onBackgroundThread: true)
        // newCompany.id = UUID()
        
        CoreDataRepository.shared.newEntity(onBackgroundThread: true) { (newCompany: Company) in
            // 新しいエンティティにデータを設定
            newCompany.id = UUID()
            newCompany.name = DateFormatUtility().getString(date: Date())
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
        guard let id = companys[safe: index]?.id else { return }
        let predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let company: Company = CoreDataRepository.shared.fetchSingle(predicate: predicate)
        company.name = DateFormatUtility().getString(date: Date())
        CoreDataRepository.shared.update(onBackgroundThread: false)
        
        CoreDataRepository.shared.fetch { (result: [Company]) in
            companys = result
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let companyToDelete = companys[index]
            CoreDataRepository.shared.delete(companyToDelete)
        }
        
        CoreDataRepository.shared.fetch { (result: [Company]) in
            companys = result
        }
    }
}

#Preview {
    ContentView()
}
