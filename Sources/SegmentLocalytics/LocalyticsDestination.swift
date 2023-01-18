//
//  LocalyticsDestination.swift
//  LocalyticsDestination
//
//  Created by Komal Dhingra on 12/1/23.

// MIT License
//
// Copyright (c) 2021 Segment
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import Segment
import Localytics

public class LocalyticsDestination: DestinationPlugin {
    
    public let timeline = Timeline()
    public let type = PluginType.destination
    public let key = "Localytics"
    public var analytics: Analytics? = nil
    
    private var localyticsSettings: LocalyticsSettings?
    private var defaultSettings: Settings?
        
    public init() { }

    public func update(settings: Settings, type: UpdateType) {
        // Skip if you have a singleton and don't want to keep updating via settings.
        guard type == .initial else { return }
        
        // Grab the settings and assign them for potential later usage.
        // Note: Since integrationSettings is generic, strongly type the variable.
        guard let tempSettings: LocalyticsSettings = settings.integrationSettings(forPlugin: self) else { return }
        localyticsSettings = tempSettings
        defaultSettings = settings
        
        if let sessionTimeoutInterval = settings.integrationSettings(forKey: key)?["sessionTimeoutInterval"] as? NSNumber {
            if sessionTimeoutInterval.intValue > 0 {
                Localytics.setOptions(["session_timeout": sessionTimeoutInterval])
            } else {
                Localytics.setOptions(["session_timeout": NSNumber(30)])
            }
        }
        
        Localytics.autoIntegrate(tempSettings.apiKey, withLocalyticsOptions: nil)
    }
    
    public func identify(event: IdentifyEvent) -> IdentifyEvent? {
        
        if let userID = event.userId {
            Localytics.setCustomerId(userID)
            analytics?.log(message: "Localytics Identified Id - \(userID)")
        }
        // We also can set email and name of customer
        if let userDetails = event.traits?.dictionaryValue {
            let email = userDetails["email"] as? String ?? ""
            Localytics.setCustomerEmail(email)
            Localytics.setValue(email, forIdentifier: "email")
            analytics?.log(message: "Localytics Identified email - \(email)")
            
            if let name = userDetails["name"] as? String {
                Localytics.setCustomerFullName(name)
                Localytics.setValue(name, forIdentifier: "customer_name")
                analytics?.log(message: "Localytics Identified name - \(name)")
            }
            
            if let firstname = userDetails["first_name"] as? String {
                Localytics.setCustomerFirstName(firstname)
                analytics?.log(message: "Localytics Identified firstname - \(firstname)")
            }
            
            if let lastName = userDetails["last_name"] as? String {
                Localytics.setCustomerLastName(lastName)
                analytics?.log(message: "Localytics Identified lastName - \(lastName)")
            }
            
            setCustomDimensions(traits: userDetails)
            
            // Allow users to specify whether attributes should be Org or Application Scoped.
            var attributeScope: LLProfileScope!
            if localyticsSettings?.setOrganizationScope == true {
                attributeScope = LLProfileScope.organization
            } else {
                attributeScope = LLProfileScope.application
            }
            
            // Other traits. Iterate over all the traits and set them.
            for (key, _) in userDetails {
                let traitValue = userDetails[key] as? String ?? ""
                Localytics.setValue(traitValue, forProfileAttribute: key, with: attributeScope)
            }
            
        }
        
        return event
    }
    
    public func track(event: TrackEvent) -> TrackEvent? {
        
        DispatchQueue.main.async {
            
            let isBackgrounded = UIApplication.shared.applicationState != UIApplication.State.active
            if isBackgrounded {
                Localytics.openSession()
            }
            
            let revenue = self.extractRevenue(dictionary: event.properties?.dictionaryValue ?? [:], revenueKey: "revenue")
            let eventProperties: [String: String] = event.properties?.dictionaryValue?.compactMapValues { "\($0)" } ?? [:]
            if revenue != nil {
                Localytics.tagEvent(event.event,attributes: eventProperties, customerValueIncrease: (revenue?.intValue ?? 0 * 100) as NSNumber)
            } else {
                Localytics.tagEvent(event.event, attributes: eventProperties)
            }
            
            self.setCustomDimensions(traits: event.properties?.dictionaryValue ?? [:])
            
            // Backgrounded? Close the session again after the event.
            if isBackgrounded {
                Localytics.closeSession()
            }
        }
        
        return event
    }
    
    public func screen(event: ScreenEvent) -> ScreenEvent? {
        
        if let eventName = event.name {
            Localytics.tagScreen(eventName)
        }

        return event
    }
    
    public func reset() {
        Localytics.upload()
    }
    
}

private extension LocalyticsDestination {
    
    func setCustomDimensions(traits: [String: Any]) {
        if let customDimensions = defaultSettings?.integrationSettings(forKey: key)?["dimensions"] as? [String: Any] {
            
            for (key, _) in traits {
                if (customDimensions[key] != nil) {
                    let dimension = customDimensions[key] as? String ?? ""
                    Localytics.setValue(traits[key] as? String ?? "", forCustomDimension: UInt(dimension) ?? 0)
                }
            }
        }
    }
  
    func extractRevenue(dictionary: [String: Any], revenueKey: String)-> NSNumber? {
        var revenueProperty = ""
        for key in dictionary.keys {
            if key.caseInsensitiveCompare(revenueKey) == .orderedSame {
                revenueProperty = dictionary[key] as? String ?? ""
                break
            }
        }
        
        if (!revenueProperty.isEmpty) {
            // Format the revenue.
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter.number(from: revenueProperty)
    
        }
        return nil
    }
}

// Example of versioning for your plugin
extension LocalyticsDestination: VersionedPlugin {
    public static func version() -> String {
        return __destination_version
    }
}

// Example of what settings may look like.
private struct LocalyticsSettings: Codable {
    let apiKey: String
    let setOrganizationScope: Bool
}

//Mark:- Callbacks for app state change
extension LocalyticsDestination : iOSLifecycle {
    
    public func applicationDidEnterBackground(application: UIApplication?) {
        Localytics.dismissCurrentInAppMessage()
        DispatchQueue.main.async {
            Localytics.closeSession()
        }
        Localytics.upload()
    }
    
    public func applicationWillEnterForeground(application: UIApplication?) {
        DispatchQueue.main.async {
            Localytics.openSession()
        }
        Localytics.upload()
    }
    
    public func applicationWillTerminate(application: UIApplication?) {
        DispatchQueue.main.async {
            Localytics.closeSession()
        }
        Localytics.upload()
    }
    
    public func applicationDidBecomeActive(application: UIApplication?) {
        DispatchQueue.main.async {
            Localytics.openSession()
        }
        Localytics.upload()
    }
    
}

extension LocalyticsDestination : RemoteNotifications {
    
    public func registeredForRemoteNotifications(deviceToken: Data) {
        Localytics.setPushToken(deviceToken)
    }
    
    public func receivedRemoteNotification(userInfo: [AnyHashable : Any]) {
        Localytics.handleNotificationReceived(userInfo)
    }
    
}
