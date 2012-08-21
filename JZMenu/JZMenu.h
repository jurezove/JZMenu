//
//  JZMenu.h
//  JZMenu
//
//  Created by Jure Zove on 6. 08. 12.
//  Copyright (c) 2012 Jure Zove. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

enum {
    JZMenuPositionTop = (1 << 0),
    JZMenuPositionRight = (1 << 1),
    JZMenuPositionBottom = (1 << 2),
    JZMenuPositionLeft = (1 << 3)
};
typedef char JZMenuPosition;

@class JZMenu;
@protocol JZMenuDelegate <NSObject>

typedef void (^JZMenuDidSelectItemFinishedBlock)(BOOL);

@optional
- (BOOL)menu:(JZMenu*)menu canSelectItemAtIndex:(NSInteger)index;
- (JZMenuDidSelectItemFinishedBlock)menu:(JZMenu*)menu didSelectItemAtIndex:(NSInteger)index;
- (void)menuActivated:(JZMenu*)menu;
- (void)menuDeactivated:(JZMenu*)menu;
- (void)menuTapped:(JZMenu*)menu;
- (void)menu:(JZMenu*)menu hoverOnItemAtIndex:(NSInteger)index;
- (BOOL)menu:(JZMenu*)menu animateOnLongHover:(NSInteger)index;
- (void)menu:(JZMenu*)menu longHoverOnItemAtIndex:(NSInteger)index;

@end

@interface JZMenu : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UILongPressGestureRecognizer *longPress;
@property (nonatomic, strong) UIPanGestureRecognizer *pan;
@property (nonatomic, strong) UITapGestureRecognizer *tap;

- (id)initWithHighlightedItemData:(id)highlightedItem
                  displayItemData:(id)displayItem
                    menuItems:(NSArray*)images
                     position:(JZMenuPosition)menuPosition
                  parentFrame:(CGRect)frame
                 menuDelegate:(id<JZMenuDelegate>)menuDelegate
                     transparency:(float)alpha;

- (void)changeDisplayItemWith:(id)displayItemData;
- (void)changeHighlightedItemWith:(id)highlightedItemData;
- (void)updateMenuItemAtIndex:(NSInteger)index withItemData:(id)data animated:(BOOL)animated;
- (NSInteger)menuItemCount;

@end

