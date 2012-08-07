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
* Add QuartzCore framework to your project.
* ```#import "JZMenu.h"``` and ```#import <QuartzCore/QuartzCore.h>```
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

* You can change the position of the main menu image by combining JZMenuPosition flags.

```
JZMenuPositionTop
JZMenuPositionRight
JZMenuPositionBottom
JZMenuPositionLeft
```

* Implement the delegate methods:

```
	- (BOOL)canSelectItemAtIndex:(NSInteger)index inMenu:(JZMenu*)menu;
	- (void)didSelectItemAtIndex:(NSInteger)index inMenu:(JZMenu*)menu;
```

Licence
-----
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
THIS SOFTWARE IS PROVIDED BY THE FREEBSD PROJECT ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE FREEBSD PROJECT OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those of the authors and should not be interpreted as representing official policies, either expressed or implied, of the FreeBSD Project.
