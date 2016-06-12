//
//  IJTMultiToolViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/8/11.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTMultiToolViewController.h"
#import "IJTPacketTableViewController.h"
#import "IJTSnifferTableViewController.h"

@interface IJTMultiToolViewController ()

@property (nonatomic, strong) NSMutableArray *toolViewControllers;
@property (nonatomic, strong) NSMutableArray *iconImages;
@property (nonatomic, strong) NSMutableArray *colors;
@property (nonatomic, strong) RNFrostedSidebar *callout;
@property (nonatomic, strong) NSMutableIndexSet *optionIndices;

@end

@implementation IJTMultiToolViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.toolViewControllers = [[NSMutableArray alloc] init];
    self.iconImages = [[NSMutableArray alloc] init];
    self.colors = [[NSMutableArray alloc] init];
    
    //rand color
    NSArray *flatColors = @[[UIColor turquoiseColor], [UIColor peterRiverColor], [UIColor wetAsphaltColor],
                            [UIColor sunflowerColor], [UIColor carrotColor],
                            [UIColor colorWithRed:240/255.f green:159/255.f blue:254/255.f alpha:1],
                            [UIColor colorWithRed:255/255.f green:137/255.f blue:167/255.f alpha:1],
                            [UIColor colorWithRed:126/255.f green:242/255.f blue:195/255.f alpha:1],
                            [UIColor colorWithRed:119/255.f green:152/255.f blue:255/255.f alpha:1]];
    
    //add sniffer
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SnifferStoryboard" bundle:nil];
    UITabBarController *tabBarVC = [storyboard instantiateViewControllerWithIdentifier:@"SnifferTabBarVC"];
    IJTSnifferTableViewController *snifferVC =
    [[(UINavigationController *)
      [tabBarVC.viewControllers objectAtIndex:0]
      viewControllers] objectAtIndex:0];
    IJTPacketTableViewController *packetVC =
    [[(UINavigationController *)
      [tabBarVC.viewControllers objectAtIndex:1]
      viewControllers] objectAtIndex:0];
    
    packetVC.multiToolButton = [[UIBarButtonItem alloc]
                                initWithImage:[UIImage imageNamed:@"list.png"]
                                style:UIBarButtonItemStylePlain
                                target:self action:@selector(showSideBar)];
    packetVC.multiToolButton.tag = MULTIBUTTONTAG;
    
    snifferVC.multiToolButton = [[UIBarButtonItem alloc]
                                 initWithImage:[UIImage imageNamed:@"list.png"]
                                 style:UIBarButtonItemStylePlain
                                 target:self action:@selector(showSideBar)];
    snifferVC.multiToolButton.tag = MULTIBUTTONTAG;
    
    [self.toolViewControllers addObject:tabBarVC];
    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"SnifferBig.png"]];
    [self.iconImages addObject:[image imageWithColor:IJTIconWhiteColor]];
    [self.colors addObject:[IJTColor lighter:IJTSnifferColor times:3]];
    
    //add storyboards
    NSArray *toolSection = [IJTBaseViewController getAllToolSectionArray];
    NSMutableArray *storyboardArray = [[NSMutableArray alloc] init];
    for(NSString *section in toolSection) {
        [storyboardArray addObject:[UIStoryboard storyboardWithName:[section stringByAppendingString:@"Storyboard"] bundle:nil]];
    }//end for
    
    for(NSString *name in self.selectedTools) {
        NSString *vcid = [NSString stringWithFormat:@"%@NavVC", name];
        UINavigationController *navVC = nil;
        
        //search view controller
        for(UIStoryboard *storyboard in storyboardArray) {
            
            //because if stroyboard not contain my view controller id, it will throw NSInvalidArgumentException
            @try {
                navVC = [storyboard instantiateViewControllerWithIdentifier:vcid];
            }
            @catch(NSException *ex) {
            }
            
            if(navVC) {
                break;
            }
        }//end for
        
        //not found, skip
        if(!navVC)
            continue;
        
        IJTBaseViewController *vc = [[navVC viewControllers] firstObject];
        vc.multiToolButton = [[UIBarButtonItem alloc]
                              initWithImage:[UIImage imageNamed:@"list.png"]
                              style:UIBarButtonItemStylePlain
                              target:self action:@selector(showSideBar)];
        vc.multiToolButton.tag = MULTIBUTTONTAG;
        
        [self.toolViewControllers addObject:navVC];
        
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", name]];
        
        [self.iconImages addObject:[image imageWithColor:IJTIconWhiteColor]];
        [self.colors addObject:flatColors[arc4random()%flatColors.count]];
    }//end for add multi tool button

    //add close
    [self.iconImages addObject:[[UIImage imageNamed:@"close.png"] imageWithColor:IJTIconWhiteColor]];
    [self.colors addObject:IJTIconWhiteColor];
    
    self.optionIndices = [NSMutableIndexSet indexSetWithIndex:1];
    self.callout = [[RNFrostedSidebar alloc] initWithImages:self.iconImages
                                            selectedIndices:self.optionIndices
                                               borderColors:self.colors];
    self.callout.delegate = self;
    self.callout.borderWidth = 3;
    [self sidebar:self.callout didTapItemAtIndex:1];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showSideBar {
    [self.callout showAnimated:YES];
}

#pragma mark - RNFrostedSidebarDelegate

- (void)sidebar:(RNFrostedSidebar *)sidebar didTapItemAtIndex:(NSUInteger)index {
    if(self.toolViewControllers.count < index)
        return;
    
    if(index == self.toolViewControllers.count) {
        [sidebar dismissAnimated:YES completion:^(BOOL finished) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        return;
    }
    
    void (^block)(BOOL) = ^(BOOL finished) {
        [[self.view subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        UINavigationController *navVC = self.toolViewControllers[index];
        [self.view addSubview:navVC.view];
    };
    
    BOOL contain = NO;
    for(UINavigationController *navVC in self.toolViewControllers) {
        if([[self.view subviews] containsObject:navVC.view]) {
            contain = YES;
        }
    }//end for search if contain
    
    if(contain) {
        [sidebar dismissAnimated:YES completion:block];
    }
    else {
        block(YES);
    }
}

- (void)sidebar:(RNFrostedSidebar *)sidebar didEnable:(BOOL)itemEnabled itemAtIndex:(NSUInteger)index {
    [self.optionIndices removeAllIndexes];
    if(itemEnabled)
    [self.optionIndices addIndex:index];
}

@end
