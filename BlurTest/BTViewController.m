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

    [self fetchPhotoWithCompletionHandler:^(ALAsset *asset) {
        ALAssetRepresentation *representation = [asset defaultRepresentation];
        CGImageRef imageRef = [representation fullResolutionImage];
        self.backgroundView.image = [[UIImage alloc] initWithCGImage:imageRef scale:representation.scale orientation:representation.orientation];
    }];
}

- (IBAction)didPan:(UIPanGestureRecognizer *)sender
{
    CGPoint translation = [sender translationInView:self.view];

    CGRect blurViewFrame = self.blurView.frame;
    blurViewFrame.size.height += translation.y;

    if (blurViewFrame.size.height > CGRectGetHeight(self.view.bounds)) {
        blurViewFrame.size.height = CGRectGetHeight(self.view.bounds);
    } else if (blurViewFrame.size.height < 0) {
        blurViewFrame.size.height = 0;
    }

    self.blurView.frame = blurViewFrame;

    [sender setTranslation:CGPointZero inView:self.view];
}

- (void)fetchPhotoWithCompletionHandler:(void (^)(ALAsset *))handler;
{
    [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (!group)
            return;

        *stop = YES;

        [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stopGroup) {
            if (!result)
                return;

            *stopGroup = YES;

            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (handler)
                    handler(result);
            }];
        }];
    } failureBlock:nil];
}

- (IBAction)applyBlur:(id)sender
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGRect bounds = self.view.bounds;

        UIImage *viewImage = [KVRenderer renderImageWithSize:CGSizeMake(320, 568) transparency:NO drawingBlock:^{
            [self.backgroundView drawViewHierarchyInRect:bounds];
        }];

        UIImage *blurredImage = [viewImage applyLightEffect];
        self.blurView.image = blurredImage;
    });
}

@end
