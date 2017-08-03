//
//  InstructionFormatter.swift
//  MapboxNavigation
//
//  Created by Bobby Sudekum on 8/3/17.
//  Copyright © 2017 Mapbox. All rights reserved.
//

import Foundation
import CoreLocation

@objc(MBSpokenInstructionFormatter)
open class SpokenInstructionFormatter: NSObject {
    
    let routeStepFormatter = RouteStepFormatter()
    let maneuverVoiceDistanceFormatter = SpokenDistanceFormatter(approximate: true)

    public func speechString(notification: NSNotification, markUpWithSSML: Bool) -> String {
        let routeProgress = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationRouteProgressKey] as! RouteProgress
        let userDistance = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationDistanceToEndOfManeuverKey] as! CLLocationDistance
        let alertLevel = routeProgress.currentLegProgress.alertUserLevel
        let profileIdentifier = routeProgress.route.routeOptions.profileIdentifier
        let minimumDistanceForHighAlert = RouteControllerMinimumDistanceForMediumAlert(identifier: profileIdentifier)
        
        let escapeIfNecessary = {(distance: String) -> String in
            return markUpWithSSML ? distance.addingXMLEscapes : distance
        }
        
        // If the current step arrives at a waypoint, the upcoming step is part of the next leg.
        let upcomingLegIndex = routeProgress.currentLegProgress.currentStep.maneuverType == .arrive ? routeProgress.legIndex + 1 :routeProgress.legIndex
        // Even if the next waypoint and the waypoint after that have the same coordinates, there will still be a step in between the two arrival steps. So the upcoming and follow-on steps are guaranteed to be part of the same leg.
        let followOnLegIndex = upcomingLegIndex
        
        // Handle arriving at the final destination
        //
        let numberOfLegs = routeProgress.route.legs.count
        guard let followOnInstruction = routeStepFormatter.string(for: routeProgress.currentLegProgress.followOnStep, legIndex: followOnLegIndex, numberOfLegs: numberOfLegs, markUpWithSSML: markUpWithSSML) else {
            let upComingStepInstruction = routeStepFormatter.string(for: routeProgress.currentLegProgress.upComingStep, legIndex: upcomingLegIndex, numberOfLegs: numberOfLegs, markUpWithSSML: markUpWithSSML)!
            var text: String
            if alertLevel == .arrive {
                text = upComingStepInstruction
            } else {
                text = String.localizedStringWithFormat(NSLocalizedString("WITH_DISTANCE_UTTERANCE_FORMAT", bundle: .mapboxCoreNavigation, value: "In %@, %@", comment: "Format for speech string; 1 = formatted distance; 2 = instruction"), escapeIfNecessary(maneuverVoiceDistanceFormatter.string(from: userDistance)), upComingStepInstruction)
            }
            
            return text
        }
        
        // If there is no `upComingStep`, there definitely should not be a followOnStep.
        // This should be caught above.
        let upComingInstruction = routeStepFormatter.string(for: routeProgress.currentLegProgress.upComingStep, legIndex: upcomingLegIndex, numberOfLegs: numberOfLegs, markUpWithSSML: markUpWithSSML)!
        let stepDistance = routeProgress.currentLegProgress.upComingStep!.distance
        let currentInstruction = routeStepFormatter.string(for: routeProgress.currentLegProgress.currentStep, legIndex: routeProgress.legIndex, numberOfLegs: numberOfLegs, markUpWithSSML: markUpWithSSML)
        let step = routeProgress.currentLegProgress.currentStep
        var text: String
        
        // We only want to announce this special depature announcement once.
        // Once it has been announced, all subsequnt announcements will not have an alert level of low
        // since the user will be approaching the maneuver location.
        if routeProgress.currentLegProgress.currentStep.maneuverType == .depart && alertLevel == .depart {
            if userDistance < minimumDistanceForHighAlert {
                text = String.localizedStringWithFormat(NSLocalizedString("LINKED_WITH_DISTANCE_UTTERANCE_FORMAT", bundle: .mapboxCoreNavigation, value: "%@, then in %@, %@", comment: "Format for speech string; 1 = current instruction; 2 = formatted distance to the following linked instruction; 3 = that linked instruction"), currentInstruction!, escapeIfNecessary(maneuverVoiceDistanceFormatter.string(from: userDistance)), upComingInstruction)
            } else if let roadDescription = step.roadDescription(markedUpWithSSML: markUpWithSSML) {
                text = String.localizedStringWithFormat(NSLocalizedString("CONTINUE_ON_ROAD", bundle: .mapboxCoreNavigation, value: "Continue on %@ for %@", comment: "Format for speech string after completing a maneuver and starting a new step; 1 = way name; 2 = distance"), roadDescription, escapeIfNecessary(maneuverVoiceDistanceFormatter.string(from: userDistance)))
            } else {
                text = String.localizedStringWithFormat(NSLocalizedString("CONTINUE", bundle: .mapboxCoreNavigation, value: "Continue for %@", comment: "Format for speech string after completing a maneuver and starting a new step; 1 = distance"), escapeIfNecessary(maneuverVoiceDistanceFormatter.string(from: userDistance)))
            }
        } else if routeProgress.currentLegProgress.currentStep.distance > 2_000 && routeProgress.currentLegProgress.alertUserLevel == .low {
            if let roadDescription = step.roadDescription(markedUpWithSSML: markUpWithSSML) {
                text = String.localizedStringWithFormat(NSLocalizedString("CONTINUE_ON_ROAD", bundle: .mapboxCoreNavigation, value: "Continue on %@ for %@", comment: "Format for speech string after completing a maneuver and starting a new step; 1 = way name; 2 = distance"), roadDescription, escapeIfNecessary(maneuverVoiceDistanceFormatter.string(from: userDistance)))
            } else {
                text = String.localizedStringWithFormat(NSLocalizedString("CONTINUE", bundle: .mapboxCoreNavigation, value: "Continue for %@", comment: "Format for speech string after completing a maneuver and starting a new step; 1 = distance"), escapeIfNecessary(maneuverVoiceDistanceFormatter.string(from: userDistance)))
            }
        } else if alertLevel == .high && stepDistance < minimumDistanceForHighAlert {
            text = String.localizedStringWithFormat(NSLocalizedString("LINKED_UTTERANCE_FORMAT", bundle: .mapboxCoreNavigation, value: "%@, then %@", comment: "Format for speech string; 1 = current instruction; 2 = the following linked instruction"), upComingInstruction, followOnInstruction)
        } else if alertLevel != .high {
            text = String.localizedStringWithFormat(NSLocalizedString("WITH_DISTANCE_UTTERANCE_FORMAT", bundle: .mapboxCoreNavigation, value: "In %@, %@", comment: "Format for speech string; 1 = formatted distance; 2 = instruction"), escapeIfNecessary(maneuverVoiceDistanceFormatter.string(from: userDistance)), upComingInstruction)
        } else {
            text = upComingInstruction
        }
        
        return text.removingPunctuation
    }
}
