//
//  JZMenuViewController.m
//  JZMenu
//
//  Created by Jure Zove on 6. 08. 12.
//  Copyright (c) 2012 Jure Zove. All rights reserved.
//

#import "JZMenuViewController.h"

@interface JZMenuViewController ()

@end

@implementation JZMenuViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];

    NSArray *menuImages = [[NSArray alloc] initWithObjects:[UIImage imageNamed:@"Camara"],
                           [UIImage imageNamed:@"Circle-Info"],
                           //                           [UIImage imageNamed:@"Cloud-Blank"],
                           [UIImage imageNamed:@"Guitar"],
                           [UIImage imageNamed:@"iPhone"], nil];
    JZMenu *demoMenu = [[JZMenu alloc] initWithHighlightedImage:[UIImage imageNamed:@"menu_blue_se"]
                                                          Image:[UIImage imageNamed:@"menu_blue"]
                                                      menuImages:menuImages
                                                        position:JZMenuPositionLeft | JZMenuPositionRight
                                                     parentFrame:CGRectMake(0, 230, 160, 230)
                                                    menuDelegate:self];
    [self.view addSubview:demoMenu];
    
    JZMenu *demoMenu2 = [[JZMenu alloc] initWithHighlightedImage:[UIImage imageNamed:@"menu_green_se"]
                                                           Image:[UIImage imageNamed:@"menu_green"]
                                                      menuImages:menuImages
                                                        position:JZMenuPositionLeft | JZMenuPositionRight
                                                     parentFrame:CGRectMake(0, 0, 160, 230)
                                                    menuDelegate:self];
    [self.view addSubview:demoMenu2];
    
    JZMenu *demoMenu3 = [[JZMenu alloc] initWithHighlightedImage:[UIImage imageNamed:@"menu_purple_se"]
                                                           Image:[UIImage imageNamed:@"menu_purple"]
                                                      menuImages:menuImages
                                                        position:JZMenuPositionLeft | JZMenuPositionRight
                                                     parentFrame:CGRectMake(160, 0, 160, 230)
                                                    menuDelegate:self];
    [self.view addSubview:demoMenu3];
    
    JZMenu *demoMenu4 = [[JZMenu alloc] initWithHighlightedImage:[UIImage imageNamed:@"menu_orange_se"]
                                                           Image:[UIImage imageNamed:@"menu_orange"]
                                                      menuImages:menuImages
                                                        position:JZMenuPositionLeft | JZMenuPositionRight
                                                     parentFrame:CGRectMake(160, 230, 160, 230)
                                                    menuDelegate:self];
    [self.view addSubview:demoMenu4];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - JZMenuDelegate

- (BOOL)canSelectItemAtIndex:(NSInteger)index inMenu:(JZMenu *)menu {
    if (index == 1)
        return NO;
    return YES;
}

- (void)didSelectItemAtIndex:(NSInteger)index inMenu:(JZMenu *)menu {
    NSString *message = [NSString stringWithFormat:@"Item at index %d in menu at position %@", index, NSStringFromCGRect(menu.frame)];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Selected item"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
}

@end
