/**
 @file          XGAAddServerPanel.m
 @package       xcode-github-app
 @brief         A panel to select a server.

 @author        Edward Smith
 @date          September 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "XGAAddServerPanel.h"
#import "XGXcodeBot.h"
#import "BNCThreads.h"

NSTimeInterval const kNetworkRefreshInterval = 7.0;

@interface XGAAddServerPanel () <NSNetServiceBrowserDelegate>
@property (strong) IBOutlet NSArrayController*serverArrayController;
@property (strong) IBOutlet NSTableView *serverTableView;
@property (strong) IBOutlet NSTextField *serverTextField;
@property (strong) IBOutlet NSTextField *userTextField;
@property (strong) IBOutlet NSSecureTextField *passwordTextField;
@property (strong) IBOutlet NSProgressIndicator *activityWheel;
@property (strong) IBOutlet NSButton *addButton;

@property (assign) BOOL isSearchingNetwork;
@property (strong) NSNetServiceBrowser*networkBrowser;
@property (strong) NSTimer*networkTimer;
@property (strong) NSDate*networkLookupDate;
@end

@implementation XGAAddServerPanel

+ (instancetype) new {
    NSArray*objects = nil;
    [[NSBundle mainBundle]
        loadNibNamed:NSStringFromClass(self)
        owner:nil
        topLevelObjects:&objects];
    for (XGAAddServerPanel*panel in objects) {
        if ([panel isKindOfClass:XGAAddServerPanel.class])
            return panel;
    }
    return nil;
}

- (void) dealloc {
    self.networkBrowser.delegate = nil;
    [self stopNetworkLookup];
}

- (void) awakeFromNib {
    [super awakeFromNib];
    self.addButton.enabled = NO;
    [self startNetworkLookup];
}

-(BOOL) canBecomeKeyWindow {
    return YES;
}

- (NSString*) serverName {
    return self.serverTextField.stringValue;
}

- (NSString*) userName {
    return self.userTextField.stringValue;
}

- (NSString*) password {
    return self.passwordTextField.stringValue;
}

- (IBAction)tableRowAction:(id)sender {
    NSInteger idx = self.serverTableView.selectedRow;
    if (idx < 0 || idx >= [self.serverArrayController.arrangedObjects count]) return;
    NSString*server = [self.serverArrayController.arrangedObjects objectAtIndex:idx];
    if (server) {
        self.serverTextField.stringValue = server;
        self.addButton.enabled = (self.serverTextField.stringValue.length > 0);
        [self.userTextField becomeFirstResponder];
    }
}

- (IBAction)cancel:(id)sender {
    [self stopNetworkLookup];
    [self.sheetParent endSheet:self returnCode:NSModalResponseCancel];
}

- (void) controlTextDidChange:(NSNotification *)obj {
    self.addButton.enabled = (self.serverTextField.stringValue.length > 0);
}

- (IBAction)add:(id)sender {
    NSString*server = [self.serverTextField.stringValue copy];
    if (server.length <= 0) return;
    [self stopNetworkLookup];

    NSError*error = nil;
    [XGXcodeBot botsForServer:server error:&error];
    if (error) {
        NSAlert*alert = [[NSAlert alloc] init];
        alert.messageText = [NSString stringWithFormat:@"Can't connect to %@", server];
        alert.informativeText = [error localizedDescription];
        alert.alertStyle = NSAlertStyleCritical;
        [alert beginSheetModalForWindow:self completionHandler:nil];
    } else {
        [self.sheetParent endSheet:self returnCode:NSModalResponseOK];
    }
}

#pragma mark - Networking

- (void) startNetworkLookup {
    @synchronized(self) {
        if (self.isSearchingNetwork) return;
        NSLog(@"startNetworkLookup");
        [self stopNetworkLookup];
        self.isSearchingNetwork = YES;
        if (!self.networkBrowser) {
            self.networkBrowser = [[NSNetServiceBrowser alloc] init];
            self.networkBrowser.delegate = self;
            self.networkBrowser.includesPeerToPeer = YES;
        }
        [self.networkBrowser searchForServicesOfType:@"_xcs2p._tcp." inDomain:@""];
        self.activityWheel.indeterminate = YES;
        [self.activityWheel startAnimation:nil];
        [self.activityWheel setNeedsDisplay:YES];
    }
}

- (void) updateNetworkSpinner {
    NSTimeInterval t = [self.networkLookupDate timeIntervalSinceNow];
    if (t <= 0.0) {
        [self startNetworkLookup];
        return;
    }
    t = (1.0f - (t / kNetworkRefreshInterval)) * 100.0f;
    self.activityWheel.doubleValue = t;
    [self.activityWheel setNeedsDisplay:YES];
}

- (void) restartNetworkLookup {
    @synchronized(self) {
        NSLog(@"restartNetworkLookup");
        [self stopNetworkLookup];
        self.networkLookupDate = [NSDate dateWithTimeInterval:kNetworkRefreshInterval sinceDate:[NSDate date]];
        self.activityWheel.doubleValue = 0.0;
        self.activityWheel.indeterminate = NO;
        self.networkTimer =
            [NSTimer scheduledTimerWithTimeInterval:0.10
                target:self
                selector:@selector(updateNetworkSpinner)
                userInfo:nil
                repeats:YES];
    }
}

- (void) stopNetworkLookup {
    @synchronized(self) {
        [self.networkBrowser stop];

        [self.networkTimer invalidate];
        self.networkTimer = nil;
        self.isSearchingNetwork = NO;

        self.activityWheel.doubleValue = 0.0;
        self.activityWheel.indeterminate = YES;
        [self.activityWheel stopAnimation:nil];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
             didNotSearch:(NSDictionary<NSString *,NSNumber *> *)errorDict {
    NSLog(@"NSNetServiceBrowser error: %@.", errorDict);
    [self restartNetworkLookup];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
           didFindService:(NSNetService *)service
               moreComing:(BOOL)moreComing {
    if (service.name.length > 0 &&
        ![self.serverArrayController.arrangedObjects containsObject:service.name]) {
        [self.serverArrayController addObject:service.name];
    }
    if (!moreComing) {
        BNCAfterSecondsPerformBlockOnMainThread(2.0, ^{
            [self restartNetworkLookup];
        });
    }
}

@end