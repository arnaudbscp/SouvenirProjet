//
//  SouvenirCree.swift
//  SouvenirProjet
//
//  Created by Arnaud Bascop on 11/04/2020.
//  Copyright © 2020 Arnaud Bascop. All rights reserved.
//

import CoreData

class SouvenirCree: NSManagedObject {
    static var all: [SouvenirCree] {
        let request: NSFetchRequest<SouvenirCree> = SouvenirCree.fetchRequest()
        guard let souvs = try? AppDelegate.viewContext.fetch(request) else { return [] }
        return souvs
    }
}
