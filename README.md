JZMenu
======

A cool menu interface design with a slide-to-select feature.

Screenshots
-----

![Single menu](https://raw.github.com/Stigec/JZMenu/master/Screenshots/menu-single.png)

![Single menu](https://raw.github.com/Stigec/JZMenu/master/Screenshots/menu-single2.png)

![Multiple menus](https://raw.github.com/Stigec/JZMenu/master/Screenshots/menu-multiple.png)

![Multiple menus](https://raw.github.com/Stigec/JZMenu/master/Screenshots/menu-multiple2.png)

Usage
-----

* Add JZMenu.h and JZMenu.m to your project.
* Add #import "JZMenu.h"
* Define an array of menu images:

```
	NSArray *menuImages = [[NSArray alloc] initWithObjects:[UIImage imageNamed:@"Camara"],
                           [UIImage imageNamed:@"Circle-Info"],
                           [UIImage imageNamed:@"Guitar"],
                           [UIImage imageNamed:@"iPhone"], nil];
```

* Create the JZMenu object with the normal and highlighted main menu image, your array of menu images and the parent frame. Then just add it to your view.

```
    JZMenu *demoMenu = [[JZMenu alloc] initWithSelectedImage:[UIImage imageNamed:@"menu_blue_se"]
                                     unselectedImage:[UIImage imageNamed:@"menu_blue"]
                                          menuImages:menuImages
                                            position:JZMenuPositionLeft | JZMenuPositionRight
                                         parentFrame:self.view.bounds
                                                menuDelegate:self];
```

* Implement the delegate methods:

```
	- (BOOL)canSelectItemAtIndex:(NSInteger)index inMenu:(JZMenu*)menu;
	- (void)didSelectItemAtIndex:(NSInteger)index inMenu:(JZMenu*)menu;
```