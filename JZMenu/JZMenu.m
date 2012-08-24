//
//  JZMenu.m
//  JZMenu
//
//  Created by Jure Zove on 6. 08. 12.
//  Copyright (c) 2012 Jure Zove. All rights reserved.
//

#import "JZMenu.h"

#define kStartMenuItemSize 90.0f
#define kAnimationDuration 0.25f
#define kAnimationDelay 0.1f
#define kMenuItemImageSize 90.0f
#define kMenuItemLabelPadding 10.0f
#define kMenuLabelMargin 25.0f
#define kMainMenuTransform CGAffineTransformMakeScale(1.5, 1.5)
#define kMinimumItemHeight (480.0f / 5.0f)
#define kAutoScrollTreshold 120.0f
#define kAutoScrollTresholdPercentage 1.4f

// Colors for the menu background
#define RGB(r,g,b, a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
//#define kMenuColor RGB(0, 0, 0, 0.4)
#define kMenuHighlightedColor RGB(150, 150, 150, 0.9)
#define kMenuBlinkColor RGB(255, 255, 255, 1.0f)
#define kMenuCantHighlightColor RGB(255, 0, 0, 0.5)
#define kMenuItemTextColor RGB (255, 255, 255, 1)
#define kSubmenuTimerInterval 1.0f
#define kUserInfoDictKey @"menuItem"
#define kLabelFontHighlighted [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:24.0f]
#define kLabelFont [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:24.0f]

#define kMenuItemActualViewTag 45367

@interface JZMenu() {
    
    BOOL isHighlighted;
    
    // Origin difference for smother panning
    float diffX, diffY;
    
    NSTimer *submenuTimer;
    
    float transparency;
    
    CADisplayLink *displayLink;
    BOOL autoScroll;
    float dAutoScroll;
}

@property (nonatomic, strong) UIView* displayItem;
@property (nonatomic, strong) UIView* highlightedItem;
@property (nonatomic) CGRect parentFrame;
@property (nonatomic) JZMenuPosition position;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, weak) id<JZMenuDelegate> menuDelegate;
@property (nonatomic) int currentItemIndex;
@property (nonatomic, weak) JZMenu *activeSubmenu;
@property (nonatomic, weak) JZMenu *parentMenu;
@property (nonatomic, retain) NSArray *origItems;
@property (nonatomic, strong) NSMutableArray *menuItems;
@property (nonatomic, getter = isMenuActive) BOOL menuActive;

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
@synthesize longPress, pan, tap;
@synthesize activeSubmenu;
@synthesize parentMenu;
@synthesize origItems;
@synthesize menuItems;
@synthesize displayItemOffset;

- (id)initWithHighlightedItemData:(id)highlightedData
                  displayItemData:(id)displayData
                        menuItems:(NSArray *)items
                         position:(JZMenuPosition)menuPosition
                      parentFrame:(CGRect)frame
                     menuDelegate:(id<JZMenuDelegate>)menuDelegate
                     transparency:(float)alpha {
    if (self = [super initWithFrame:frame]) {
        self.displayItemOffset = 0;
        self.parentFrame = frame;
        self.position = menuPosition;
        self.menuDelegate = menuDelegate;
        self.displayItem = [self configureMainItem:displayData highlighted:NO];
        self.highlightedItem = [self configureMainItem:highlightedData highlighted:YES];
        self.origItems = items;
        _currentItemIndex = -1;
        transparency = alpha;
        [self createMenuWith:self.origItems];
        [self config];
    }
    return self;
}

- (id)initWithHighlightedItemData:(id)highlightedData
                  displayItemData:(id)displayData
                        menuItems:(NSArray *)items
                         position:(JZMenuPosition)menuPosition
                      parentFrame:(CGRect)frame
                     menuDelegate:(id<JZMenuDelegate>)menuDelegate
                     transparency:(float)alpha
                displayItemOffset:(float)displayItemOffset_ {
    if (self = [super initWithFrame:frame]) {
        self.displayItemOffset = displayItemOffset_;
        self.parentFrame = frame;
        self.position = menuPosition;
        self.menuDelegate = menuDelegate;
        self.displayItem = [self configureMainItem:displayData highlighted:NO];
        self.highlightedItem = [self configureMainItem:highlightedData highlighted:YES];
        self.origItems = items;
        _currentItemIndex = -1;
        transparency = alpha;
        [self createMenuWith:self.origItems];
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
        
        if ([self.menuDelegate respondsToSelector:@selector(menu:hoverOnItemAtIndex:)])
            [self.menuDelegate menu:self hoverOnItemAtIndex:_currentItemIndex];
    } else if (currentItemIndex == -1)
        _currentItemIndex = -1;
}

- (void)changeItem:(UIView*)item withData:(id)itemData animated:(BOOL)animated {
    CGPoint center = item.center;
    if (animated) {
        [UIView animateWithDuration:kAnimationDuration
                              delay:kAnimationDuration * 2
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             item.alpha = 0;
                         } completion:^(BOOL finished) {
                             if ([item isKindOfClass:[UILabel class]] && [itemData isKindOfClass:[NSString class]]) {
                                 [(UILabel*)item setText:itemData];
                                 [self resizeItem:item];
                                 item.center = center;
                             } else if ([item isKindOfClass:[UIImageView class]] && [itemData isKindOfClass:[UIImage class]]) {
                                 [(UIImageView*)item setImage:itemData];
                             }
                             
                             [UIView animateWithDuration:kAnimationDuration
                                              animations:^{
                                                  item.alpha = 1;
                                              }];
                         }];
    } else {
        if ([item isKindOfClass:[UILabel class]] && [itemData isKindOfClass:[NSString class]]) {
            [(UILabel*)item setText:itemData];
            [self resizeItem:item];
            item.center = center;
        } else if ([item isKindOfClass:[UIImageView class]] && [itemData isKindOfClass:[UIImage class]]) {
            [(UIImageView*)item setImage:itemData];
        }
    }
}

- (void)changeDisplayItemWith:(id)displayItemData animated:(BOOL)animated {
    [self changeItem:self.displayItem withData:displayItemData animated:animated];
}

- (void)changeHighlightedItemWith:(id)highlightedItemData animated:(BOOL)animated {
    [self changeItem:self.highlightedItem withData:highlightedItemData animated:animated];
}

- (void)replaceMenuItemsWith:(NSArray *)newItems {
    self.origItems = nil;
    self.origItems = newItems;
    [self createMenuWith:self.origItems];
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
    CGSize size = CGSizeMake(kStartMenuItemSize, kStartMenuItemSize);
    if ([item isKindOfClass:[UIImageView class]]) {
        CGPoint originPoint = [self originPointForSize:size];
        [(UIImageView*)item setFrame:CGRectMake(originPoint.x, originPoint.y, size.width, size.height)];
    } else if ([item isKindOfClass:[UILabel class]]) {
        CGRect labelRect = CGRectMake(kMenuItemLabelPadding,
                                      kMenuItemLabelPadding,
                                      self.frame.size.width - 2 * kMenuItemLabelPadding,
                                      self.frame.size.height - 2 * kMenuItemLabelPadding);
        item.frame = labelRect;
        [item sizeToFit];
        item.frame = [self addPaddingTo:item.frame];
        CGPoint originPoint = [self originPointForSize:item.frame.size];
//        CGPoint originPoint = [self originPointFor:item];
        [item setCenter:[self centerPointForOrigin:originPoint andView:item]];
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
        [(UILabel*)item setTextColor:kMenuItemTextColor];
        [(UILabel*)item setTextAlignment:[self alignmentForPosition]];
        [(UILabel*)item setText:data];
        [self addSubview:item];
    }
    [self resizeItem:item];
    
    item.hidden = highlighted;
    
    return item;
}

- (CGPoint)centerPointForOrigin:(CGPoint)origin andView:(UIView*)view {
    float x, y;
    if (self.position & JZMenuPositionTop && !(self.position & JZMenuPositionBottom)) {
        y = origin.y - displayItemOffset;
    } else if (self.position & JZMenuPositionBottom && !(self.position & JZMenuPositionTop)) {
        y = origin.y + displayItemOffset;
    } else {
        y = origin.y;
    }
    
    if (self.position & JZMenuPositionLeft && !(self.position & JZMenuPositionRight)) {
        x = origin.x - displayItemOffset;
    } else if (self.position & JZMenuPositionRight && !(self.position & JZMenuPositionLeft)) {
        x = origin.x + displayItemOffset;
    } else {
        x = origin.x;
    }
        
    return CGPointMake(x+ view.frame.size.width / 2, y + view.frame.size.height / 2);
}

- (CGPoint)originPointForSize:(CGSize)size {
    float x, y;
    
    if (self.position & JZMenuPositionTop && !(self.position & JZMenuPositionBottom)) {
        y = 0 - displayItemOffset;
    } else if (self.position & JZMenuPositionBottom && !(self.position & JZMenuPositionTop)) {
        y = self.frame.size.height - size.height + displayItemOffset;
    } else {
        y = self.frame.size.height / 2 - size.height / 2;
    }
    
    if (self.position & JZMenuPositionLeft && !(self.position & JZMenuPositionRight)) {
        x = 0 - displayItemOffset;
    } else if (self.position & JZMenuPositionRight && !(self.position & JZMenuPositionLeft)) {
        x = self.frame.size.width - size.width + displayItemOffset;
    } else {
        x = self.frame.size.width / 2 - size.width / 2;
    }
    
    return CGPointMake(x, y);
}

- (CGPoint)originPointFor:(UIView*)view {
    float x, y;
    
    if (self.position & JZMenuPositionTop && !(self.position & JZMenuPositionBottom)) {
        y = 0;
    } else if (self.position & JZMenuPositionBottom && !(self.position & JZMenuPositionTop)) {
        y = self.frame.size.height - view.frame.size.height;
    } else {
        y = self.frame.size.height / 2 - view.frame.size.height / 2;
    }
    
    if (self.position & JZMenuPositionLeft && !(self.position & JZMenuPositionRight)) {
        x = 0;
    } else if (self.position & JZMenuPositionRight && !(self.position & JZMenuPositionLeft)) {
        x = self.frame.size.width - view.frame.size.width;
    } else {
        x = self.frame.size.width / 2 - view.frame.size.width / 2;
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
    
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tap.delegate = self;
    tap.cancelsTouchesInView = NO;
    [self addGestureRecognizer:tap];
    
    self.backgroundColor = [UIColor clearColor];

}

- (void)createMenuItemWith:(id)object andFrame:(CGRect)frame {
    // Menu item
    UIView *menuItem = [[UIView alloc] initWithFrame:frame];
    menuItem.layer.borderColor = [UIColor whiteColor].CGColor;
    menuItem.layer.borderWidth = 1.0f;
//    menuItem.backgroundColor = kMenuColor;
    menuItem.backgroundColor = RGB(0, 0, 0, transparency);
//    menuItem.backgroundColor = [UIColor redColor];
    
    if ([object isKindOfClass:[UIImage class]]) {
        // Menu image
        CGRect imageRect = CGRectMake(frame.size.width / 2 - kMenuItemImageSize / 2,
                                      frame.size.height / 2 - kMenuItemImageSize / 2,
                                      kMenuItemImageSize,
                                      kMenuItemImageSize);
        UIImageView *image = [[UIImageView alloc] initWithFrame:imageRect];
        image.image = object;
        image.contentMode = UIViewContentModeCenter;
        image.tag = kMenuItemActualViewTag;
        [menuItem addSubview:image];
    } else if ([object isKindOfClass:[NSString class]]) {
        CGRect labelRect = CGRectMake(kMenuItemLabelPadding,
                                      kMenuItemLabelPadding,
                                      frame.size.width - 2 * kMenuItemLabelPadding,
                                      frame.size.height - 2 * kMenuItemLabelPadding);
        UILabel *label = [[UILabel alloc] initWithFrame:labelRect];
        label.font = kLabelFont;
        label.textAlignment = UITextAlignmentCenter;
        label.text = [NSString stringWithFormat:@"%@", object];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = kMenuItemTextColor;
        label.tag = kMenuItemActualViewTag;
        [menuItem addSubview:label];
    } else if ([object isKindOfClass:[JZMenu class]]) {
        // Create a submenu with display item of the object's menu
        [[object displayItem] setFrame:CGRectMake(0,
                                    0,
                                    frame.size.width,
                                    frame.size.height)];
        [object setLongPress:self.longPress];
        [object setPan:self.pan];
        [object displayItem].hidden = NO;
        [object displayItem].alpha = 1.0f;
        [menuItem addSubview:[object displayItem]];
    }
    [self.menuView addSubview:menuItem];
    [menuItems addObject:menuItem];
}

- (void)createMenuWith:(NSArray*)items {
    float sizeOfMenuItem = (float)self.frame.size.height / items.count;
    if (sizeOfMenuItem < kMinimumItemHeight) {
        sizeOfMenuItem = kMinimumItemHeight;
        self.menuView = [[UIScrollView alloc] initWithFrame:self.bounds];
        [(UIScrollView*)self.menuView setContentSize:CGSizeMake(self.menuView.frame.size.width, sizeOfMenuItem * items.count)];
        displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateScroll)];
    } else {
        self.menuView = [[UIView alloc] initWithFrame:self.bounds];
    }
    
    self.menuView.backgroundColor = [UIColor clearColor];
    self.menuView.hidden = YES;
    [self addSubview:self.menuView];
    [self sendSubviewToBack:self.menuView];
    
    // Menu items
    menuItems = [[NSMutableArray alloc] initWithCapacity:items.count];
    
    for (int i = 0; i < items.count; i++) {
        CGRect frame = CGRectMake(0,
                                  i * sizeOfMenuItem,
                                  self.frame.size.width,
                                  sizeOfMenuItem);
        
        [self createMenuItemWith:[items objectAtIndex:i] andFrame:frame];
    }
}

- (BOOL)canReplaceMenuItemView:(UIView*)view withItemData:(id)data {
    if (([data isKindOfClass:[NSString class]] && [view isKindOfClass:[UILabel class]]) ||
        ([data isKindOfClass:[UIImage class]] && [view isKindOfClass:[UIImageView class]])) {
        return YES;
    }
    return NO;
}
        

- (void)updateMenuItemView:(UIView*)view withItemData:(id)data {
    if ([data isKindOfClass:[NSString class]] && [view isKindOfClass:[UILabel class]]) {
        [(UILabel*)view setText:data];
    } else if ([data isKindOfClass:[UIImage class]] && [view isKindOfClass:[UIImageView class]]) {
        [(UIImageView*)view setImage:data];
    }
}

- (void)updateMenuItemAtIndex:(NSInteger)index withItemData:(id)data animated:(BOOL)animated {
    UIView *view = [[menuItems objectAtIndex:index] viewWithTag:kMenuItemActualViewTag];
    if ([self canReplaceMenuItemView:view withItemData:data]) {
        if (animated) {
            [UIView animateWithDuration:kAnimationDuration / 2
                             animations:^{
                                 view.alpha = 0;
                             } completion:^(BOOL finished) {
                                 [self updateMenuItemView:view withItemData:data];
                                 [UIView animateWithDuration:kAnimationDuration / 2
                                                  animations:^{
                                                      view.alpha = 1.0f;
                                                  }];
                             }];
        } else {
            [self updateMenuItemView:view withItemData:data];
        }
    } else {
        [self updateMenuItemView:view withItemData:data];
    }
}


#pragma mark - Auto scroll

- (void)disableAutoScroll {
    autoScroll = NO;
    [displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)enableAutoScroll {
    if (!autoScroll) {
        [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        autoScroll = YES;
    }
}

- (void)updateScroll {
    CGPoint offset = [(UIScrollView*)self.menuView contentOffset];
//    NSLog(@"Offset: %f", dAutoScroll);
    if (dAutoScroll > 0) {
        if (offset.y + dAutoScroll + [(UIScrollView*)self.menuView frame].size.height < [(UIScrollView*)self.menuView contentSize].height) {
            offset.y+=dAutoScroll;
            [(UIScrollView*)self.menuView setContentOffset:offset animated:NO];
        } else {
            offset.y = [(UIScrollView*)self.menuView contentSize].height - self.menuView.frame.size.height;
            [(UIScrollView*)self.menuView setContentOffset:offset animated:NO];
            [self disableAutoScroll];
        }
    } else {
        if (offset.y + dAutoScroll > 0) {
            offset.y+=dAutoScroll;
            [(UIScrollView*)self.menuView setContentOffset:offset animated:NO];
        } else {
            offset.y = 0;
            [(UIScrollView*)self.menuView setContentOffset:offset animated:NO];
            [self disableAutoScroll];
        }
    }
}

#pragma mark - Menu stuff

- (void)showMenu {
    [self menuView].hidden = NO;
    [self menuView].alpha = 0;
    [UIView animateWithDuration:kAnimationDuration
                    animations:^{
                        [self menuView].alpha = 1.0f;
                    }];

}

- (void)hideMenu {
    [self disableAutoScroll];
    [UIView animateWithDuration:kAnimationDuration
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         [self menuView].alpha = 0;
                     } completion:^(BOOL finished) {
                         if (finished) {
                             [self menuView].hidden = YES;
                             UIView *v = [self.menuView viewWithTag:kMenuItemActualViewTag];
                             [v removeFromSuperview];
                             [menuItems removeAllObjects];
                             menuItems = nil;
                             [self.menuView removeFromSuperview];
                             self.menuView = nil;
                             [self createMenuWith:origItems];
                         }
                     }];
}

- (NSInteger)highlightedItemIndexAt:(CGPoint)point {
    CGPoint relativePoint = [self.menuView convertPoint:point fromView:nil];
    int highlightedItemIndex = -1;
    for (int i = 0; i < menuItems.count; i++) {
        UIView *menuItem = [menuItems objectAtIndex:i];
        if (CGRectContainsPoint(menuItem.frame, relativePoint)) {
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
    if (newHighlightedItemIndex == -1)
        self.currentItemIndex = -1;
}

- (void)layoutMenuItems:(NSInteger)highlightedItemIndex {
    self.currentItemIndex = highlightedItemIndex;
    for (int i = 0; i < menuItems.count; i++) {
        [UIView animateWithDuration:kAnimationDuration
                         animations:^{
                             if (i == highlightedItemIndex) {
                                 // Check if we can highlight the current item - if the delegate isnt responding, we highlight it normally
                                 if (highlightedItemIndex >= 0 && ((self.menuDelegate &&
                                                                    [self.menuDelegate respondsToSelector:@selector(menu:canSelectItemAtIndex:)] &&
                                     [self.menuDelegate menu:self canSelectItemAtIndex:highlightedItemIndex]) ||
                                                                   ![self.menuDelegate respondsToSelector:@selector(menu:canSelectItemAtIndex:)]) ) {
                                     [(UIView*)[menuItems objectAtIndex:i] setBackgroundColor:kMenuHighlightedColor];
                                 } else {
                                     [(UIView*)[menuItems objectAtIndex:i] setBackgroundColor:kMenuCantHighlightColor];
                                 }
                             } else {
//                                 [(UIView*)[menuItems objectAtIndex:i] setBackgroundColor:kMenuColor];
                                 [(UIView*)[menuItems objectAtIndex:i] setBackgroundColor:RGB(0, 0, 0, transparency)];
//                                 [(UIView*)[menuItems objectAtIndex:i] setBackgroundColor:[UIColor blackColor]];
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
        
        // Check if we can activate the menu
        if (([self.menuDelegate respondsToSelector:@selector(canActivateMenu:)] && ![self.menuDelegate canActivateMenu:self]))
            return;
        
        
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

- (void)resetMove:(BOOL)animated withCallback:(JZMenuDidSelectItemFinishedBlock)callback {
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
        JZMenuDidSelectItemFinishedBlock parentCallback = ^(BOOL finished){
            if (finished) {
                [parentMenu deactivateSubmenu];
            }
            if (callback)
                callback(finished);
        };
        [parentMenu resetMove:YES withCallback:parentCallback];
    } else {
        [self moveTo:[self centerPointForOrigin:[self originPointFor:self.displayItem] andView:self.displayItem] animated:animated withCallback:callback];
    }
}

- (void)moveTo:(CGPoint)point animated:(BOOL)animated withCallback:(JZMenuDidSelectItemFinishedBlock)callback {
    if (!CGPointEqualToPoint(self.displayItem.center, point) ||
        !CGPointEqualToPoint(self.highlightedItem.center, point)) {
        if (animated) {
            [UIView animateWithDuration:kAnimationDuration
                                  delay:kAnimationDelay
                                options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut
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
            
            // Scrollview
            if ([self.menuView isKindOfClass:[UIScrollView class]]) {
                if (point.y >= self.bounds.size.height - kAutoScrollTreshold && [(UIScrollView*)self.menuView contentOffset].y + self.menuView.bounds.size.height < [(UIScrollView*)self.menuView contentSize].height) {
                    dAutoScroll = (kAutoScrollTreshold*kAutoScrollTresholdPercentage - (self.bounds.size.height - point.y)) / 10;
                    [self enableAutoScroll];
                } else if (point.y <= kAutoScrollTreshold && [(UIScrollView*)self.menuView contentOffset].y > 0) {
                    dAutoScroll = -(kAutoScrollTreshold*kAutoScrollTresholdPercentage - point.y) / 10;
                    [self enableAutoScroll];
                }
                else {
                    if (autoScroll) {
                        [self disableAutoScroll];
                    }
                }
            }
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
         && pan.state != UIGestureRecognizerStateCancelled && !autoScroll);
}

- (void)handleGesture:(UIGestureRecognizer*)gesture {
    if (activeSubmenu) {
        [activeSubmenu handleGesture:gesture];
        return;
    }
    
    CGPoint point = [gesture locationInView:self];
    point.x += diffX;
    point.y += diffY;
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self changeSelection:YES];
        if (gesture == pan) {
            CGPoint pointInSelf = [gesture locationInView:self.displayItem];
            diffX = (self.displayItem.frame.size.width / 2 - pointInSelf.x);
            diffY = (self.displayItem.frame.size.height / 2 - pointInSelf.y);
        } else {
            // The gesture is long press, just highlight the item
//            [self highlightMenuItemAtPoint:point];
        }
    [self activateMenu];
    } else if ((gesture.state == UIGestureRecognizerStateEnded ||
                gesture.state == UIGestureRecognizerStateCancelled ||
                gesture.state == UIGestureRecognizerStateFailed) && isHighlighted) { // Only recognize the gesture if the menu item is highlighted
        JZMenuDidSelectItemFinishedBlock finishedBlock;
        // If the gesture isn't cancelled, we notify the delegate
        if (gesture.state != UIGestureRecognizerStateCancelled ||
            gesture.state == UIGestureRecognizerStateFailed) {
            
            NSInteger highlightedItemIndex = [self highlightedItemIndexAt:point];
            // Cleanup possible submenu stuff
            [self leftHoverOnItemAtIndex:highlightedItemIndex inMenu:self];
            
            // Notify delegate
            if (highlightedItemIndex >= 0 && self.menuDelegate &&
                (([self.menuDelegate respondsToSelector:@selector(menu:canSelectItemAtIndex:)] &&
                 [self.menuDelegate menu:self canSelectItemAtIndex:highlightedItemIndex]) ||
                 ![self.menuDelegate respondsToSelector:@selector(menu:canSelectItemAtIndex:)]))
            {
                if ([self.menuDelegate respondsToSelector:@selector(menu:didSelectItemAtIndex:)])
                    finishedBlock = [self.menuDelegate menu:self didSelectItemAtIndex:highlightedItemIndex];
            }
        }
        [self resetMove:YES withCallback:finishedBlock];
        [self deactivateMenu];
    } else if (gesture == pan && isHighlighted) {
//        point.x += diffX;
//        point.y += diffY;
        [self moveTo:point animated:NO withCallback:nil];
    }
}

- (void)handleTap:(UITapGestureRecognizer*)tap {
    if ([self.menuDelegate respondsToSelector:@selector(menuTapped:)])
        [self.menuDelegate menuTapped:self];
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
//    [menuItems removeAllObjects];
//    menuItems = nil;
//    self.highlightedItem = nil;
//    self.displayItem = nil;
//    self.menuView = nil;
//    self.origItems = nil;
}

#pragma mark - Selecting submenus

- (void)activateSubmenu:(JZMenu*)submenu {
    activeSubmenu = submenu;
    [activeSubmenu activateMenu];
    activeSubmenu->parentMenu = self;
    [self hideMenu];
    self.highlightedItem.hidden = YES;
    [self addSubview:activeSubmenu];
    [self.superview bringSubviewToFront:activeSubmenu];
    [activeSubmenu changeSelection:YES];
    CGPoint currentCenter = self.highlightedItem.center;
    // TEST
//    float newX = currentCenter.x + (self.highlightedItem.frame.size.width - activeSubmenu.highlightedItem.frame.size.width) / 2;
//    float newY = currentCenter.y + (self.highlightedItem.frame.size.height - activeSubmenu.highlightedItem.frame.size.height) / 2;
//    float newX = currentCenter.x;
//    float newY = currentCenter.y;
    // TEST

    CGPoint newCenter = currentCenter;
    activeSubmenu->diffX = diffX;
    activeSubmenu->diffY = diffY;
    // TEST
//    CGPoint newCenter = CGPointMake(newX, newY);
//    activeSubmenu->diffX = diffX - fabs(currentCenter.x - newCenter.x);
//    activeSubmenu->diffY = diffY - fabs(currentCenter.y - newCenter.y);
    // TEST
    
    [activeSubmenu highlightedItem].center = newCenter;
    [activeSubmenu displayItem].center = newCenter;
    [activeSubmenu displayItem].hidden = YES;

    CGPoint highlightedItemPoint = [activeSubmenu highlightedItem].center;
    [activeSubmenu highlightMenuItemAtPoint:highlightedItemPoint];
}

- (void)deactivateSubmenu {
    if (activeSubmenu) {
        [activeSubmenu removeFromSuperview];
        activeSubmenu = nil;
    }
}

- (void)longHover:(NSTimer*)timer {
     // Get item and handle long press according to class
    NSInteger itemIndex = (NSInteger)[[[timer userInfo] objectForKey:kUserInfoDictKey] intValue];
    
    if ([self.menuDelegate respondsToSelector:@selector(menu:canLongHoverOnItemAtIndex:)] && ![self.menuDelegate menu:self canLongHoverOnItemAtIndex:itemIndex])
        return;
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
        if ([self.menuDelegate respondsToSelector:@selector(menu:longHoverOnItemAtIndex:)] &&
            [self.menuDelegate menu:self animateOnLongHover:itemIndex]) {
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
                                 if ([self.menuDelegate respondsToSelector:@selector(menu:longHoverOnItemAtIndex:)]) {
                                     [self.menuDelegate menu:self longHoverOnItemAtIndex:itemIndex];
                                 }
                             }];
        } else if ([self.menuDelegate respondsToSelector:@selector(menu:longHoverOnItemAtIndex:)]) {
            // Dont animate - only activate the long hover action
            [self.menuDelegate menu:self longHoverOnItemAtIndex:itemIndex];
        }
    }
}

- (NSInteger)menuItemCount {
    return menuItems.count;
}

#pragma mark - Delegate stuff

- (void)activateMenu {
    if (!self.isMenuActive) {
        self.menuActive = YES;
        if (self.menuDelegate && [self.menuDelegate respondsToSelector:@selector(menuActivated:)]) {
            [self.menuDelegate menuActivated:self];
        }
    }
}

- (void)deactivateMenu {
    [displayLink invalidate];
    displayLink = nil;
    
    if (self.isMenuActive) {
        // Check parents
        if (self.parentMenu) {
            [self.parentMenu deactivateMenu];
        }
        self.menuActive = NO;
        if (self.menuDelegate && [self.menuDelegate respondsToSelector:@selector(menuDeactivated:)]) {
            [self.menuDelegate menuDeactivated:self];
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
    if (hitView == self)
        return nil;
    else
        return hitView;
}

@end
