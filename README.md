# Easy app
Easy is an unofficial [Medium](https://medium.com/) broswer that makes it... easy to find posts you're interested in.
## Screenshots
![Easy](https://github.com/enzosv/easy-ios/blob/master/Screenshots/easy.png)
## Features
* View claps and recommendations before reading post
* Hide premium posts
* Hide posts you're not interested in
* View only topics/tags you're interested in*
    *Right now, this only fetches posts so topics and tags will populate as the app becomes aware of more posts and their accompanying topics and tags
* View and organize read posts by date or "upvotes"
## This is unofficial
* This won't be published to the AppStore
* This can break at anytime if Medium decides to change things
* This does not sync to your Medium account
## Running
```shell
git clone https://github.com/enzosv/easy-ios.git && cd easy-ios
pod install
open easy.xcworkspace
```
## Credits
Inspired by [Top Medium Stories](https://topmediumstories.com/)
### Libraries used
* [Alamofire](https://github.com/Alamofire/Alamofire) ([MIT](https://raw.githubusercontent.com/Alamofire/Alamofire/master/LICENSE))
* [RealmSwift](https://realm.io/docs/swift/latest/) ([Apache](https://github.com/realm/realm-cocoa/master/LICENSE))
* [SwiftLint](https://github.com/realm/SwiftLint) ([MIT](https://github.com/realm/SwiftLint/master/LICENSE))
* [PromiseKit](https://github.com/mxcl/PromiseKit) ([MIT](https://raw.githubusercontent.com/mxcl/PromiseKit/master/LICENSE))
* [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) ([MIT](https://raw.githubusercontent.com/SwiftyJSON/SwiftyJSON/master/LICENSE))
* [SwiftyUserDefaults](https://github.com/radex/SwiftyUserDefaults) ([MIT](https://raw.githubusercontent.com/radex/SwiftyUserDefaults/master/LICENSE))
* [SnapKit](https://github.com/SnapKit/SnapKit) ([MIT](https://raw.githubusercontent.com/SnapKit/SnapKit/develop/LICENSE))
* [ESPullToRefresh](https://github.com/eggswift/pull-to-refresh) ([MIT](https://raw.githubusercontent.com/eggswift/pull-to-refresh/master/LICENSE))
* [DifferenceKit](https://github.com/ra1028/DifferenceKit) ([MIT](https://raw.githubusercontent.com/ra1028/DifferenceKit/master/LICENSE))
