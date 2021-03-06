//
//  AppState.h
//  ScavengerApp
//
//  Created by Taco van Dijk on 5/23/13.
//  Copyright (c) 2013 Code for Europe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataModels.h"
#import <CoreLocation/CoreLocation.h>

extern NSString* const kLocationServicesFailure;
extern NSString* const kLocationServicesForbidden;
extern NSString* const kLocationServicesGotBestAccuracyLocation;
extern NSString* const kLocationServicesUpdateHeading;
extern NSString* const kLocationServicesEnteredDestinationRegion;


extern NSString* const kFilePathCatalogs;
extern NSString* const kFilePathRoutes;
extern NSString* const kFilePathProfiles;

@interface AppState : NSObject <CLLocationManagerDelegate>

@property (nonatomic, strong) NSMutableArray *checkins; //Array of check-ins along current route
//@property (nonatomic, assign) int activeProfileId; //ID of the active profile
@property (nonatomic, assign) int activeRouteId; //ID of the active route
@property (nonatomic, assign) int activeTargetId;   //ID of the active Target where we are navigating to
@property (nonatomic, assign) BOOL playerIsInCompass; //Is the player in compass mode? If so, when restoring, go there immediately
//@property (nonatomic, strong) NSDictionary *game; //Dictionary from GHGameData
@property (nonatomic, strong) GHCatalog *currentCatalog; //Catalog of the game (with profiles, routes)
@property (nonatomic, strong) GHRoute *currentRoute;
@property (nonatomic, strong) GHCities *cities;
@property (nonatomic, strong) GHCity *currentCity; //City the player is currently in

//Location
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *currentLocation;

+(AppState *)sharedInstance;
- (void)checkIn;
- (BOOL)save;
- (void)restore;
- (BOOL)setNextTarget;

- (GHWaypoint*)activeWaypoint;

- (GHWaypoint*)nextCheckinForRoute:(int)routeId startingFromWaypointRank:(int)rank;
- (NSArray*)checkinsForRoute:(int)routeId;
- (NSArray*)waypointsWithCheckinsForRoute:(int)routeId;
- (BOOL)isRouteFinished:(NSDictionary*)route;

//Location
- (void) startLocationServices;
- (void) startLocationServicesLowPrecision;
- (void) stopLocationServices;

- (void)startMonitoringForDestination;
- (void)stopMonitoringForDestination;



@end



//in compass controller

//appdelegate.appstate.activeRoute
//appdelegate.appstate.activeTargetLocation

//check in the current target location

// appdelegate.appstate.activeRoute.activeLocation setMarked:YES
//or
// appdelegate.appstate.progress.add new Progress(appstate.activeRoute.activeLocation)
//

