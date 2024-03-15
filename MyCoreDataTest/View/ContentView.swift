//
//  ContentView.swift
//  MyCoreDataTest
//
//  Created by t&a on 2024/01/05.
//

import SwiftUI
import CoreData

struct ContentView: View {
    
    private let repository = CoreDataRepository.shared
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
                DispatchQueue(label: "com.amefure.queue", qos: .background).async {
                    updateCompany(index: 0)
                }
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
                repository.fetch { (result: [Company]) in
                    companys = result
                }
            }
        }
    }
    
    private func addCompany() {
        // この形式だとidプロパティを変更時にスレッド違反でクラッシュしてしまう
        // 明示的にスレッドを指定すればすり抜けるがsaveContext > context.hasChanges で
        // 「EXC_BREAKPOINT (code=1, subcode=0x1863133d4)」 になる
        // let newCompany: Company = repository.newEntity(onBackgroundThread: true)
        // newCompany.id = UUID()
        
        repository.newEntity() { (newCompany: Company) in
            // 新しいエンティティにデータを設定
            newCompany.id = UUID()
            newCompany.name = DateFormatUtility().getString(date: Date())
            newCompany.location = "東京都"
            
            // 新しいエンティティを保存
            repository.insert(newCompany, onBackgroundThread: true)
            
            repository.fetch { (result: [Company]) in
                companys = result
            }
        }
    }
    
    private func updateCompany(index: Int) {
        // バックグラウンドスレッドからContentView > companysオブジェクトを参照した時点でクラッシュする
        // そのためバックグラウンドスレッドでデータを取得して参照
        repository.fetch { (result: [Company]) in
            guard let id = result[safe: index]?.id else { return }
            let predicate = NSPredicate(format: "id == %@", id as CVarArg)
            let company: Company = repository.fetchSingle(predicate: predicate)
            company.name = DateFormatUtility().getString(date: Date())
            repository.update(onBackgroundThread: false)
            
            repository.fetch { (result: [Company]) in
                // ここで更新してもUIは反映されない(メイン/バックグラウンドでも)
                companys = result
            }
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let companyToDelete = companys[index]
            repository.delete(companyToDelete)
        }
        
        repository.fetch { (result: [Company]) in
            companys = result
        }
    }
}

#Preview {
    ContentView()
}
