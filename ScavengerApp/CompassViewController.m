//
//  CompassViewController.m
//  ScavengerApp
//
//  Created by Taco van Dijk on 5/21/13.
//  Copyright (c) 2013 Code for Europe. All rights reserved.
//

#import "CompassViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "CLLocation+measuring.h"

#import "CheckinView.h"

#import "RouteFinishedView.h"

#import "NavigationStatusView.h"

#import "CustomBarButtonView.h"

#import "CloudView.h"

#import "DestinationRadarView.h"

#define ARROW_SIZE 150
#define COMPASS_SIZE 300
#if DEBUG
#define CHECKIN_DISTANCE 50 //meters
#else
#define CHECKIN_DISTANCE 50 //meters
#endif
//#define DEGREES_TO_RADIANS(x) (M_PI * x / 180.0)
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)
#define STATUS_HEIGHT 50
#define NAVBAR_HEIGHT 44

@interface CompassViewController ()
@property (nonatomic, strong) UIImageView *arrow;
@property (nonatomic, strong) UIImageView *compass;
@property (nonatomic, weak) CheckinView * checkinView;
@property (nonatomic, weak) RouteFinishedView *routeFinishedView;
@property (nonatomic,strong) NavigationStatusView *statusView;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *destinationLocation;
@property (nonatomic, strong) CLLocation *previousLocation;
@property (nonatomic, assign) BOOL checkinPending;
@property (nonatomic, strong) CloudView *cloudView;
@property (nonatomic, strong) DestinationRadarView *destinationRadarView;
@end

@implementation CompassViewController
@synthesize arrow, compass, checkinView, statusView, cloudView, destinationRadarView;
@synthesize locationManager;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.checkinPending = NO;
        
//    _destinationLocation = [[CLLocation alloc] initWithLatitude:DUMMY_LATITUDE longitude:DUMMY_LONGITUDE];
//        _destinationLocation = [[CLLocation alloc] initWithLatitude:[AppState sharedInstance].activeTarget.latitude longitude:[AppState sharedInstance].activeTarget.longitude];
        float latitude = [[[[AppState sharedInstance] activeWaypoint] objectForKey:@"latitude"] floatValue];
        float longitude = [[[[AppState sharedInstance] activeWaypoint] objectForKey:@"longitude"] floatValue];
        _destinationLocation = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
        self.previousLocation = nil;
        NSLog(@"Destination: lat: %f long %f", latitude, longitude);
    }
    return self;
}

-(void)viewDidDisappear:(BOOL)animated
{
    [cloudView stopAnimation];
    [[AppState sharedInstance] setPlayerIsInCompass:NO];
    [[AppState sharedInstance] save];
}

- (void)viewDidAppear:(BOOL)animated
{
    [cloudView startAnimation];
    [[AppState sharedInstance] setPlayerIsInCompass:YES];
    [[AppState sharedInstance] save];
}

#pragma mark - CLLocation

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    if (newHeading.headingAccuracy > 0) {
        float magneticHeading = newHeading.magneticHeading;
        float trueHeading = newHeading.trueHeading;
#if DEBUG
        //NSLog(@"magnetic heading %f",magneticHeading);
        //NSLog(@"true heading: %f",trueHeading);
#endif
        //current heading in degrees and radians
        //use true heading if it is available
        float heading = (trueHeading > 0) ? trueHeading : magneticHeading;
        float heading_radians = DEGREES_TO_RADIANS(heading);

        
        compass.transform = CGAffineTransformMakeRotation(-1 * heading_radians); //set the compass to current heading

//        [UIView animateWithDuration:0.1 delay:0.0 options:
////         UIViewAnimationOptionBeginFromCurrentState |
//         UIViewAnimationOptionCurveLinear animations:^{
//            CGAffineTransform transform = CGAffineTransformMakeRotation(-1 * heading_radians);
//            compass.transform = transform;
//        } completion:nil];
        
        
        
        CLLocationDirection destinationHeading = [locationManager.location directionToLocation:_destinationLocation];
        //NSLog(@"Destination heading: %f",destinationHeading);
        float adjusted_heading = destinationHeading - heading;
        float adjusted_heading_radians = DEGREES_TO_RADIANS(adjusted_heading);
        //arrow.transform = CGAffineTransformMakeRotation(adjusted_heading_radians);

        
        [UIView animateWithDuration:0.1 delay:0.0 options:
//         UIViewAnimationOptionBeginFromCurrentState |
         UIViewAnimationOptionCurveLinear animations:^{
            CGAffineTransform transform = CGAffineTransformMakeRotation(adjusted_heading_radians);
            arrow.transform = transform;
            destinationRadarView.transform = transform;
        } completion:nil];
        
    }
}

//updates the statusview checkin display
-(void) updateCheckinStatus
{
    //1b. update the statusview
    NSArray *waypoints = [[AppState sharedInstance].activeRoute objectForKey:@"waypoints"];
    NSArray *checkins = [[AppState sharedInstance] checkinsForRoute:[AppState sharedInstance].activeRouteId];
    [self.statusView setCheckinsComplete:[checkins count] ofTotal:[waypoints count]];
}

-(IBAction)checkIn
{
    NSLog(@"CHECK IN");
    
    //1. record the checkin as done
    [[AppState sharedInstance] checkIn];
    [self updateCheckinStatus];
    
    //2. change the active target
    BOOL continueRoute =  [[AppState sharedInstance] nextTarget];
    if (continueRoute) {
        
        float latitude = [[[[AppState sharedInstance] activeWaypoint] objectForKey:@"latitude"] floatValue];
        float longitude = [[[[AppState sharedInstance] activeWaypoint] objectForKey:@"longitude"] floatValue];
        _destinationLocation = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
        NSLog(@"Destination: lat: %f long %f", latitude, longitude);
        
        
        [self.checkinView removeFromSuperview];
        self.checkinPending = NO;
    }
    else { 
        
    }
//    _destinationLocation = [[CLLocation alloc] initWithLatitude:[AppState sharedInstance].activeTarget.latitude longitude:[AppState sharedInstance].activeTarget.longitude];

}

-(IBAction) finishRoute:(id)sender
{
    [_routeFinishedView removeFromSuperview];
}

-(IBAction) goToReward:(id)sender
{
    [_routeFinishedView removeFromSuperview];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    
    NSString * destinationName = [[[AppState sharedInstance] activeWaypoint] objectForKey:@"name_en"];
    NSLog(@"did update with destination: %@",destinationName);
    
    CLLocation *currentLocation = [locations lastObject];
    
    
    NSDate* eventDate = currentLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0) {
        
        // If the event is recent, do something with it.
        double distanceFromDestination = [currentLocation distanceFromLocation:_destinationLocation];
        [self.statusView update:destinationName withDistance:distanceFromDestination];
        
        if (distanceFromDestination < CHECKIN_DISTANCE) {
            NSLog(@"within distance");
            
            if(!self.checkinPending)
            {
                self.checkinPending = YES;
//                UIView *aCheckinView = [[[NSBundle mainBundle] loadNibNamed:@"CheckinView" owner:self options:nil] objectAtIndex:0];
                //Begin - Added by Giovanni 2013-05-28
                //TODO: to test
                NSString *langKey = [[AppState sharedInstance] language];
                CheckinView *aCheckinView = [[CheckinView alloc] init];
                aCheckinView.locationTextView.text = [[[AppState sharedInstance] activeWaypoint] objectForKey:[NSString stringWithFormat:@"description_%@", langKey]];
                aCheckinView.checkInLabel.text = NSLocalizedString(@"You can check-in!", nil);
                //End - Added by Giovanni 2013-05-28
                self.checkinView = (CheckinView*)aCheckinView;
                [self.view addSubview:checkinView];
                NSLog(@"add checkin view");
            }
        }
    
        //if we have a previous location, determine sort of proximation speed
        if(self.previousLocation)
        {
            double previousDistanceFromDestination = [self.previousLocation distanceFromLocation:_destinationLocation];
            
            float pSpeed = (previousDistanceFromDestination - distanceFromDestination) / ([currentLocation.timestamp timeIntervalSinceNow] - [self.previousLocation.timestamp timeIntervalSinceNow]);
            cloudView.speed = pSpeed;
        }
        
        //update radar
        destinationRadarView.activeDestination = [[AppState sharedInstance] activeWaypoint];
        destinationRadarView.currentLocation = currentLocation;
        [destinationRadarView setNeedsDisplay];
        
        self.previousLocation = currentLocation;
    }
    
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Could not get location due to error: %@", [error description]);
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //custom back button
    CustomBarButtonView *backButton = [[CustomBarButtonView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)
                                                                       imageName:@"icon-back"
                                                                            text:@"Back"
                                                                          target:self
                                                                          action:@selector(onBackButton)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    
    
    //custom map button
    CustomBarButtonView *mapButton = [[CustomBarButtonView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)
                                                                      imageName:@"icon-map"
                                                                           text:nil
                                                                          target:self
                                                                          action:@selector(onMapButton)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:mapButton];
    
    
    //
    CGRect statusRect = CGRectMake(0, self.view.bounds.size.height - (STATUS_HEIGHT + NAVBAR_HEIGHT), self.view.bounds.size.width, STATUS_HEIGHT);
    self.statusView = [[NavigationStatusView alloc] initWithFrame:statusRect];
    [self updateCheckinStatus];
    
    if(locationManager == nil)
    {
        locationManager = [[CLLocationManager alloc] init];
    }
    locationManager.delegate = self;
    locationManager.activityType = CLActivityTypeFitness; //Used to track pedestrian activity
    locationManager.headingFilter = 5;  // 5 degrees
//        locationManager.distanceFilter = 2; //2 meters
    

    if( [CLLocationManager locationServicesEnabled]
       &&  [CLLocationManager headingAvailable]) {
        NSLog(@"heading available");
        [locationManager startUpdatingLocation];
        [locationManager startUpdatingHeading];
        
    } else {
        NSLog(@"Can't report heading");
    }
    
    CGPoint screenCenter = CGPointMake(self.view.frame.size.width / 2, (self.view.frame.size.height / 2) - NAVBAR_HEIGHT);
    compass = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"compass"]];
    CGRect compassRect = CGRectMake(0, 0, COMPASS_SIZE, COMPASS_SIZE);
    [compass setFrame:compassRect];
    [compass setCenter:screenCenter];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    UIImage *backgroundImage = [UIImage imageNamed:@"viewbackground"];
    UIImageView *background = [[UIImageView alloc] initWithImage:backgroundImage];
    background.contentMode = UIViewContentModeScaleAspectFit;
    [background setFrame:self.view.bounds];
    [self.view addSubview:background];
    
    UIImage *gridImage = [UIImage imageNamed:@"compassbackground"];
    UIImageView *grid = [[UIImageView alloc] initWithImage:gridImage];
    grid.contentMode = UIViewContentModeScaleAspectFit;
    [grid setFrame:self.view.bounds];
    [grid setCenter:screenCenter];
    
    
    UIImage * arrowImage = [UIImage imageNamed:@"arrow.png"];
    arrow = [[UIImageView alloc] initWithImage:arrowImage];
    arrow.contentMode = UIViewContentModeScaleAspectFit;
    
    //add arrow
    CGRect arrowRect = CGRectMake(0, 0, ARROW_SIZE, ARROW_SIZE);
    [arrow setFrame:arrowRect];
    [arrow setCenter:CGPointMake(screenCenter.x + 1, screenCenter.y)];//manual calibration
    
    //add clouds
    cloudView = [[CloudView alloc] initWithFrame:grid.frame];
    
    //add radar make it square (bigger than frame) so it overlaps the whole grid always (also when rotated)
    float s = sqrtf(grid.bounds.size.width*grid.bounds.size.width+grid.bounds.size.height*grid.bounds.size.height);
    destinationRadarView = [[DestinationRadarView alloc] initWithFrame:CGRectMake(0, 0, s, s)];
    destinationRadarView.destinations = [[AppState sharedInstance].activeRoute objectForKey:@"waypoints"];
    destinationRadarView.center = arrow.center;
    destinationRadarView.radius = 1500; //1.5 km
    destinationRadarView.checkinRadiusInPixels = 85; //radius of check in area in pix (edge of compass circle)
    destinationRadarView.checkinRadiusInMeters = CHECKIN_DISTANCE;
    
    [self.view addSubview:grid];
    [self.view addSubview:compass];
    [self.view addSubview:arrow];
    [self.view addSubview:destinationRadarView];
    [self.view addSubview:cloudView];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.statusView];
    
    [cloudView startAnimation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Timer
- (void)onTimerTick:(id)something
{
    
    
    //NSLog(@"timer");
}



#pragma mark - CustomButtonHandlers
- (void)onBackButton
{
    [self.navigationController popViewControllerAnimated:true];
}

- (void)onMapButton
{
    NSLog(@"show map");
}


@end
