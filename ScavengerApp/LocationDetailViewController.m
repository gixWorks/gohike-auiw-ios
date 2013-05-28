//
//  LocationDetailViewController.m
//  ScavengerApp
//
//  Created by Giovanni on 5/28/13.
//  Copyright (c) 2013 Code for Europe. All rights reserved.
//

#import "LocationDetailViewController.h"
#import "CompassViewController.h"

@interface LocationDetailViewController ()

@end

@implementation LocationDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UIBarButtonItem *startRouteButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Hike!", nil) style:UIBarButtonItemStylePlain target:self action:@selector(replayLocation)];
    self.navigationItem.rightBarButtonItem = startRouteButton;
    
    NSString *langKey = [[AppState sharedInstance] language];
    self.locationImageView.image = [UIImage imageWithData:[NSData dataWithBase64EncodedString:[_location objectForKey:@"image_data"]]];
    self.locationText.text = [_location objectForKey:[NSString stringWithFormat:@"description_%@",langKey]];
    self.locationTitleLabel.text = [_location objectForKey:[NSString stringWithFormat:@"name_%@", langKey]];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)replayLocation
{
    NSArray *waypoints = [[[AppState sharedInstance] activeRoute] objectForKey:@"waypoints"];
    NSDictionary *thisWayPoint;
    
    NSUInteger index = [waypoints indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [[obj objectForKey:@"location_id"] integerValue] == [[_location objectForKey:@"location_id"] intValue];
    }];
    if (index == NSNotFound) {
        
    }
    else {
        thisWayPoint = [waypoints objectAtIndex:index];
    }
    
    if([waypoints count] > 0)
    {
        [[AppState sharedInstance] setActiveRouteId: [[_location objectForKey:@"route_id"] intValue]];
        [[AppState sharedInstance] setActiveTargetId: [[_location objectForKey:@"location_id"] intValue]];
        [[AppState sharedInstance] save];
        
        NSLog(@"Active Target ID = %d",[[AppState sharedInstance] activeTargetId]);
        
        CompassViewController *compass = [[CompassViewController alloc] init];
//        [compass setReplay:YES]; //TODO: set we are replaying
        [self.navigationController pushViewController:compass animated:YES];
        
    }
}


@end