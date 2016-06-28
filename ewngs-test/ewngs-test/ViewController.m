//
//  ViewController.m
//  ewngs-test
//
//  Created by Szabo Gergo on 2016. 06. 28..
//  Copyright © 2016. Szabo Gergo. All rights reserved.
//

#import "ViewController.h"

#import "AsyncImageView.h"
#import "FlickrKit.h"

static NSString * const kAPIKey = @"c0ffad038525f352a2a304db4a33b160";
static NSString * const kSecret = @"32b0d86d245ff918";

@interface ViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout> {
    
    NSArray *_images;
    NSString *_message;
}

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) UIRefreshControl *refreshControl;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    FlickrKit *fk = [FlickrKit sharedFlickrKit];
    [fk initializeWithAPIKey:kAPIKey
                sharedSecret:kSecret];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor purpleColor];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(refreshImages)
                  forControlEvents:UIControlEventValueChanged];
    
    [self.collectionView addSubview:self.refreshControl];
    
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged:)    name:UIDeviceOrientationDidChangeNotification  object:nil];
}

#pragma mark - Overrided

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection{
    
    [self.collectionView reloadData];
}

#pragma mark - Private methods

- (void)orientationChanged:(NSNotification *)notification{
    
    [self.collectionView reloadData];
}

- (void)refreshImages{
    
    _images = nil;
    _message = @"Frissítés";
    [self.collectionView reloadData];
    
    FlickrKit *fk = [FlickrKit sharedFlickrKit];
    
    FKFlickrInterestingnessGetList *interesting = [[FKFlickrInterestingnessGetList alloc] init];
    [fk call:interesting completion:^(NSDictionary *response, NSError *error) {
        // Note this is not the main thread!
        if (response) {
            NSMutableArray *photoURLs = [NSMutableArray array];
            for (NSDictionary *photoData in [response valueForKeyPath:@"photos.photo"]) {
                NSURL *url = [fk photoURLForSize:FKPhotoSizeSmall240 fromPhotoDictionary:photoData];
                [photoURLs addObject:url];
            }
            
            _images = photoURLs;
            _message = nil;
        
        } else if (error){
            
            _message = [NSString stringWithFormat:@"Hiba: %@", error.localizedDescription];
            _images = nil;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.collectionView reloadData];
            [self endRefreshing];
        });
    }];
}

- (void)endRefreshing{
    
    if (self.refreshControl) {
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MMM d, h:mm:ss"];
        NSString *title = [NSString stringWithFormat:@"Utoljára frissítve: %@", [formatter stringFromDate:[NSDate date]]];
        NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor]
                                                                    forKey:NSForegroundColorAttributeName];
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
        self.refreshControl.attributedTitle = attributedTitle;
        
        [self.refreshControl endRefreshing];
    }
}

- (UILabel *)labelWithText:(NSString *)text{
    
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.textAlignment = NSTextAlignmentCenter;
    
    return label;
}

#pragma mark - UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    
    if (!_images) {
        
        self.collectionView.backgroundView = _message ? [self labelWithText:_message] : [self labelWithText:@"Képek betöltéséhez használja a pull to refresh-t."];
        
        return 0;
    }
    
    
    NSUInteger count = _images.count;
    
    if (count == 0) {
        
        collectionView.backgroundView = [self labelWithText:@"Nincsenek megjeleníthető képek"];
    
    } else {
        
        collectionView.backgroundView = nil;
    }
    
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString * const kCellID = @"Cell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellID forIndexPath:indexPath];
    NSURL *imageURL = [_images objectAtIndex:indexPath.row];
    
    AsyncImageView *imageView = [cell viewWithTag:1];
    [imageView setImageURL:imageURL];
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular &&
        self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular &&
        UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
        
        CGFloat size = collectionView.bounds.size.width/6.0f - 5.0f;
        
        return CGSizeMake(size, size);
        
    } else {
        
        CGFloat size = collectionView.bounds.size.width/3.0f - 4.0f;
        
        return CGSizeMake(size, size);
    }
}

@end
