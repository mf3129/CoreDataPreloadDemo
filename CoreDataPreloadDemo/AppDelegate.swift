//
//  AppDelegate.swift
//  CoreDataPreloadDemo
//
//  Created by Makan Fofana
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let defaults = UserDefaults.standard
        let isPreloaded = defaults.bool(forKey: "isPreloaded")
        if !isPreloaded {
            preloadData()
            defaults.set(true, forKey: "isPreloaded")
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "CoreDataPreloadDemo")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}


//Method for parsing CSV file

extension AppDelegate {
    
    func parseCSV(contentsOfURL: URL, encoding: String.Encoding) -> [(name: String, detail: String, price: String)]? {
        
        //Load the CSV file and parse it
        let delimeter = ","
        var items: [(name: String, detail: String, price: String)]?
        
        do {
            let content = try String(contentsOf: contentsOfURL, encoding: encoding)
            
            items = []
            let lines: [String] = content.components(separatedBy: .newlines)
            
            for line in lines {
                var values: [String] = []
                if line != "" {
                    //For a line with double quotes
                    //we use NS Scanner to perfrom the parsing
                    if line.range(of: "\"") != nil {
                        var textToScan: String = line
                        var value: NSString?
                        var textScanner: Scanner = Scanner(string: textToScan)
                        while textScanner.string != "" {
                            
                            if (textScanner.string as NSString).substring(to: 1) == "\"" {
                            textScanner.scanLocation += 1
                            textScanner.scanUpTo("\"", into: &value)
                            textScanner.scanLocation += 1
                            }
                            else {
                            textScanner.scanUpTo(delimeter, into: &value)
                        }
                            
                        //Store the value into an array
                            if let value = value {
                                values.append(value as String)
                            }
                            //Retrieve the unscanned remainder of the string
                            if textScanner.scanLocation < textScanner.string.count {
                                textToScan = (textScanner.string as NSString).substring(from: textScanner.scanLocation + 1)
                            } else {
                                textToScan = ""
                            }
                            textScanner = Scanner(string: textToScan)
                            
                        }
                }
                else {
                    values = line.components(separatedBy: delimeter)
                    }
                
                    let item = (name: values[0], detail: values[1], price: values[2])
                    
                    items?.append(item)
            }
        }
        } catch {
            print(error)
        }
        return items
  }
    
    
    
    //MARK: Preloading data
    func preloadData() {
        //Loading data file and if unable we just return
        guard let contentsOfURL = Bundle.main.url(forResource: "menudata", withExtension: "csv") else {
            return
        }
        
        //Remove all the menu items before preloading
        removeData()
        
        //Parse the CSV file and import the data
        if let items = parseCSV(contentsOfURL: contentsOfURL, encoding: String.Encoding.utf8) {
        
            let context = persistentContainer.viewContext
            
            for item in items {
                let menuItem = MenuItem(context: context)
                menuItem.name = item.name
                menuItem.detail = item.detail
                menuItem.price = Double(item.price) ?? 0.0
                
                do {
                    try context.save()
                } catch {
                    print(error)
                }
            }
       }
   }
    
    
    
    //MARK: Remove Data
    func removeData() {
        //Remove the existing items
        let fetchRequest = NSFetchRequest<MenuItem>(entityName: "MenuItem")
        let context = persistentContainer.viewContext
        
        do {
            let menuItems = try context.fetch(fetchRequest)
            
            for menuItem in menuItems {
                context.delete(menuItem)
            }
            
            saveContext()
        }
        catch {
            print(error)
        }
    }



    
}

