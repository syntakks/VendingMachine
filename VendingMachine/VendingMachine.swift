//
//  VendingMachine.swift
//  VendingMachine
//
//  Created by Steve Wall on 2/3/20.
//  Copyright © 2020 Treehouse Island, Inc. All rights reserved.
//

import Foundation
import UIKit

enum VendingSelection: String {
    case soda
    case dietSoda
    case chips
    case cookie
    case sandwich
    case wrap
    case candyBar
    case popTart
    case water
    case fruitJuice
    case sportsDrink
    case gum
    
    func icon() -> UIImage {
        if let image = UIImage(named: self.rawValue) {
            return image
        } else {
            return #imageLiteral(resourceName: "default")
        }
    }
}

protocol VendingItem {
    var price: Double { get }
    var quantity: Int { get set }
}

protocol VendingMachine {
    var selection: [VendingSelection] { get }
    var inventory: [VendingSelection: VendingItem] { get set }
    var amountDeposited: Double { get set }
     
    init(inventory: [VendingSelection: VendingItem])
    func vend(selection: VendingSelection, quantity: Int) throws
    func deposit(_ aount: Double)
    func item(forSelection selection: VendingSelection) -> VendingItem?
}

struct Item: VendingItem {
    let price: Double
    var quantity: Int
}

enum InventoryError: Error {
    case invalidResource
    case conversionFailure
    case invalidSelection
}

class PlistConverter {
    static func dictionary(fromFile name: String, ofType type: String) throws -> [String: AnyObject] {
        // First get path of resource.
        guard let path = Bundle.main.path(forResource: name, ofType: type) else {
            throw InventoryError.invalidResource
        }
        //print(path)
        // Gets dictionary from file. Need to type cast.
        guard let dictionary = NSDictionary(contentsOfFile: path) as? [String : AnyObject] else {
            throw InventoryError.conversionFailure
        }
        //print (dictionary)
        return dictionary
    }
}

class InventoryUnarchiver {
    static func vendingInventory(fromDictionary: [String : AnyObject]) throws -> [VendingSelection : VendingItem]{
        var inventory: [VendingSelection : VendingItem] = [:]
        for (key, value) in fromDictionary {
            
            if let itemDictionary = value as? [String : Any],
                let price = itemDictionary["price"] as? Double,
                let quantity = itemDictionary["quantity"] as? Int {
                let item = Item(price: price, quantity: quantity)
                
                guard let selection = VendingSelection(rawValue: key) else {
                    throw InventoryError.invalidSelection
                }
                inventory.updateValue(item, forKey: selection)
            } else {
                print("InventoryUnarchiver: Could not get a valid [VendingSelection : VendingItem]")
            }
        }
        return inventory
    }
}

enum VendingMachineError: Error {
    case invalidSelection
    case outOfStock
    case insufficientFunds(required: Double)
}

class FoodVendingMachine: VendingMachine {
    let selection: [VendingSelection] = [
        .soda, .dietSoda, .chips, .cookie, .sandwich, .wrap, .candyBar, . popTart, .water, .fruitJuice, .sportsDrink, .gum
    ]
    var inventory: [VendingSelection : VendingItem]
    var amountDeposited: Double = 10.0
    
    required init(inventory: [VendingSelection : VendingItem]) {
        self.inventory = inventory
    }
    
    func vend(selection: VendingSelection, quantity: Int) throws {
        // Validate selection
        guard var item = inventory[selection] else {
            throw VendingMachineError.invalidSelection
        }
        // Validate Available quantity
        guard item.quantity >= quantity else {
            throw VendingMachineError.outOfStock
        }
        // Validate funds
        let totalPrice = item.price * Double(quantity)
        if amountDeposited >= totalPrice {
            // Vend Item
            amountDeposited -= totalPrice
            item.quantity -= quantity
            inventory.updateValue(item, forKey: selection)
        } else {
            // Insufficient Funds
            let amountRequired = totalPrice - amountDeposited
            throw VendingMachineError.insufficientFunds(required: amountRequired)
        }
    }
    
    func deposit(_ amount: Double) {
        amountDeposited += amount
    }
    
    func item(forSelection selection: VendingSelection) -> VendingItem? {
        return inventory[selection]
    }
}
