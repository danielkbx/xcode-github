//
//  XGAPreferencesViewController.h
//  xcode-github-app
//
//  Created by Edward on 5/10/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface XGAPreferencesViewController : NSViewController
+ (instancetype) loadController;
@property (strong) IBOutlet NSWindow*window;
@end
