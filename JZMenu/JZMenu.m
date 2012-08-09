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
#define kMenuItemLabelPadding 10.0f
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
    
//    int currentItemIndex;
}

@property (nonatomic, strong) UIView* displayItem;
@property (nonatomic, strong) UIView* highlightedItem;
@property (nonatomic) CGRect parentFrame;
@property (nonatomic) JZMenuPosition position;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, weak) id<JZMenuDelegate> menuDelegate;
@property (nonatomic) int currentItemIndex;

- (void)hoverOnItemAtIndex:(NSInteger)index inMenu:(JZMenu*)menu;
- (void)leftHoverOnItemAtIndex:(NSInteger)index inMenu:(JZMenu*)menu;

@end

@implementation JZMenu

@synthesize displayItem = _displayItem;
@synthesize highlightedItem = _highlightedItem;
@synthesize parentFrame;
@synthesize position;
@synthesize menuView = _menuView;
@synthesize menuDelegate = _menuDelegate;
@synthesize currentItemIndex = _currentItemIndex;

- (id)initWithHighlightedItem:(id)highlightedItem
                  displayItem:(id)displayItem
                    menuItems:(NSArray *)items
                     position:(JZMenuPosition)menuPosition
                  parentFrame:(CGRect)frame
                 menuDelegate:(id<JZMenuDelegate>)menuDelegate {
    if (self = [super initWithFrame:frame]) {
        [self createDisplayItem:displayItem];
        [self createHighlightedItem:highlightedItem];
//        self.highlightedItem = [[UIImageView alloc] initWithImage:highlightedItem];
//        self.normalItem = [[UIImageView alloc] initWithImage:normalItem];
        self.parentFrame = frame;
        self.position = menuPosition;
        self.menuDelegate = menuDelegate;
        [self createMenuWith:items];
        [self config];
    }
    return self;
}

- (void)setCurrentItemIndex:(int)currentItemIndex {
    if (_currentItemIndex != currentItemIndex) {
        // Handle hovering
        [self leftHoverOnItemAtIndex:_currentItemIndex inMenu:self];
        _currentItemIndex = currentItemIndex;
        [self hoverOnItemAtIndex:_currentItemIndex inMenu:self];
        
        if ([self.menuDelegate respondsToSelector:@selector(hoverOnItemAtIndex:inMenu:)])
            [self.menuDelegate hoverOnItemAtIndex:_currentItemIndex inMenu:self];
    }
}

#pragma mark - Config

- (void)createDisplayItem:(id)displayItem {
    CGPoint originPoint = [self originPoint];
    CGSize size = CGSizeMake(kStartMenuItemSize, kStartMenuItemSize);
    if ([displayItem isKindOfClass:[UIImage class]]) {
        self.displayItem = [[UIImageView alloc] initWithImage:displayItem];
        [(UIImageView*)self.displayItem setContentMode:UIViewContentModeScaleAspectFit];
        [(UIImageView*)self.displayItem setFrame:CGRectMake(originPoint.x, originPoint.y, size.width, size.height)];
        [self addSubview:self.displayItem];
    } else if ([displayItem isKindOfClass:[NSString class]]) {
        CGRect labelRect = CGRectMake(kMenuItemLabelPadding,
                                      kMenuItemLabelPadding,
                                      self.frame.size.width - 2 * kMenuItemLabelPadding,
                                      self.frame.size.height - 2 * kMenuItemLabelPadding);
        self.displayItem = [[UILabel alloc] initWithFrame:labelRect];
        self.displayItem.backgroundColor = [UIColor clearColor];
        [(UILabel*)self.displayItem setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:20.0f]];
        [(UILabel*)self.displayItem setTextAlignment:UITextAlignmentCenter];
        [(UILabel*)self.displayItem setText:displayItem];
        [self addSubview:self.displayItem];
    }
}

- (void)createHighlightedItem:(id)highlightedItem {
    CGSize size = CGSizeMake(kStartMenuItemSize, kStartMenuItemSize);
    CGPoint originPoint = [self originPoint];
    if ([highlightedItem isKindOfClass:[UIImage class]]) {
        self.highlightedItem = [[UIImageView alloc] initWithImage:highlightedItem];
        [(UIImageView*)self.highlightedItem setContentMode:UIViewContentModeScaleAspectFit];
        [(UIImageView*)self.highlightedItem setFrame:CGRectMake(originPoint.x, originPoint.y, size.width, size.height)];
        [self addSubview:self.highlightedItem];
        [self.highlightedItem setHidden:YES];
    } else if ([highlightedItem isKindOfClass:[NSString class]]) {
        CGRect labelRect = CGRectMake(kMenuItemLabelPadding,
                                      kMenuItemLabelPadding,
                                      self.frame.size.width - 2 * kMenuItemLabelPadding,
                                      self.frame.size.height - 2 * kMenuItemLabelPadding);
        self.highlightedItem = [[UILabel alloc] initWithFrame:labelRect];
        self.highlightedItem.backgroundColor = [UIColor clearColor];
        [(UILabel*)self.highlightedItem setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:20.0f]];
        [(UILabel*)self.highlightedItem setTextAlignment:UITextAlignmentCenter];
        [(UILabel*)self.highlightedItem setText:highlightedItem];
        [self addSubview:self.highlightedItem];
        [self.highlightedItem setHidden:YES];
    }
}

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
    
    // Add gesture recognizers
    longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    longPress.minimumPressDuration = kAnimationDuration;
    longPress.delegate = self;
    longPress.cancelsTouchesInView = NO;
    [self addGestureRecognizer:longPress];
    
    pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    pan.delegate = self;
    pan.cancelsTouchesInView = NO;
    [self addGestureRecognizer:pan];
    
    self.backgroundColor = [UIColor clearColor];
}

- (void)createMenuItemWith:(id)object andFrame:(CGRect)frame {
    // Menu item
    UIView *menuItem = [[UIView alloc] initWithFrame:frame];
    menuItem.layer.borderColor = [UIColor whiteColor].CGColor;
    menuItem.layer.borderWidth = 1.0f;
    menuItem.backgroundColor = kMenuColor;
    
    if ([object isKindOfClass:[UIImage class]]) {
        // Menu image
        CGRect imageRect = CGRectMake(self.frame.size.width / 2 - kMenuItemImageSize / 2,
                                      frame.size.height / 2 - kMenuItemImageSize / 2,
                                      kMenuItemImageSize,
                                      kMenuItemImageSize);
        UIImageView *image = [[UIImageView alloc] initWithFrame:imageRect];
        image.image = object;
        image.contentMode = UIViewContentModeCenter;
        [menuItem addSubview:image];
    } else if ([object isKindOfClass:[NSString class]]) {
        CGRect labelRect = CGRectMake(kMenuItemLabelPadding,
                                      kMenuItemLabelPadding,
                                      frame.size.width - 2 * kMenuItemLabelPadding,
                                      frame.size.height - 2 * kMenuItemLabelPadding);
        UILabel *label = [[UILabel alloc] initWithFrame:labelRect];
        label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0f];
        label.textAlignment = UITextAlignmentCenter;
        label.text = object;
        label.backgroundColor = [UIColor clearColor];
        [menuItem addSubview:label];
    }
    
    [_menuView addSubview:menuItem];
    [menuItems addObject:menuItem];
}

- (void)createMenuWith:(NSArray*)items {
    _menuView = [[UIView alloc] initWithFrame:self.bounds];
    _menuView.backgroundColor = [UIColor clearColor];
    _menuView.hidden = YES;
    [self addSubview:_menuView];
    [self sendSubviewToBack:_menuView];
    
    // Menu items
    menuItems = [[NSMutableArray alloc] initWithCapacity:items.count];
    float sizeOfMenuItem = (float)self.frame.size.height / items.count;
    
    for (int i = 0; i < items.count; i++) {
        CGRect frame = CGRectMake(0,
                                  i * sizeOfMenuItem,
                                  self.frame.size.width,
                                  sizeOfMenuItem);
        
        [self createMenuItemWith:[items objectAtIndex:i] andFrame:frame];
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
    int newHighlightedItemIndex = [self highlightedItemIndexAt:point];
    if (newHighlightedItemIndex != self.currentItemIndex)
        [self layoutMenuItems:newHighlightedItemIndex];
}

- (void)layoutMenuItems:(NSInteger)highlightedItemIndex {
    self.currentItemIndex = highlightedItemIndex;
    for (int i = 0; i < menuItems.count; i++) {
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
        self.highlightedItem.alpha = 0;
        self.highlightedItem.hidden = NO;
        [UIView animateWithDuration:kAnimationDuration
                              delay:0
                            options:UIViewAnimationCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             self.highlightedItem.transform = kMainMenuTransform;
                             self.displayItem.alpha = 0;
                             self.highlightedItem.alpha = 1;
                         } completion:^(BOOL finished) {
                             if (finished) {
                                 self.displayItem.hidden = YES;
                             }
                         }];
    } else {
        if (!isHighlighted)
            return;
        isHighlighted = NO;
        
        [self hideMenu];
        self.displayItem.alpha = 0;
        self.displayItem.hidden = NO;
        [UIView animateWithDuration:kAnimationDuration
                              delay:0
                            options:UIViewAnimationCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             self.highlightedItem.transform = CGAffineTransformIdentity;
                             self.highlightedItem.alpha = 0;
                             self.displayItem.alpha = 1;
                         } completion:^(BOOL finished) {
                             if (finished) {
                                 self.highlightedItem.hidden = YES;
                             }
                         }];
    }
}

- (void)resetMove {
    [self changeSelection:NO];
    [self moveTo:[self centerPointForOrigin:[self originPoint]] animated:YES];
}

- (void)moveTo:(CGPoint)point animated:(BOOL)animated {
    if (!CGPointEqualToPoint(self.displayItem.center, point) ||
        !CGPointEqualToPoint(self.highlightedItem.center, point)) {
        if (animated) {
            [UIView animateWithDuration:kAnimationDuration
                                  delay:kAnimationDelay
                                options:UIViewAnimationOptionAllowUserInteraction
                             animations:^{
                                 self.displayItem.center = point;
                                 self.highlightedItem.center = point;
                             } completion:nil];
        } else {
            self.displayItem.center = self.highlightedItem.center = point;
        }
        [self highlightMenuItemAtPoint:point];
    }
}

- (void)handleGesture:(UIGestureRecognizer*)gesture {
    CGPoint point = [gesture locationInView:self];
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self changeSelection:YES];
        if (gesture == pan) {
            CGPoint pointInSelf = [gesture locationInView:self.displayItem];
            diffX = (self.displayItem.frame.size.width / 2 - pointInSelf.x);
            diffY = (self.displayItem.frame.size.height / 2 - pointInSelf.y);
        } else {
            // The gesture is long press, just highlight the item
            [self highlightMenuItemAtPoint:point];
        }
        if (self.menuDelegate && [self.menuDelegate respondsToSelector:@selector(menuActivated:)]) {
            [self.menuDelegate menuActivated:self];
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
        if (self.menuDelegate && [self.menuDelegate respondsToSelector:@selector(menuDeactivated:)]) {
            [self.menuDelegate menuDeactivated:self];
        }
    } else if (gesture == pan && isHighlighted) {
        point.x += diffX;
        point.y += diffY;
        [self moveTo:point animated:NO];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGPoint test = [touch locationInView:self];
    if (CGRectContainsPoint(self.displayItem.frame, test)
        || CGRectContainsPoint(self.highlightedItem.frame, test)) {
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
    self.highlightedItem = nil;
    self.displayItem = nil;
    self.menuView = nil;
}

#pragma mark - Selecting subviews

- (void)hoverOnItemAtIndex:(NSInteger)index inMenu:(JZMenu *)menu {
    UIView *item = [menuItems objectAtIndex:index];

    // Start timer countdown for selection
}

- (void)leftHoverOnItemAtIndex:(NSInteger)index inMenu:(JZMenu *)menu{
//    UIView *item = [menuItems objectAtIndex:index];
//    item.transform = CGAffineTransformIdentity;
}

#pragma mark - Some stuff to handle subview touches

-(id)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (CGRectContainsPoint(self.displayItem.frame, point) ||
        CGRectContainsPoint(self.highlightedItem.frame, point))
        return self;
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self)
        return nil;
    else
        return hitView;
}

@end
