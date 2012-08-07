//
//  JZMenu.h
//  JZMenu
//
//  Created by Jure Zove on 6. 08. 12.
//  Copyright (c) 2012 Jure Zove. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
    JZMenuPositionTop = (1 << 0),
    JZMenuPositionRight = (1 << 1),
    JZMenuPositionBottom = (1 << 2),
    JZMenuPositionLeft = (1 << 3)
};
typedef char JZMenuPosition;

@class JZMenu;
@protocol JZMenuDelegate <NSObject>

- (BOOL)canSelectItemAtIndex:(NSInteger)index inMenu:(JZMenu*)menu;
- (void)didSelectItemAtIndex:(NSInteger)index inMenu:(JZMenu*)menu;

@end

@interface JZMenu : UIView <UIGestureRecognizerDelegate>

- (id)initWithSelectedImage:(UIImage*)selectedImage
            unselectedImage:(UIImage*)unselectedImage
                 menuImages:(NSArray*)images
                   position:(JZMenuPosition)menuPosition
                parentFrame:(CGRect)frame
                menuDelegate:(id<JZMenuDelegate>)menuDelegate;

@end

