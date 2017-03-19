# CoreDataHelper
CoreDataHelper is a tiny Swift Framework that helps you to easily manage CoreData objects in the main context.

## Why?
I love CoreData. I use it in almost 99.9% of my iOS projects but one day, I was tired of writing tons of code each time I wanted to create, fetch or delete a single entity. I know that there are thousands of libraries to wrap CoreData but I wanted to create mine. Not because I wanted to be famous (and I won't be for sure) but because it was for me a very good opportunity to dive deep in this very interesting and powerfull framework.

On top of that, I know that a lot of Apple Developers are scared of using CoreData when they read the documentation for the first time. I was one of them.

By creating CoreDataHelper, I wanted to have something human readable and nicer to code and look.

## When should I use it?
As long as your project is using CoreData, you can include CoreDataHelper! 

## Examples
### Create a new entity
```swift
let user: User = User.new()
// OR
let user: User = User.new([
  "firstName": "John",
  "lastName": "Doe"
])
```

### Save this entity
```swift
user.save()
```

### Delete this entity
```swift
user.destroy()
```

### Find one or more entity(ies)
#### Getting all
Here is the most basic requests you can do:
```swift
let users: [User] = User.findAll.exec()
```
#### Getting one
```swift
let user: User? = User.findOne.where("firstName").isEqual(to: "John").exec()
```
#### Adding sort and limit
```swift
let users: [User] = User
                    .findAll
                    .where("id")
                    .isGreater(than: 10)
                    .sort(by: "id")
                    .limit(10)
                    .exec()
```
#### Asynchronous fetch
```swift
User.findAll.exec { (users) in
  // do some stuff
}
```

## Installation

To install this, simply add the `.xcodeproj` to your project, and do not forget to link the `.framework`.

If you're using cocoapods, just add `pod 'CoreDataHelper'` into your `Podfile` file.

Whenever you want to use it in your code, simply type :
```swift
import CoreDataHelper
```

## Getting started

Using CoreDataHelper is pretty simple because you have (almost) nothing to do. You can leave the library taking care of your CoreData stack or initialize it with your own context by adding the following code in your `AppDelegate.swift`:
```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

  CDHelper.initialize(withContext: self.persistentContainer.viewContext)
  
  return true
}
```

## Create your first entity class
Let's create an entity named `User` which contains 4 properties :
- id          (Integer)
- first_name  (String)
- last_name   (String)
- email       (String)

Once you created the class `User` which inherit of `NSManagedObject`, the only thing you have to do is to add the `CDHelperEntity` protocol like that:
```swift
class User: NSManagedObject, CDHelperEntity {
  // ...
}
```

And here you are ready to use all the features of CoreDataHelper!

### What's under the hood?
CoreDataHelper uses the class name to figure out the entity name because that's almost always the case. If your class doesn't the same name as your enity, you can this property to your `NSManagedObject` subclass:

```swift
static var entityName: String { return "YourEntityName" }
```

But keep in mind that this practice should remains occasional and is strongly discouraged.

## Try it yourself!
Because CoreDataHelper has been made to be intuitive, no documentation should be required right? Of course, I'm just kidding, I will start to write the documentation as soon as possible but until then, you can try it yourself!

There is just one VERY important thing to have in mind when you use CoreDataHelper: **Be logical**.

For example, don't try to fecth or delete an entity which has not been created. It doesn't make sense.

Same thing when you write your find request.
```swift
// WRONG
User.findAll.and("lastName").isEqual(to: "Doe").exec()
```

Does the sentence _"Find me all entities and name is equal to 'Doe'"_ make any sense to you? Hum, not really I guess.

When you're writing a fetch request, just ask yourself _"What do I want?"_. For example _"I want all the users where the first name is equal to 'John' and the id is greater than 42."_

All right, let's ask CoreDataHelper about that:
```swift
// GOOD
User.findAll.where("firstName").isEqual(to: "John").and("id").isGreater(than: 42).exec()
```

Enjoy CoreDataHelper! 🍾
