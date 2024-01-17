# [1.5.0]
* Adds [retries] to retry connection to server [retries] times before setting connection as false. Defaults to 0.

# [1.4.0]
* Added the [timeoutDuration] parameter

# [1.3.0]
* When doing a `[isPhoneConnected]`, we add values to the stream

# [1.2.0]
* By default, we show a loading indicator instead of assuming we have no internet connection

# [1.1.0]
* Fixes library tests
* Adds [child] as a required parameter
* Correctly dispose of resources

# [1.0.0]
* Null safety migration
* Replaces `simple_connectivity` with `connectivity_plus`
* Connection stream now only outputs distinct values
* Removes the `ConnectivityBloc`
* Rewrites `ConnectivityUtils`
* adds Github Actions
* adds tests
* fixes misc bugs

# [0.1.8]
* Updates http dependency, via [#26](https://github.com/Vanethos/flutter_connectivity_widget/pull/26), thanks to jezer07 
# [0.1.7]
* Set default `serverToPing` and `callback` values if set to null via [#19](https://github.com/Vanethos/flutter_connectivity_widget/pull/19)

# [0.1.6]
* Changed the default connectivity URL via [#13](https://github.com/Vanethos/flutter_connectivity_widget/pull/15)
* Updated RxDart version via [15](https://github.com/Vanethos/flutter_connectivity_widget/pull/13)

# [0.1.5]
* Added `ConnectivityUtils.initialize` to initialize with the `serverToPing` and `callback`, so that the first time 
we check the internet access we ping the correct server and use the provided callback

## [0.1.4+1]
* Update dependencies

## [0.1.4]
* Change implementation from connectivity to simple_connectivity so that location-aware `Info-plist`
strings are no longer required

## [0.1.3]
* Fix Dio dependency still present in repo
* Change example

## [0.1.2]
* Update example
* Remove Dio from dependencies 

## [0.1.1] 
* Banner is invisible when there is no connection
* Fixed issue of banner not showing when starting the app in offline mode

## [0.1.0+1]

* Update RxDart Version

## [0.1.0]

* Initial Release
