// 
//  CoreDataManager.swift
//  Precious Time
//
//  Created by Rahardyan Bisma on 31/01/23.
//  

import Foundation
import CoreData

final class CoreDataManager: NSPersistentContainer {
    static let shared = CoreDataManager(name: "PreciousTimeDataModel")
    
    private(set) lazy var privateContext: NSManagedObjectContext = {
        let context = newBackgroundContext()
        context.name = "background_context"
        context.transactionAuthor = "coredatamanager_background_context"
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        
        return context
    }()
    
    func setup() {
        loadPersistentStores { _, error in
            print("load persistent stores error \(String(describing: error?.localizedDescription))")
        }
    }
    
    func saveChangesInBackground() {
        DispatchQueue.global().async {
            self.privateContext.perform { [weak self] in
                if self?.privateContext.hasChanges ?? false {
                    do {
                        try self?.privateContext.save()
                    } catch {
                        print("failed to save changes in background \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func saveChangesInMain() {
        DispatchQueue.main.async {
            self.viewContext.perform { [weak self] in
                if self?.viewContext.hasChanges ?? false {
                    do {
                        try self?.viewContext.save()
                    } catch {
                        print("failed to save changes in main \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
}



