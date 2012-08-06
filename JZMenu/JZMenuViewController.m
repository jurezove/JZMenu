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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    UIImageView *jackie = [[UIImageView alloc] initWithFrame:self.view.bounds];
    jackie.image = [UIImage imageNamed:@"jackie.JPG"];
    jackie.contentMode = UIViewContentModeCenter;
    [self.view addSubview:jackie];
    
    NSArray *menuImages = [NSArray arrayWithObjects:[UIImage imageNamed:@"Camara"],
                           [UIImage imageNamed:@"Circle-Info"],
                           [UIImage imageNamed:@"Cloud-Blank"],
                           [UIImage imageNamed:@"Guitar"],
                           [UIImage imageNamed:@"iPhone"], nil];
    JZMenu *demoMenu = [[JZMenu alloc] initWithSelectedImage:[UIImage imageNamed:@"heart"]
                                             unselectedImage:[UIImage imageNamed:@"heart_us"]
                                                  menuImages:menuImages
                                                    position:JZMenuPositionTop | JZMenuPositionLeft
                                                 parentFrame:self.view.bounds];
    [self.view addSubview:demoMenu];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
