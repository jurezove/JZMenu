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

@optional
- (BOOL)canSelectItemAtIndex:(NSInteger)index inMenu:(JZMenu*)menu;
- (void)didSelectItemAtIndex:(NSInteger)index inMenu:(JZMenu*)menu;
- (void)menuActivated:(JZMenu*)menu;
- (void)menuDeactivated:(JZMenu*)menu;
- (void)hoverOnItemAtIndex:(NSInteger)index inMenu:(JZMenu*)menu;
- (BOOL)animateOnLongHover:(NSInteger)index inMenu:(JZMenu*)menu;
- (void)longHoverOnItemAtIndex:(NSInteger)index inMenu:(JZMenu*)menu;

@end

@interface JZMenu : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UILongPressGestureRecognizer *longPress;
@property (nonatomic, strong) UIPanGestureRecognizer *pan;

- (id)initWithHighlightedItem:(id)highlightedItem
                  displayItem:(id)displayItem
                    menuItems:(NSArray*)images
                     position:(JZMenuPosition)menuPosition
                  parentFrame:(CGRect)frame
                 menuDelegate:(id<JZMenuDelegate>)menuDelegate;

@end

