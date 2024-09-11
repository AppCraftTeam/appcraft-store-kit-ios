# ACStorekit

[![Swift](https://img.shields.io/badge/Swift-5-orange?style=flat-square)](https://img.shields.io/badge/Swift-5-Orange?style=flat-square)
[![Platforms](https://img.shields.io/badge/Platforms-iOS-yellowgreen?style=flat-square)](https://img.shields.io/badge/Platforms-iOS?style=flat-square)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)
[![version](https://img.shields.io/badge/version-1.0.0-white.svg)](https://semver.org)

## Requirements
- Xcode 13 and later
- iOS 12 and later
- Swift 5.0 and later

## Overview
* [Demo](#demo)
* [Install](#install)
* [Products](#Products)
	* [List of products](#list-of-products)
	* [Retrieving from App Store](#retrieving-a-list-of-products-from-app-store)
* [Basic usage](#basic-usage)
	* [Handlers](#handlers)
	* [Purchase](#purchase)
	* [Restore purchases](#restore-purchases)
* [Recipe](#validation-and-retrieving-a-recipe)
* [License](#License)

## Demo

All these examples, as well as the integration of the `ACStorekit` module into the application, can be seen in action in the [Demo project](/Demo).

## Install
To install this Swift package into your project, follow these steps:

1. Open your Xcode project.
2. Go to "File" > "Swift Packages" > "Add Package Dependency".
3. In the "Choose Package Repository" dialog, enter `https://github.com/AppCraftTeam/appcraft-store-kit-ios.git`.
4. Click "Next" and select the version you want to use.
5. Choose the target where you want to add the package and click "Finish".

Xcode will then resolve the package and add it to your project. You can now import and use the package in your code.

## Products
### List of products

To store the list of products, it is necessary to create an object conforming to the `ACProduct` class:

```swift
class ACProduct {
  init(
    productIdentifer: String,
    name: String,
    description: String,
    sortIndex: Int)
}
```

For ease of development, the list of products can be stored in an enum, then your enum must match the `ACProductType` protocol, for example like this:

```swift
enum AppPurchases: String, ACProductType {
  case month = "subscription.month"
  case year = "subscription.year"

  public var product: ACProduct {
    return ACProduct(
        productIdentifer: self.rawValue,
        name: <String>,
        description: <String>,
        sortIndex: <Int>
      )
  }
}

```

### Retrieving a list of products from App Store

Create an [`ACPurchaseService`](#basic-usage) object and call to fetch the product list:

```swift
purchaseService.loadProducts()
```

## Basic usage

The main class that performs the product listing retrieval from the App Store, the process of purchasing, restoring, etc - `ACPurchaseService`.

```swift
class ACPurchaseService {
    products: Set<ACProductTypeItem>,
    sharedSecretKey: String,
    logLevel: ACLogLevel
}
```

## Handlers
`setupCallbacks()` method is used to handle the processing of all events.

```swift
purchaseService.setupCallbacks(
  didUpdateProductsList: { result in
	// Result processing with a list of products or errors
  },
  didCompletePurchase: { result in
	// Result processing with a list of purchased products or errors
  },
  didRestorePurchases: { result in
	// Result processing with a list of recovered products or errors
  }
)
```

### Purchase

```swift
purchaseService.purchase(<SKProduct>)
```

Track the result of the execution in [Handlers](#handlers)

###  Restore purchases

```swift
purchaseService.restore()
```

Track the result of the execution in [Handlers](#handlers)

## Validation and retrieving a recipe

You need to pass the validation type. Validation via Apple is done by sending a rest request to Apple server, manually means that your own validation logic will be used, for example on your server.

```swift
enum ACReceiptValidationType {
  case manual
  case apple
}
```

```swift
 self.purchaseService.fetchReceipt(validationType: .manual) { result in }
```

If successful, a `ACReceiptProductInfo` model will be returned containing the recipe and validity data for active subscriptions (*in the case of validation via Apple*):

```swift
public struct ACReceiptProductInfo {
  var expiredInfo: Set<ACProductExpiredInfo>
  var receipt: Data
}
```

```swift
struct ACProductExpiredInfo {
  var productId: String
  var date: Date
}
```

## License
This library is licensed under the MIT License.

## Author
Email: <dmitriyap11@gmail.com><br>
Email: <moslienko.p@gmail.com>