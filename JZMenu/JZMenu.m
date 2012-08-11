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
#define kMenuLabelMargin 25.0f
#define kMainMenuTransform CGAffineTransformMakeScale(2.0, 2.0)

// Colors for the menu background
#define RGB(r,g,b, a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
#define kMenuColor RGB(0, 0, 0, 0.4)
#define kMenuHighlightedColor RGB(255, 255, 255, 0.5)
#define kMenuBlinkColor RGB(255, 255, 255, 1.0f)
#define kMenuCantHighlightColor RGB(255, 0, 0, 0.5)
#define kSubmenuTimerInterval 1.0f
#define kUserInfoDictKey @"menuItem"
#define kLabelFontHighlighted [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:24.0f]
#define kLabelFont [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:24.0f]

@interface JZMenu() {
    
    BOOL isHighlighted;
    
    // Origin difference for smother panning
    float diffX, diffY;
    NSMutableArray *menuItems;
    
    NSTimer *submenuTimer;
}

@property (nonatomic, strong) UIView* displayItem;
@property (nonatomic, strong) UIView* highlightedItem;
@property (nonatomic) CGRect parentFrame;
@property (nonatomic) JZMenuPosition position;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, weak) id<JZMenuDelegate> menuDelegate;
@property (nonatomic) int currentItemIndex;
@property (nonatomic, weak) JZMenu *activeSubmenu;
@property (nonatomic, assign) JZMenu *parentMenu;
@property (nonatomic, retain) NSArray *origItems;

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
@synthesize longPress, pan;
@synthesize activeSubmenu;
@synthesize parentMenu;
@synthesize origItems;

- (id)initWithHighlightedItemData:(id)highlightedData
                  displayItemData:(id)displayData
                        menuItems:(NSArray *)items
                         position:(JZMenuPosition)menuPosition
                      parentFrame:(CGRect)frame
                     menuDelegate:(id<JZMenuDelegate>)menuDelegate {
    if (self = [super initWithFrame:frame]) {
        self.parentFrame = frame;
        self.position = menuPosition;
        self.menuDelegate = menuDelegate;
        self.displayItem = [self configureMainItem:displayData highlighted:NO];
        self.highlightedItem = [self configureMainItem:highlightedData highlighted:YES];
        self.origItems = items;
        _currentItemIndex = -1;
        [self createMenuWith:items];
        [self config];
    }
    return self;
}

- (void)setCurrentItemIndex:(int)currentItemIndex {
    if (_currentItemIndex != currentItemIndex && currentItemIndex >= 0 && currentItemIndex < menuItems.count) {
        // Handle hovering
        [self leftHoverOnItemAtIndex:_currentItemIndex inMenu:self];
        _currentItemIndex = currentItemIndex;
        [self hoverOnItemAtIndex:_currentItemIndex inMenu:self];
        
        if ([self.menuDelegate respondsToSelector:@selector(hoverOnItemAtIndex:inMenu:)])
            [self.menuDelegate hoverOnItemAtIndex:_currentItemIndex inMenu:self];
    }
}

- (void)changeDisplayItemWith:(id)displayItemData {
    CGPoint center = self.displayItem.center;
    [UIView animateWithDuration:kAnimationDuration
                          delay:kAnimationDuration * 2
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.displayItem.alpha = 0;
                     } completion:^(BOOL finished) {
                         if (finished) {
                             if ([self.displayItem isKindOfClass:[UILabel class]]) {
                                 [(UILabel*)self.displayItem setText:displayItemData];
//                                 [self.displayItem sizeToFit];
                                 [self resizeItem:self.displayItem];
                                 self.displayItem.center = center;
                             } else if ([self.displayItem isKindOfClass:[UIImageView class]]) {
                                 [(UIImageView*)self.displayItem setImage:displayItemData];
                             }

                             [UIView animateWithDuration:kAnimationDuration
                                              animations:^{
                                                  self.displayItem.alpha = 1;
                                              }];
                         }
                     }];
}

- (void)changeHighlightedItemWith:(id)highlightedItemData {
//     self.highlightedItem = [self configureMainItem:highlightedItemData highlighted:YES];
    
    [UIView animateWithDuration:kAnimationDuration
                          delay:kAnimationDuration
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.highlightedItem.alpha = 0;
                     } completion:^(BOOL finished) {
                         if (finished) {
                             if ([self.highlightedItem isKindOfClass:[UILabel class]]) {
                                 // This still ned fixing
                                 [(UILabel*)self.highlightedItem setText:highlightedItemData];

//                                 float newX = center.x + (frame.size.width - self.highlightedItem.frame.size.width) / 2;
//                                 float newY = center.y + (frame.size.height - self.highlightedItem.frame.size.height) / 2;
//                                 CGPoint newCenter = CGPointMake(newX, newY);
//                                 diffX -= fabs(center.x - newCenter.x);
//                                 diffY -= fabs(center.y - newCenter.y);
//                                 NSLog(@"old frame: %@, new frame: %@", NSStringFromCGRect(frame), NSStringFromCGRect(self.highlightedItem.frame));
//                                 self.highlightedItem.center = newCenter;
                             } else if ([self.highlightedItem isKindOfClass:[UIImageView class]]) {
                                 [(UIImageView*)self.highlightedItem setImage:highlightedItemData];
                                 
                             }
                             [UIView animateWithDuration:kAnimationDuration
                                              animations:^{
                                                  self.highlightedItem.alpha = 1;
                                              }];
                         }
                     }];
}

#pragma mark - Config

- (UITextAlignment)alignmentForPosition {
    if (self.position & JZMenuPositionLeft && !(self.position & JZMenuPositionRight)) {
        return UITextAlignmentLeft;
    }
    else if (self.position & JZMenuPositionRight && !(self.position & JZMenuPositionLeft)) {
        return UITextAlignmentRight;
    } else
        return UITextAlignmentCenter;
}

- (CGRect)addPaddingTo:(CGRect)rect {
    rect.origin.x -= kMenuLabelMargin / 2;
    rect.origin.y -= kMenuLabelMargin / 2;
    rect.size.width += kMenuLabelMargin;
    rect.size.height += kMenuLabelMargin;
    return rect;
}

- (void)resizeItem:(UIView*)item {
    CGPoint originPoint = [self originPoint];
    CGSize size = CGSizeMake(kStartMenuItemSize, kStartMenuItemSize);
    if ([item isKindOfClass:[UIImageView class]]) {
        [(UIImageView*)item setFrame:CGRectMake(originPoint.x, originPoint.y, size.width, size.height)];
    } else if ([item isKindOfClass:[UILabel class]]) {
        CGRect labelRect = CGRectMake(kMenuItemLabelPadding,
                                      kMenuItemLabelPadding,
                                      self.frame.size.width - 2 * kMenuItemLabelPadding,
                                      self.frame.size.height - 2 * kMenuItemLabelPadding);
        item.frame = labelRect;
        [item sizeToFit];
        item.frame = [self addPaddingTo:item.frame];
        [item setCenter:[self centerPointForOrigin:[self originPoint]]];
    }
}

- (UIView*)configureMainItem:(id)data highlighted:(BOOL)highlighted {
    UIView *item;
    if ([data isKindOfClass:[UIImage class]]) {
        item = [[UIImageView alloc] initWithImage:data];
        [(UIImageView*)item setContentMode:UIViewContentModeScaleAspectFit];
        [self addSubview:item];
    } else if ([data isKindOfClass:[NSString class]]) {
        item = [[UILabel alloc] init];
        item.backgroundColor = [UIColor clearColor];
        if (highlighted)
            [(UILabel*)item setFont:kLabelFontHighlighted];
        else
            [(UILabel*)item setFont:kLabelFont];
        [(UILabel*)item setTextAlignment:[self alignmentForPosition]];
        [(UILabel*)item setText:data];
        [self addSubview:item];
    }
    [self resizeItem:item];
    
    item.hidden = highlighted;
    
    return item;
}

- (CGPoint)centerPointForOrigin:(CGPoint)origin {
    return CGPointMake(origin.x + self.displayItem.frame.size.width / 2, origin.y + self.displayItem.frame.size.height / 2);
}

- (CGPoint)originPoint {
    float x, y;
    
    if (self.position & JZMenuPositionTop && !(self.position & JZMenuPositionBottom)) {
        y = 0;
    } else if (self.position & JZMenuPositionBottom && !(self.position & JZMenuPositionTop)) {
        y = self.frame.size.height - self.displayItem.frame.size.height;
    } else {
        y = self.frame.size.height / 2 - self.displayItem.frame.size.height / 2;
    }
    
    if (self.position & JZMenuPositionLeft && !(self.position & JZMenuPositionRight)) {
        x = 0;
    } else if (self.position & JZMenuPositionRight && !(self.position & JZMenuPositionLeft)) {
        x = self.frame.size.width - self.displayItem.frame.size.width;
    } else {
        x = self.frame.size.width / 2 - self.displayItem.frame.size.width / 2;
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
        CGRect imageRect = CGRectMake(frame.size.width / 2 - kMenuItemImageSize / 2,
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
        label.font = kLabelFont;
        label.textAlignment = UITextAlignmentCenter;
        label.text = object;
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor blackColor];
        [menuItem addSubview:label];
    } else if ([object isKindOfClass:[JZMenu class]]) {
        // Create a submenu with display item of the object's menu
        [[object displayItem] setFrame:CGRectMake(0,
                                    0,
                                    frame.size.width,
                                    frame.size.height)];
        [object setLongPress:self.longPress];
        [object setPan:self.pan];
        [menuItem addSubview:[object displayItem]];
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
                             [_menuView removeFromSuperview];
                             _menuView = nil;
                             [self createMenuWith:origItems];
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

- (void)resetMove:(BOOL)animated withCallback:(void(^)(BOOL))callback {
    _currentItemIndex = -1;
    [self changeSelection:NO];
    
    // Submenu stuff
    [submenuTimer invalidate];
    submenuTimer = nil;
//    [self deactivateSubmenu];
    
    // Parent menu stuff
    if (parentMenu) {
        parentMenu.displayItem.center = self.displayItem.center;
        parentMenu.highlightedItem.center = self.highlightedItem.center;
        callback = ^(BOOL finished){
            if (finished) {
                [parentMenu deactivateSubmenu];
            }
        };
        [parentMenu resetMove:YES withCallback:callback];
    } else {
        [self moveTo:[self centerPointForOrigin:[self originPoint]] animated:animated withCallback:callback];
    }
}

- (void)moveTo:(CGPoint)point animated:(BOOL)animated withCallback:(void(^)(BOOL))callback {
    if (!CGPointEqualToPoint(self.displayItem.center, point) ||
        !CGPointEqualToPoint(self.highlightedItem.center, point)) {
        if (animated) {
            [UIView animateWithDuration:kAnimationDuration
                                  delay:kAnimationDelay
                                options:UIViewAnimationOptionAllowUserInteraction
                             animations:^{
                                 self.displayItem.center = point;
                                 self.highlightedItem.center = point;
                             } completion:^(BOOL finished) {
                                 if (callback)
                                     callback(finished);
                                 
                             }];
        } else {
            self.displayItem.center = self.highlightedItem.center = point;
            if (callback)
                callback(YES);
        }
        if ([self gesturesNotIdle]) {
            [self highlightMenuItemAtPoint:point];
        }
    }
}

- (BOOL)gesturesNotIdle {
   return (longPress.state != UIGestureRecognizerStateEnded && longPress.state != UIGestureRecognizerStateFailed
         && longPress.state != UIGestureRecognizerStateCancelled) &&
        (pan.state != UIGestureRecognizerStateEnded && pan.state != UIGestureRecognizerStateFailed
         && pan.state != UIGestureRecognizerStateCancelled);
}

- (void)handleGesture:(UIGestureRecognizer*)gesture {
    if (activeSubmenu) {
        [activeSubmenu handleGesture:gesture];
        return;
    }
    
    CGPoint point = [gesture locationInView:self];
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self changeSelection:YES];
        if (gesture == pan) {
            NSLog(@"Gesture began in: %@", self);
            CGPoint pointInSelf = [gesture locationInView:self.displayItem];
            diffX = (self.displayItem.frame.size.width / 2 - pointInSelf.x);
            diffY = (self.displayItem.frame.size.height / 2 - pointInSelf.y);
        } else {
            // The gesture is long press, just highlight the item
//            [self highlightMenuItemAtPoint:point];
        }
        if (self.menuDelegate && [self.menuDelegate respondsToSelector:@selector(menuActivated:)]) {
            [self.menuDelegate menuActivated:self];
        }
    } else if ((gesture.state == UIGestureRecognizerStateEnded ||
                gesture.state == UIGestureRecognizerStateCancelled ||
                gesture.state == UIGestureRecognizerStateFailed) && isHighlighted) { // Only recognize the gesture if the menu item is highlighted
        [self resetMove:YES withCallback:nil];
        // If the gesture isn't cancelled, we notify the delegate
        if (gesture.state != UIGestureRecognizerStateCancelled ||
            gesture.state == UIGestureRecognizerStateFailed) {
            
            NSInteger highlightedItemIndex = [self highlightedItemIndexAt:point];
            // Cleanup possible submenu stuff
            [self leftHoverOnItemAtIndex:highlightedItemIndex inMenu:self];
            
            // Notify delegate
            if (highlightedItemIndex >= 0 && self.menuDelegate &&
                (([self.menuDelegate respondsToSelector:@selector(canSelectItemAtIndex:inMenu:)] &&
                 [self.menuDelegate canSelectItemAtIndex:highlightedItemIndex inMenu:self]) ||
                 ![self.menuDelegate respondsToSelector:@selector(canSelectItemAtIndex:inMenu:)]))
            {
                    [self.menuDelegate didSelectItemAtIndex:highlightedItemIndex inMenu:self];
            }
        }
        if (self.menuDelegate && [self.menuDelegate respondsToSelector:@selector(menuDeactivated:)]) {
            [self.menuDelegate menuDeactivated:self];
        }
    } else if (gesture == pan && isHighlighted) {
        point.x += diffX;
        point.y += diffY;
        [self moveTo:point animated:NO withCallback:nil];
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

#pragma mark - Selecting submenus

- (void)activateSubmenu:(JZMenu*)submenu {
    activeSubmenu = submenu;
    activeSubmenu->parentMenu = self;
    [self hideMenu];
    self.highlightedItem.hidden = YES;
    [self addSubview:activeSubmenu];
    [self.superview bringSubviewToFront:activeSubmenu];
    [activeSubmenu changeSelection:YES];
    CGPoint currentCenter = self.highlightedItem.center;
    float newX = currentCenter.x + (self.highlightedItem.frame.size.width - activeSubmenu.highlightedItem.frame.size.width) / 2;
    float newY = currentCenter.y + (self.highlightedItem.frame.size.height - activeSubmenu.highlightedItem.frame.size.height) / 2;
    CGPoint newCenter = CGPointMake(newX, newY);
    activeSubmenu->diffX = diffX - fabs(currentCenter.x - newCenter.x);
    activeSubmenu->diffY = diffY - fabs(currentCenter.y - newCenter.y);
    
    [activeSubmenu highlightedItem].center = newCenter;
    [activeSubmenu displayItem].center = newCenter;

    CGPoint highlightedItemPoint = [activeSubmenu highlightedItem].center;
    [activeSubmenu highlightMenuItemAtPoint:highlightedItemPoint];
}

- (void)deactivateSubmenu {
    NSLog(@"Deactivating submenu");
    [activeSubmenu removeFromSuperview];
    activeSubmenu = nil;
}

- (void)longHover:(NSTimer*)timer {
    NSLog(@"Long hover");
     // Get item and handle long press according to class
    NSInteger itemIndex = (NSInteger)[[[timer userInfo] objectForKey:kUserInfoDictKey] intValue];
    
    UIView *menuItem = [menuItems objectAtIndex:itemIndex];
    id menu = [origItems objectAtIndex:itemIndex];
    if ([menu isKindOfClass:[JZMenu class]]) {
        UIColor *originalColor = menuItem.backgroundColor;
        [UIView animateWithDuration:0.15f
                              delay:0
                            options:UIViewAnimationOptionRepeat
                         animations:^{
                             [UIView setAnimationRepeatCount:2.0f];
                             menuItem.backgroundColor = kMenuBlinkColor;
                             menuItem.backgroundColor = originalColor;
                         } completion:^(BOOL finished) {
                             if (submenuTimer && finished)
                                 [self activateSubmenu:menu];
                         }];
    } else {
        if ([self.menuDelegate respondsToSelector:@selector(longHoverOnItemAtIndex:inMenu:)] &&
            [self.menuDelegate animateOnLongHover:itemIndex inMenu:self]) {
            // Animate and activate long hover action
            UIColor *originalColor = menuItem.backgroundColor;
            [UIView animateWithDuration:0.15f
                                  delay:0
                                options:UIViewAnimationOptionRepeat
                             animations:^{
                                 [UIView setAnimationRepeatCount:2.0f];
                                 menuItem.backgroundColor = [UIColor clearColor];
                                 menuItem.backgroundColor = originalColor;
                             } completion:^(BOOL finished) {
                                 if ([self.menuDelegate respondsToSelector:@selector(longHoverOnItemAtIndex:inMenu:)]) {
                                     [self.menuDelegate longHoverOnItemAtIndex:itemIndex inMenu:self];
                                 }
                             }];
        } else if ([self.menuDelegate respondsToSelector:@selector(longHoverOnItemAtIndex:inMenu:)]) {
            // Dont animate - only activate the long hover action
            [self.menuDelegate longHoverOnItemAtIndex:itemIndex inMenu:self];
        }
    }
}

- (void)hoverOnItemAtIndex:(NSInteger)index inMenu:(JZMenu *)menu {
    // Start timer countdown for selection
    if (![submenuTimer isValid]) {
        submenuTimer = [NSTimer scheduledTimerWithTimeInterval:kSubmenuTimerInterval target:self selector:@selector(longHover:) userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:index] forKey:kUserInfoDictKey] repeats:NO];
    }
}

- (void)leftHoverOnItemAtIndex:(NSInteger)index inMenu:(JZMenu *)menu{
    if ([submenuTimer isValid]) {
        [submenuTimer invalidate];
        submenuTimer = nil;
    }
}

#pragma mark - Some stuff to handle subview touches

-(id)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (CGRectContainsPoint(self.displayItem.frame, point) ||
        CGRectContainsPoint(self.highlightedItem.frame, point))
        return self;
    
    UIView *hitView = [super hitTest:point withEvent:event];
    NSLog(@"hitView class: %@", [hitView class]);
    if (hitView == self)
        return nil;
    else
        return hitView;
}

@end
