//
//  ContentView.swift
//  MyCoreDataTest
//
//  Created by t&a on 2024/01/05.
//

import SwiftUI
import CoreData

struct MulchListView: View {
    
    private let repository = MulchCoreDataRepository.shared
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
            // (1) メインスレッドでのUI反映はこれ
            // companys = repository.fetch()
            
            
            DispatchQueue(label: "com.amefure.queue", qos: .background).async {
                // (2) バックグラウンドスレッドでのUI反映はこれ
                companys = repository.fetchBG()
                
                // BGでこの形式ではプロパティがnullになる(BGContext & perform)
                // repository.fetchBGNone { (result: [Company]) in
                //    companys = result
                // }
                
                // BGでこの形式はクラッシュする(mainContext & perform未使用メソッド)
                // companys = repository.fetch()
            }
        }
    }
    
    private func addCompany() {
        // この形式だとidプロパティを変更時にスレッド違反でクラッシュしてしまう
        // 明示的にスレッドを指定すればすり抜けるがsaveContext > context.hasChanges で
        // 「EXC_BREAKPOINT (code=1, subcode=0x1863133d4)」 になる
        // performAndWaitで取得したものは変更できない？
        // -------------------------------------------------------------------------
        // let newCompany: Company = repository.newEntity(onBackgroundThread: true)
        // newCompany.id = UUID()
        
        // onBackgroundThreadをtrueにしなくてもクラッシュしない？
        repository.newEntity(onBackgroundThread: true) { (newCompany: Company) in
            // 新しいエンティティにデータを設定
            newCompany.id = UUID()
            newCompany.name = DateFormatUtility().getString(date: Date())
            newCompany.location = "東京都"
            
            // 新しいエンティティを保存
            repository.insert(newCompany)
            
            companys = repository.fetchBG()
        }
    }
    
    private func updateCompany(index: Int) {
        // insert同様にこの形式だとidプロパティを参照時にスレッド違反でクラッシュしてしまう
        // performAndWaitで取得したものは変更できない？
        // -------------------------------------------------------------------------
        //  let result: [Company] = repository.fetchBG()
        // guard let id = result[safe: index]?.id else { return }
        
        // また MulchListView > companysをそのまま参照しようとしてもクラッシュするので注意
        
        // 完了ハンドラー形式なら問題なく実装可能
        repository.fetchBG { (result: [Company]) in
            guard let id = result[safe: index]?.id else { return }
            let predicate = NSPredicate(format: "id == %@", id as CVarArg)
            let company: Company = repository.fetchSingle(predicate: predicate)
            company.name = DateFormatUtility().getString(date: Date())
            // fetchしているContextに合わせたContextでupdate処理を実行しなければいけないので注意
            repository.update(company)

            // ここでそのまま更新してもUIは反映されないため明示的にリセット
            companys = []
            companys = repository.fetchBG()
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let companyToDelete = companys[index]
            repository.delete(companyToDelete)
        }
        
        companys = repository.fetchBG()
    }
}

#Preview {
    MulchListView()
}
