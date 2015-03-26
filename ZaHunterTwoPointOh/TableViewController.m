//
//  TableViewController.m
//  ZaHunterTwoPointOh
//
//  Created by Jen Kelley on 3/25/15.
//  Copyright (c) 2015 Jen Kelley. All rights reserved.
//

#import "TableViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface TableViewController () <CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate>
@property CLLocationManager *locationManager;
@property NSMutableArray *pizzaArray;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UITextView *textView;
@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager startUpdatingLocation];

}
#pragma mark - "location manager"
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"%@", error);
}
//where am I?
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    for (CLLocation *location in locations) {
        if (location.horizontalAccuracy < 1000 && location.verticalAccuracy < 1000) {
            NSLog(@"Location found!");
            [self.locationManager stopUpdatingLocation];
            [self reverseGeocodePizza:location];
        }
    }
}
#pragma mark - "geocoding pizza address from current address"
//what is this address?
-(void)reverseGeocodePizza:(CLLocation *)location{
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *placemark = placemarks.firstObject;
        NSString *address = [NSString stringWithFormat:@"%@ %@\n%@",
                             placemark.subThoroughfare,
                             placemark.thoroughfare,
                             placemark.locality];
        NSLog(@"%@", address);
        [self findPizzaNear:placemark.location];
    }];
}
//what pizza is nearby?
-(void)findPizzaNear:(CLLocation *)location{
    MKLocalSearchRequest *request = [MKLocalSearchRequest new];
    request.naturalLanguageQuery = @"pizza";
    request.region = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(.1, .1));

    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        self.pizzaArray = [[NSMutableArray alloc] initWithArray:response.mapItems];
        NSLog(@"You should be at the %lu", (unsigned long)self.pizzaArray.count);
        [self.tableView reloadData];
     //   ten items

    }];
}
#pragma mark - "directions"
//this is drawing the entire routh with the array of paths... not working yet
- (void) drawRoute:(NSArray *) path
{
    NSInteger numberOfSteps = path.count;

    CLLocationCoordinate2D coordinates[numberOfSteps];
    for (NSInteger index = 0; index < numberOfSteps; index++) {
        CLLocation *location = [path objectAtIndex:index];
        CLLocationCoordinate2D coordinate = location.coordinate;

        coordinates[index] = coordinate;
    }

   // MKPolyline *polyLine = [MKPolyline polylineWithCoordinates:coordinates count:numberOfSteps];
   // [MKMapItem addOverlay:polyLine]; //when button is clicked. this is called
    
    
}
- (IBAction)onPizzaRunTapped:(id)sender {
    [MKMapItem openMapsWithItems:self.pizzaArray launchOptions:nil];

//  not quite working
//  [self drawRoute:self.pizzaArray];
}
//mkroute, create steps. polyline is all the steps. mkroutestep has instructions property, transporttype and distance
-(NSString *)getDirectionsTo:(MKMapItem *)destinationItem
{
    MKDirectionsRequest *request = [MKDirectionsRequest new];
    request.source = [MKMapItem mapItemForCurrentLocation];
    request.destination = destinationItem;
    request.transportType = MKDirectionsTransportTypeWalking;

    MKDirections *walkingDirections = [[MKDirections alloc] initWithRequest:request];
    [walkingDirections calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        MKRoute *route = response.routes.firstObject;
        NSMutableString *walkingDirectionString = [NSMutableString new];
        int counter = 1;

        for (MKRouteStep *step in route.steps) {
            [walkingDirectionString appendFormat:@"%d: %@\n", counter, step.instructions];
            counter++;
            self.textView.text = walkingDirectionString;
        }
    }];
//these are time calculations
//    MKDirections *timeDirections = [MKDirections new];
//    [timeDirections calculateETAWithCompletionHandler:^(MKETAResponse *response, NSError *error) {
//        for (MKRoute *timeRoute in self.pizzaArray) {
//
//
//            double walkDirectionsTime = timeRoute.expectedTravelTime;
//            NSLog(@"%f", walkDirectionsTime);
//        }
//    }];
    return self.textView.text;

// these are unfinished auto calculations
//    MKDirections *autoDirections = [[MKDirections alloc] init];
//    request.source = [MKMapItem mapItemForCurrentLocation];
//    request.destination = destinationItem;
//    request.transportType = MKDirectionsTransportTypeAutomobile;
}

#pragma mark - "tableview"
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 4;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PizzaCellID"];
    MKMapItem *mapItem = [self.pizzaArray objectAtIndex:indexPath.row];

    CLLocationDistance distance = [self.locationManager.location distanceFromLocation:mapItem.placemark.location];

    cell.textLabel.text = mapItem.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%f meters", distance];


    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
  self.textView.text = [self getDirectionsTo:[self.pizzaArray objectAtIndex:indexPath.row]];
}

#pragma mark - "Main MapView"
//need to research how to access the map that pops up. to force-code only the 4 places that come up, do an overlay of the total route

@end
