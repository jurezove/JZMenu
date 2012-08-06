//
//  JZMenu.m
//  JZMenu
//
//  Created by Jure Zove on 6. 08. 12.
//  Copyright (c) 2012 Jure Zove. All rights reserved.
//

#import "JZMenu.h"

#define kMenuWidth 80.0f
#define kAnimationDuration 0.2f
#define kNumOfMenuItems 5
#define kMenuItemImageWidth 80.0f
#define RGB(r,g,b, a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]

// Colors
#define kMenuColor RGB(0, 0, 0, 0.7)
#define kMenuHighlightedColor RGB(255, 255, 255, 0.5)


@interface JZMenu() {
    UILongPressGestureRecognizer *longPress;
    UIPanGestureRecognizer *pan;
    BOOL moveCompleted;
    BOOL isSelected;
    
    // Origin diff for pan gesture recognizer
    float diffX, diffY;
    
    NSMutableArray *menuItems;
    NSArray *menuImages;
}

@property (nonatomic, strong) UIImageView *unselectedImageView;
@property (nonatomic, strong) UIImageView *selectedImageView;
@property (nonatomic) CGRect parentFrame;
@property (nonatomic) JZMenuPosition position;
@property (nonatomic, strong) UIView *menuView;

@end

@implementation JZMenu

@synthesize selectedImageView;
@synthesize unselectedImageView;
@synthesize parentFrame;
@synthesize position;
@synthesize menuView = _menuView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithSelectedImage:(UIImage*)selectedImage
            unselectedImage:(UIImage*)unselectedImage
                 menuImages:(NSArray *)images
                   position:(JZMenuPosition)menuPosition
                parentFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.selectedImageView = [[UIImageView alloc] initWithImage:selectedImage];
        self.unselectedImageView = [[UIImageView alloc] initWithImage:unselectedImage];
        self.parentFrame = frame;
        self.position = menuPosition;
        menuImages = images;
        [self config];
    }
    return self;
}

#pragma mark - Config

- (CGPoint)centerPoint {
    float x, y;
    switch (self.position) {
        case JZMenuPositionTop:
            x = self.frame.size.width / 2;
            y = 0 + kMenuWidth / 2;
            break;
        case JZMenuPositionRight:
            x = self.frame.size.width - kMenuWidth / 2;
            y = self.frame.size.height / 2;
            break;
        case JZMenuPositionBottom:
            x = self.frame.size.width / 2;
            y = self.frame.size.height - kMenuWidth / 2;
            break;
        case JZMenuPositionLeft:
            x = 0 + kMenuWidth / 2;
            y = self.frame.size.height / 2;
            break;
        default:
            x = y = 0;
            break;
    }
    return CGPointMake(x, y);
}

- (CGPoint)originPoint {
    float x, y;
    
    // if top && bottom
    // if top
    // if bottom
    
    // if left && right
    // if left
    // if right
    
    if (self.position & JZMenuPositionTop && self.position & JZMenuPositionLeft) {
        NSLog(@"top and bottom");
    }
    
    switch (self.position) {
            
        case JZMenuPositionTop:
            x = self.frame.size.width / 2 - kMenuWidth / 2;
            y = 0;
            break;
        case JZMenuPositionRight:
            x = self.frame.size.width - kMenuWidth;
            y = self.frame.size.height / 2 - kMenuWidth / 2;
            break;
        case JZMenuPositionBottom:
            x = self.frame.size.width / 2 - kMenuWidth / 2;
            y = self.frame.size.height - kMenuWidth;
            break;
        case JZMenuPositionLeft:
            x = 0;
            y = self.frame.size.height / 2 - kMenuWidth / 2;
            break;
        default:
            x = y = 0;
            break;
    }
    return CGPointMake(x, y);
}

- (void)config {
    // Determine the frame of the menu
    CGSize size = CGSizeMake(kMenuWidth, kMenuWidth);
    CGPoint originPoint = [self originPoint];
    self.unselectedImageView.contentMode = self.selectedImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.unselectedImageView.frame = self.selectedImageView.frame = CGRectMake(originPoint.x, originPoint.y, size.width, size.height);
    self.selectedImageView.hidden = YES;
    [self addSubview:self.selectedImageView];
    [self addSubview:self.unselectedImageView];
    
    // Add gesture recognizers
    longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(menuLongPressed:)];
    longPress.minimumPressDuration = kAnimationDuration;
    longPress.delegate = self;
    [self addGestureRecognizer:longPress];
    
    pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(menuPaned:)];
    pan.delegate = self;
    [self addGestureRecognizer:pan];
    
    self.backgroundColor = [UIColor clearColor];
}

#pragma mark - Menu stuff

- (UIView *)menuView {
    if (!_menuView) {
        _menuView = [[UIView alloc] initWithFrame:self.bounds];
        _menuView.backgroundColor = [UIColor clearColor];
        _menuView.hidden = YES;
        [self addSubview:_menuView];
        [self sendSubviewToBack:_menuView];
        
        // Menu items
        menuItems = [[NSMutableArray alloc] initWithCapacity:kNumOfMenuItems];
        float sizeOfMenuItem = (float)self.frame.size.height / kNumOfMenuItems;
        CGRect imageRect = CGRectMake(self.frame.size.width / 2 - kMenuItemImageWidth / 2,
                                      sizeOfMenuItem / 2 - kMenuItemImageWidth / 2,
                                      kMenuItemImageWidth,
                                      kMenuItemImageWidth);
        for (int i = 0; i < kNumOfMenuItems; i++) {
            CGRect frame = CGRectMake(0,
                                      i * sizeOfMenuItem,
                                      self.frame.size.width,
                                      sizeOfMenuItem);
            UIView *menuItem = [[UIView alloc] initWithFrame:frame];
            menuItem.layer.borderColor = [UIColor whiteColor].CGColor;
            menuItem.layer.borderWidth = 1.0f;
            menuItem.backgroundColor = kMenuColor;
            
            // Image
            UIImageView *image = [[UIImageView alloc] initWithFrame:imageRect];
            image.image = [menuImages objectAtIndex:i];
            image.contentMode = UIViewContentModeCenter;
            [menuItem addSubview:image];
            
            [_menuView addSubview:menuItem];
            [menuItems addObject:menuItem];
        }
    }
    return _menuView;
}

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
                     animations:^{
                         [self menuView].alpha = 0;
                     } completion:^(BOOL finished) {
                         if (finished) {
                             [self menuView].hidden = YES;
                         }
                     }];
}

- (void)highlightMenuItemAtPoint:(CGPoint)point {
    int highlightedItem = 0;
    for (int i = 0; i < menuItems.count; i++) {
        UIView *menuItem = [menuItems objectAtIndex:i];
        if (CGRectContainsPoint(menuItem.frame, point)) {
            highlightedItem = i;
            break;
        }
    }
    [self layoutMenuItems:highlightedItem];
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
                                 [(UIView*)[menuItems objectAtIndex:i] setBackgroundColor:kMenuHighlightedColor];
                             } else {
                                 [(UIView*)[menuItems objectAtIndex:i] setBackgroundColor:kMenuColor];
                             }
                         }];
    }
}

#pragma mark - Gestures

- (void)changeSelection:(BOOL)selected {
    moveCompleted = NO;
    if (selected) {
        if (isSelected)
            return;
        
        [self showMenu];
        isSelected = YES;
        [self transform:CGAffineTransformMakeScale(1.3, 1.3)];
        self.selectedImageView.alpha = 0;
        self.selectedImageView.hidden = NO;
        [UIView animateWithDuration:kAnimationDuration
                              delay:0
                            options:UIViewAnimationCurveEaseOut
                         animations:^{
                             self.unselectedImageView.alpha = 0;
                             self.selectedImageView.alpha = 1;
                         } completion:^(BOOL finished) {
                             if (finished) {
                                 self.unselectedImageView.hidden = YES;
                                 moveCompleted = YES;
                             }
                         }];
    } else {
        if (!isSelected)
            return;
        
        [self hideMenu];
        isSelected = NO;
        [self transform:CGAffineTransformIdentity];
        self.unselectedImageView.alpha = 0;
        self.unselectedImageView.hidden = NO;
        [UIView animateWithDuration:kAnimationDuration
                              delay:0
                            options:UIViewAnimationCurveEaseOut
                         animations:^{
                             self.selectedImageView.alpha = 0;
                             self.unselectedImageView.alpha = 1;
                         } completion:^(BOOL finished) {
                             if (finished) {
                                 self.selectedImageView.hidden = YES;
                                 moveCompleted = YES;
                             }
                         }];
    }
}

- (void)resetMove {
    [self changeSelection:NO];
    [self moveTo:[self centerPoint] animated:YES];
    
}

- (void)transform:(CGAffineTransform)transform {
    [UIView animateWithDuration:kAnimationDuration
                     animations:^{
                        self.selectedImageView.transform = transform;
                     }];
}

- (void)moveTo:(CGPoint)point animated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:kAnimationDuration
                         animations:^{
                             self.unselectedImageView.center = self.selectedImageView.center = point;
                         }];
    } else {
        self.unselectedImageView.center = self.selectedImageView.center = point;
    }
    [self highlightMenuItemAtPoint:point];
}

- (void)menuLongPressed:(UILongPressGestureRecognizer*)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        // Began
        [self changeSelection:YES];
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        // Ended

        [self changeSelection:NO];
        
    }
    
}

- (void)menuPaned:(UIPanGestureRecognizer*)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self changeSelection:YES];
        CGPoint pointInSelf = [gesture locationInView:self.unselectedImageView];
        diffX = (self.unselectedImageView.frame.size.width / 2 - pointInSelf.x);
        diffY = (self.unselectedImageView.frame.size.height / 2 - pointInSelf.y);
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        [self resetMove];
        
    } else {
        CGPoint point = [gesture locationInView:self];
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

@end
