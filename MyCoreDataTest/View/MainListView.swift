//
//  MainListView.swift
//  MyCoreDataTest
//
//  Created by t&a on 2024/03/15.
//

import SwiftUI

struct MainListView: View {
    
    private let repository = MainCoreDataRepository.shared
    @State private var companys: Array<Company> = []
    
    var body: some View {
        
        List {
            Button {
                addCompany()
            } label: {
                Label("Add Item Company", systemImage: "plus")
            }
            
            Button {
                updateCompany(index: 0)
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
            companys = repository.fetch()
        }
    }
    
    private func addCompany() {
        let newCompany: Company = repository.newEntity()
        // 新しいエンティティにデータを設定
        newCompany.id = UUID()
        newCompany.name = DateFormatUtility().getString(date: Date())
        newCompany.location = "東京都"
        
        // 新しいエンティティを保存
        repository.insert(newCompany)
        
        companys = repository.fetch()
    }
    
    private func updateCompany(index: Int) {
        guard let id = companys[safe: index]?.id else { return }
        let predicate = NSPredicate(format: "id == %@", id as CVarArg)
        let company: Company = repository.fetchSingle(predicate: predicate)
        company.name = DateFormatUtility().getString(date: Date())
        
        companys = repository.fetch()
    }
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let companyToDelete = companys[index]
            repository.delete(companyToDelete)
        }
        
        companys = repository.fetch()
    }
}


#Preview {
    MainListView()
}
