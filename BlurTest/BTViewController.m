//
//  BTViewController.m
//  BlurTest
//
//  Created by Mark Adams on 7/6/13.
//  Copyright (c) 2013 Mark Adams. All rights reserved.
//

#import "BTViewController.h"
@import AssetsLibrary;
#import "KVRenderer.h"
#import "UIImage+UIImageEffects.h"

@interface BTViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *backgroundView;
@property (weak, nonatomic) IBOutlet UIImageView *blurView;
@property (strong, nonatomic) ALAssetsLibrary *assetsLibrary;
@property (strong, nonatomic) UIDynamicAnimator *animator;
@property (strong, nonatomic) CALayer *blurMask;

@end

@implementation BTViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    if (!self)
        return nil;

    _assetsLibrary = [[ALAssetsLibrary alloc] init];

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.blurView];

    UICollisionBehavior *collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[self.blurView]];
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.view.bounds];
    [collisionBehavior addBoundaryWithIdentifier:@"Boundary" forPath:path];
    [self.animator addBehavior:collisionBehavior];

    UIGravityBehavior *gravityBehavior = [[UIGravityBehavior alloc] initWithItems:@[self.blurView]];
    [self.animator addBehavior:gravityBehavior];

    [self fetchPhotoWithCompletionHandler:^(CGImageRef imageRef) {
        self.backgroundView.image = [[UIImage alloc] initWithCGImage:imageRef];
    }];
}

- (void)fetchPhotoWithCompletionHandler:(void (^)(CGImageRef))handler;
{
    [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (!group)
            return;

        *stop = YES;

        [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if (!result)
                return;

            *stop = YES;

            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (handler)
                    handler(result.defaultRepresentation.fullResolutionImage);
            }];
        }];
    } failureBlock:nil];
}

- (IBAction)applyBlur:(id)sender
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGRect bounds = self.view.bounds;

        UIImage *viewImage = [KVRenderer renderImageWithSize:bounds.size transparency:NO drawingBlock:^{
            [self.view drawViewHierarchyInRect:bounds];
        }];

        UIImage *blurredImage = [viewImage applyLightEffect];
        self.blurView.image = [[UIImage alloc] initWithCGImage:blurredImage.CGImage];
    });
}

@end
