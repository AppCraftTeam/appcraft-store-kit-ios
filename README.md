# ACStorekit

[![Swift](https://img.shields.io/badge/Swift-5-orange?style=flat-square)](https://img.shields.io/badge/Swift-5-Orange?style=flat-square)
[![Platforms](https://img.shields.io/badge/Platforms-iOS-yellowgreen?style=flat-square)](https://img.shields.io/badge/Platforms-iOS?style=flat-square)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)
[![version](https://img.shields.io/badge/version-1.0.1-white.svg)](https://semver.org)

## Requirements
- Xcode 13 and later
- iOS 11 and later
- Swift 5.0 and later

## Overview
* [Demo](#demo)
* [Install](#install)

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

## Список продуктов

Для начала работы создайте список продуктов, соответствующий классу `ACProduct`:

```swift
class ACProduct {
  init(
    productIdentifer: String,
    name: String,
    description: String,
    sortIndex: Int)
}
```

Для удобства в разработке список продуктов можно хранить в enum, тогда ваш enum должен соответствовать протоколу `ACProductType`, например так:

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

## Инициализация ACPurchaseService

Основной класс, выполняющий получение списка продукта из App Store, процесс покупки, восстановления и т.д - ACPurchaseService

```swift
class ACPurchaseService {
    products: Set<ACProductTypeItem>,
    sharedSecretKey: String,
    logLevel: ACLogLevel
}
```

Получение списка продуктов
```swift
purchaseService.loadProducts()
```

## Handlers

```swift
purchaseService.setupCallbacks(
  didUpdateProductsList: { result in
		<Обработка Result со списком продуктов или ошибки>
  },
  didCompletePurchase: { result in
		<Обработка Result со списком купленных продуктов или ошибки>
  },
  didRestorePurchases: { result in
		<Обработка Result со списком восстановленных продуктов или ошибки>
  }
)
```

```swift
```

```swift
```

```swift
```

```swift
```

```swift
```

```swift
```

```swift
```

```swift
```

```swift
```

```swift
```

```swift
```

```swift
```

```swift
```


## License
This library is licensed under the MIT License.

## Author
Email: <dmitriyap11@gmail.com><br>
Email: <moslienko.p@gmail.com>