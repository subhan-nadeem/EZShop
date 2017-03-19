#AlamofireSwiftyJSON
[![Build Status](https://travis-ci.org/starboychina/AlamofireSwiftyJSON.svg)](https://travis-ci.org/starboychina/AlamofireSwiftyJSON)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![SwiftLint](https://img.shields.io/badge/SwiftLint-passing-brightgreen.svg)](https://github.com/realm/SwiftLint)
[![codecov.io](https://codecov.io/github/starboychina/AlamofireSwiftyJSON/coverage.svg?branch=master)](https://codecov.io/gh/starboychina/AlamofireSwiftyJSON?branch=master)
[![GitHub release](https://img.shields.io/github/release/starboychina/AlamofireSwiftyJSON.svg)](https://github.com/starboychina/AlamofireSwiftyJSON/releases)

---
Easy way to use both [Alamofire](https://github.com/Alamofire/Alamofire) and [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)

## Requirements

- iOS 8.0+ / Mac OS X 10.9+
- Xcode 7.0

## Install

- CocoaPods

```swift
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

target "target name" do
  pod 'AlamofireSwiftyJSON'
end

```

- [Carthage](https://github.com/Carthage/Carthage)

```swift
github "starboychina/AlamofireSwiftyJSON"
```

## Usage

```swift
let URL = "http://httpbin.org/get"
Alamofire.request(.GET, URL, parameters: ["foo": "bar"]).responseSwiftyJSON { response in
  print("###Success: \(response.result.isSuccess)")
  //now response.result.value is SwiftyJSON.JSON type
  print("###Value: \(response.result.value?["args"].array)")
}

```
