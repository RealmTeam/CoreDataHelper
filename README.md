# CoreDataHelper

CoreDataHelper is a tiny Swift Framework that helps you to easily manage CoreData objects in the main context.

## Installation

To install this, simply add the `.xcodeproj` to your project, and do not forget to link the `.framework`.


If you're using cocoapods, just add `pod 'CoreDataHelper'` into your `Podfile` file.


Whenever you want to use it in your code, simply type :
```swift
import CoreDataHelper
```

## Getting started

To start with CoreDataHelper, it is pretty simple. Just go to your `AppDelegate.swift` file and add the following code :
```swift
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

  CDHelper.initializeWithMainContext(self.managedObjectContext)
  
  return true
}
```

Note that your project must use CoreData.

## Create your first entity class

Let's create an entity named `User` which contains 4 properties :
- first_name (String)
- last_name (String)
- email (String)
- age (Integer)

Once you created the class `User` which inherit of `NSManagedObject`, just add the `CDHelperEntity` protocol like that :
```swift
class User: NSManagedObject, CDHelperEntity {
    
  static var entityName: String! { return "User" } // Required
    
  @NSManaged var first_name: String?
  @NSManaged var age: NSNumber?
  @NSManaged var email: String?
  @NSManaged var last_name: String?
}
```

You just need to add the `entityName` variable to be conform with the `CDHelperEntity` protocol and that's it ! You're ready to use all the features of _CoreDataHelper_ !

## Play with your entity

### Create a new entity

There are two ways to create a new entity.
First, you can create an empty entity and fill it after :
```swift
let user: User = User.new()
user.first_name = "John"
user.last_name = "Doe"
user.email = "john.doe@foobar.com"
user.age = 42
```

You can also create an entity using a data dictionary :
```swift
let userData: [String: AnyObject?] = [
  "first_name": "John",
  "last_name": "Doe",
  "email": "john.doe@foobar.com",
  "age": 42,
]

let user: User = User.new(userData)
```

### Save your entity
To save your entity, simply use the `.save()` method like that :
```swift
let user: User = User.new()
// ...
user.save()
```

### Delete your entity
If you don't need your entity anymore, you can use the `.destroy()` method :
```swift
let user: User = User.new()
// ...
user.save()

// ... Ok, let's admit you want to delete your user
user.destroy()
```

### Retrieve your entities
There are different ways to retrieve your entities.

#### Synchronously
##### findAll()
- Basic use
```swift
let users: [User] = User.findAll()
```
- Using sort descriptor(s)
```swift
let users: [User] = User.findAll(usingSortDescriptors: [NSSortDescriptor(key: "first_name", ascending: true)])
```

##### findOne()
```swift
let user: User? = User.findOne("first_name=\"John\"")
```

##### find()
- Basic use
```swift
let users: [User] = User.find("first_name=\"John\"")
```
- Using sort descriptor(s)
```swift
let users: [User] = User.find("first_name=\"John\"", usingSortDescriptors: [NSSortDescriptor(key: "first_name", ascending: true)])
```
- Using fetch limit
```swift
let users: [User] = User.find("first_name=\"John\"", limit: 5)
```
- Using both
```swift
let users: [User] = User.find("first_name=\"John\"", usingSortDescriptors: [NSSortDescriptor(key: "first_name", ascending: true)], limit: 5)
```

#### Asynchronously
##### asynchronouslyFindAll()
- Basic use
```swift
User.asynchronouslyFindAll { (results: [User]) -> Void in
  // ...
}
```
- Using sort descriptor(s)
```swift
User.asynchronouslyFindAll(usingSortDescriptors: [NSSortDescriptor(key: "first_name", ascending: true)]) { (results: [User]) -> Void in
  // ...
}
```

##### asynchronouslyFindOne()
```swift
User.asynchronouslyFindOne("first_name=\"John\"") { (user: User?) -> Void in
  // ...
}
```

##### asynchronouslyFind()
- Basic use
```swift
User.asynchronouslyFind("first_name=\"John\"") { (user: [User]) -> Void in
  // ...
}
```
- Using sort descriptor(s)
```swift
User.asynchronouslyFind("first_name=\"John\"", usingSortDescriptors: [NSSortDescriptor(key: "first_name", ascending: true)]) { (user: [User]) -> Void in
  // ...
}
```
- Using fetch limit
```swift
User.asynchronouslyFind("first_name=\"John\"", limit: 5) { (user: [User]) -> Void in
  // ...
}
```
- Using both
```swift
User.asynchronouslyFind("first_name=\"John\"", usingSortDescriptors: [NSSortDescriptor(key: "first_name", ascending: true)], limit: 5) { (user: [User]) -> Void in
  // ...
}
```
