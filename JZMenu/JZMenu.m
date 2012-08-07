//
//  JZMenu.m
//  JZMenu
//
//  Created by Jure Zove on 6. 08. 12.
//  Copyright (c) 2012 Jure Zove. All rights reserved.
//

#import "JZMenu.h"

#define kStartMenuItemSize 60.0f
#define kAnimationDuration 0.25f
#define kAnimationDelay 0.1f
#define kMenuItemImageSize 80.0f
#define kMainMenuTransform CGAffineTransformMakeScale(2.5, 2.5)

// Colors for the menu background
#define RGB(r,g,b, a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
#define kMenuColor RGB(0, 0, 0, 0.7)
#define kMenuHighlightedColor RGB(255, 255, 255, 0.5)
#define kMenuCantHighlightColor RGB(255, 0, 0, 0.5)

@interface JZMenu() {
    UILongPressGestureRecognizer *longPress;
    UIPanGestureRecognizer *pan;
    BOOL isHighlighted;
    
    // Origin difference for smother panning
    float diffX, diffY;
    NSMutableArray *menuItems;
}

@property (nonatomic, strong) UIImageView *unselectedImageView;
@property (nonatomic, strong) UIImageView *selectedImageView;
@property (nonatomic) CGRect parentFrame;
@property (nonatomic) JZMenuPosition position;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, weak) id<JZMenuDelegate> menuDelegate;

@end

@implementation JZMenu

@synthesize selectedImageView;
@synthesize unselectedImageView;
@synthesize parentFrame;
@synthesize position;
@synthesize menuView = _menuView;
@synthesize menuDelegate = _menuDelegate;

- (id)initWithHighlightedImage:(UIImage*)selectedImage
            Image:(UIImage*)unselectedImage
                 menuImages:(NSArray *)images
                   position:(JZMenuPosition)menuPosition
                parentFrame:(CGRect)frame
                   menuDelegate:(id<JZMenuDelegate>)menuDelegate {
    if (self = [super initWithFrame:frame]) {
        self.selectedImageView = [[UIImageView alloc] initWithImage:selectedImage];
        self.unselectedImageView = [[UIImageView alloc] initWithImage:unselectedImage];
        self.parentFrame = frame;
        self.position = menuPosition;
        self.menuDelegate = menuDelegate;
        [self createMenuWith:images];
        [self config];
    }
    return self;
}

#pragma mark - Config

- (CGPoint)centerPointForOrigin:(CGPoint)origin {
    return CGPointMake(origin.x + kStartMenuItemSize / 2, origin.y + kStartMenuItemSize / 2);
}

- (CGPoint)originPoint {
    float x, y;
    
    if (self.position & JZMenuPositionTop && !(self.position & JZMenuPositionBottom)) {
        y = 0;
    } else if (self.position & JZMenuPositionBottom && !(self.position & JZMenuPositionTop)) {
        y = self.frame.size.height - kStartMenuItemSize;
    } else {
        y = self.frame.size.height / 2 - kStartMenuItemSize / 2;
    }
    
    if (self.position & JZMenuPositionLeft && !(self.position & JZMenuPositionRight)) {
        x = 0;
    } else if (self.position & JZMenuPositionRight && !(self.position & JZMenuPositionLeft)) {
        x = self.frame.size.width - kStartMenuItemSize;
    } else {
        x = self.frame.size.width / 2 - kStartMenuItemSize / 2;
    }
    
    return CGPointMake(x, y);
}

- (void)config {
    // Determine the frame of the menu
    CGSize size = CGSizeMake(kStartMenuItemSize, kStartMenuItemSize);
    CGPoint originPoint = [self originPoint];
    self.unselectedImageView.contentMode = self.selectedImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.unselectedImageView.frame = self.selectedImageView.frame = CGRectMake(originPoint.x, originPoint.y, size.width, size.height);
    self.selectedImageView.hidden = YES;
    [self addSubview:self.selectedImageView];
    [self addSubview:self.unselectedImageView];
    
    // Add gesture recognizers
    longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    longPress.minimumPressDuration = kAnimationDuration;
    longPress.delegate = self;
    [self addGestureRecognizer:longPress];
    
    pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    pan.delegate = self;
    [self addGestureRecognizer:pan];
    
    self.backgroundColor = [UIColor clearColor];
}

- (void)createMenuWith:(NSArray*)images {
    _menuView = [[UIView alloc] initWithFrame:self.bounds];
    _menuView.backgroundColor = [UIColor clearColor];
    _menuView.hidden = YES;
    [self addSubview:_menuView];
    [self sendSubviewToBack:_menuView];
    
    // Menu items
    menuItems = [[NSMutableArray alloc] initWithCapacity:images.count];
    float sizeOfMenuItem = (float)self.frame.size.height / images.count;
    CGRect imageRect = CGRectMake(self.frame.size.width / 2 - kMenuItemImageSize / 2,
                                  sizeOfMenuItem / 2 - kMenuItemImageSize / 2,
                                  kMenuItemImageSize,
                                  kMenuItemImageSize);
    for (int i = 0; i < images.count; i++) {
        CGRect frame = CGRectMake(0,
                                  i * sizeOfMenuItem,
                                  self.frame.size.width,
                                  sizeOfMenuItem);
        
        // Menu item
        UIView *menuItem = [[UIView alloc] initWithFrame:frame];
        menuItem.layer.borderColor = [UIColor whiteColor].CGColor;
        menuItem.layer.borderWidth = 1.0f;
        menuItem.backgroundColor = kMenuColor;
        
        // Menu image
        UIImageView *image = [[UIImageView alloc] initWithFrame:imageRect];
        image.image = [images objectAtIndex:i];
        image.contentMode = UIViewContentModeCenter;
        [menuItem addSubview:image];
        
        [_menuView addSubview:menuItem];
        [menuItems addObject:menuItem];
    }
}

#pragma mark - Menu stuff

- (void)showMenu {
    [self menuView].hidden = NO;
    [self menuView].alpha = 0;
    [UIView animateWithDuration:kAnimationDuration
                    animations:^{
                        [self menuView].alpha = 0.5;
                    }];

}

- (void)hideMenu {
    [UIView animateWithDuration:kAnimationDuration
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         [self menuView].alpha = 0;
                     } completion:^(BOOL finished) {
                         if (finished) {
                             [self menuView].hidden = YES;
                         }
                     }];
}

- (NSInteger)highlightedItemIndexAt:(CGPoint)point {
    int highlightedItemIndex = -1;
    for (int i = 0; i < menuItems.count; i++) {
        UIView *menuItem = [menuItems objectAtIndex:i];
        if (CGRectContainsPoint(menuItem.frame, point)) {
            highlightedItemIndex = i;
            break;
        }
    }
    return highlightedItemIndex;
}

- (void)highlightMenuItemAtPoint:(CGPoint)point {
    [self layoutMenuItems:[self highlightedItemIndexAt:point]];
}

- (void)layoutMenuItems:(NSInteger)highlightedItemIndex {
    float y = 0;
    float menuItemSize = (self.frame.size.height / menuItems.count);
    for (int i = 0; i < menuItems.count; i++) {
        CGRect frame = CGRectMake(0,
                                   y += frame.size.height,
                                   self.frame.size.width,
                                   menuItemSize);
        
        [UIView animateWithDuration:kAnimationDuration
                         animations:^{
                             if (i == highlightedItemIndex) {
                                 // Check if we can highlight the current item
                                 if (highlightedItemIndex >= 0 && self.menuDelegate &&
                                     [self.menuDelegate respondsToSelector:@selector(canSelectItemAtIndex:inMenu:)] &&
                                     [self.menuDelegate canSelectItemAtIndex:highlightedItemIndex inMenu:self]) {
                                     [(UIView*)[menuItems objectAtIndex:i] setBackgroundColor:kMenuHighlightedColor];
                                 } else {
                                     [(UIView*)[menuItems objectAtIndex:i] setBackgroundColor:kMenuCantHighlightColor];
                                 }
                             } else {
                                 [(UIView*)[menuItems objectAtIndex:i] setBackgroundColor:kMenuColor];
                             }
                         }];
    }
}

#pragma mark - Gestures

- (void)changeSelection:(BOOL)selected {
    if (selected) {
        if (isHighlighted)
            return;
        isHighlighted = YES;
        
        [self showMenu];
        self.selectedImageView.alpha = 0;
        self.selectedImageView.hidden = NO;
        [UIView animateWithDuration:kAnimationDuration
                              delay:0
                            options:UIViewAnimationCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             self.selectedImageView.transform = kMainMenuTransform;
                             self.unselectedImageView.alpha = 0;
                             self.selectedImageView.alpha = 1;
                         } completion:^(BOOL finished) {
                             if (finished) {
                                 self.unselectedImageView.hidden = YES;
                             }
                         }];
    } else {
        if (!isHighlighted)
            return;
        isHighlighted = NO;
        
        [self hideMenu];
        self.unselectedImageView.alpha = 0;
        self.unselectedImageView.hidden = NO;
        [UIView animateWithDuration:kAnimationDuration
                              delay:0
                            options:UIViewAnimationCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             self.selectedImageView.transform = CGAffineTransformIdentity;
                             self.selectedImageView.alpha = 0;
                             self.unselectedImageView.alpha = 1;
                         } completion:^(BOOL finished) {
                             if (finished) {
                                 self.selectedImageView.hidden = YES;
                             }
                         }];
    }
}

- (void)resetMove {
    [self changeSelection:NO];
    [self moveTo:[self centerPointForOrigin:[self originPoint]] animated:YES];
}

- (void)moveTo:(CGPoint)point animated:(BOOL)animated {
    if (!CGPointEqualToPoint(self.unselectedImageView.center, point) ||
        !CGPointEqualToPoint(self.selectedImageView.center, point)) {
        if (animated) {
            [UIView animateWithDuration:kAnimationDuration
                                  delay:kAnimationDelay
                                options:UIViewAnimationOptionAllowUserInteraction
                             animations:^{
                                 self.unselectedImageView.center = point;
                                 self.selectedImageView.center = point;
                             } completion:nil];
        } else {
            self.unselectedImageView.center = self.selectedImageView.center = point;
        }
        [self highlightMenuItemAtPoint:point];
    }
}

- (void)handleGesture:(UIGestureRecognizer*)gesture {
    CGPoint point = [gesture locationInView:self];
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self changeSelection:YES];
        if (gesture == pan) {
            CGPoint pointInSelf = [gesture locationInView:self.unselectedImageView];
            diffX = (self.unselectedImageView.frame.size.width / 2 - pointInSelf.x);
            diffY = (self.unselectedImageView.frame.size.height / 2 - pointInSelf.y);
        } else {
            // The gesture is long press, just highlight the item
            [self highlightMenuItemAtPoint:point];
        }
    } else if ((gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) && isHighlighted) { // Only recognize the gesture if the menu item is highlighted
        [self resetMove];
        // If the gesture isn't cancelled, we notify the delegate
        if (gesture.state != UIGestureRecognizerStateCancelled) {
            NSInteger highlightedItemIndex = [self highlightedItemIndexAt:point];
            if (highlightedItemIndex >= 0 && self.menuDelegate && [self.menuDelegate respondsToSelector:@selector(canSelectItemAtIndex:inMenu:)]) {
                if ([self.menuDelegate canSelectItemAtIndex:highlightedItemIndex inMenu:self]) {
                    [self.menuDelegate didSelectItemAtIndex:highlightedItemIndex inMenu:self];
                }
            }
        }
    } else if (gesture == pan && isHighlighted) {
        point.x += diffX;
        point.y += diffY;
        [self moveTo:point animated:NO];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGPoint test = [touch locationInView:self];
    if (CGRectContainsPoint(self.unselectedImageView.frame, test)
        || CGRectContainsPoint(self.selectedImageView.frame, test)) {
        return YES;
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)dealloc {
    [menuItems removeAllObjects];
    menuItems = nil;
    selectedImageView = nil;
    unselectedImageView = nil;
    self.menuView = nil;
}

@end
