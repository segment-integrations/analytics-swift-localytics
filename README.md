# Analytics-Swift Localytics

Add `Localytics` Device Mode support to your applications via this plugin for [Analytics-Swift](https://github.com/segmentio/analytics-swift)

⚠️ **Github Issues disabled in this repository** ⚠️

Please direct all issues, bug reports, and feature enhancements to `friends@segment.com` so they can be resolved as efficiently as possible. 

## Adding the dependency

***Note:*** the `Localytics` library itself will be installed as an additional dependency.

### via Xcode
In the Xcode `File` menu, click `Add Packages`.  You'll see a dialog where you can search for Swift packages.  In the search field, enter the URL for this repo:

```
https://github.com/segment-integrations/analytics-swift-localytics
```

You'll then have the option to pin to a version, or specific branch, as well as which project in your workspace to add it to.  Once you've made your selections, click the `Add Package` button.  

### via Package.swift

Open your Package.swift file and add the following do your the `dependencies` section:

```
.package(
            name: "Segment",
            url: "https://github.com/segment-integrations/analytics-swift-localytics.git",
            from: "1.0.0"
        ),
```


## Using the Plugin in your App

Open the file where you setup and configure the Analytics-Swift library.  Add this plugin to the list of imports.

```
import Segment
import SegmentLocalytics // <-- Add this line
```

Just under your Analytics-Swift library setup, call `analytics.add(plugin: ...)` to add an instance of the plugin to the Analytics timeline.

```
let analytics = Analytics(configuration: Configuration(writeKey: "<YOUR WRITE KEY>")
                    .flushAt(3)
                    .trackApplicationLifecycleEvents(true))
analytics.add(plugin: LocalyticsDestination())
```
Your events will now be given Localytics session data and start flowing to Localytics via Device Mode.


## Support

Please use Github issues, Pull Requests, or feel free to reach out to our [support team](https://segment.com/help/).

## Integrating with Segment

Interested in integrating your service with us? Check out our [Partners page](https://segment.com/partners/) for more details.

## License
```
MIT License

Copyright (c) 2021 Segment

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

This template is resolved around `ExampleDestination` (to be replaced by you). 

## What does the template provide
### Data class for holding settings
To standardize fetching and using settings in your destination, we recommend using a Coable class to store your destination settings. If marked `Codable`, it will enable you to retrieve your destination settings in a strongly typed construct.

### Settings-related functions
We provide APIs to update your destination settings in `update(settings:type:)`.
`UpdateType.initial` lets you know if this is the intial or subsequent fetch.

`Settings.isDestinationEnabled(key: String)`
- check if your destination is enabled

`Settings.integrationSettings(forKey: String)`
- retrieve a typed destination object

### Sample implementation for common destination functions
We have templated common destinations functions like `track`, `identify`, `screen`, `group`, `alias` that you should modify to fit your vendor SDK implementation. Although these functions do not need to return the ending payload, its good practice to do so (for unit testing purposes).

### Transforming events
Often times, destinations need to transform events (eg: change names, modify properties/traits etc.). We have templated an example of transformation in the `track(event:)` example. we recommend you use this approach to perform any such transformations. This will make your code more legible plus improve code quality.

### Testing functions for primary functions (to be expanded)
We have provided a very bare minimum template for testing the primary destination APIs. We recommend to use this as a starter and build upon it to get test coverage of most scenarios.
