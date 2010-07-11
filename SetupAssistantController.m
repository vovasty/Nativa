#import "SetupAssistantController.h"
#import "SynthesizeSingleton.h"
#import "AMSession.h"
#import "AMServer.h"

@implementation SetupAssistantController

@dynamic currentView;
@synthesize sshHost, sshUsername, sshPassword, sshUsePrivateKey, errorMessage, checking;
;

SYNTHESIZE_SINGLETON_FOR_CLASS(SetupAssistantController);

- (id) init
{
    if ((self = [super initWithWindowNibName: @"SetupAssistant"]))
    {
        
    }
    
    return self;
}

-(void) dealloc
{
    [sshProxy release];
}

-(void) openSetupAssistant
{
	NSWindow* window = [self window];
	if (![window isVisible])
        [window center];
	
    [window makeKeyAndOrderFront: nil];
}

- (void)awakeFromNib
{
    NSView *contentView = [[self window] contentView];
    [contentView setWantsLayer:YES];
    [self setCurrentView:startView];
    [contentView addSubview:[self currentView]];
    
    transition = [CATransition animation];
    [transition setType:kCATransitionPush];
    [transition setSubtype:kCATransitionFromLeft];
    
    NSDictionary *ani = [NSDictionary dictionaryWithObject:transition forKey:@"subviews"];
    [contentView setAnimations:ani];
}

- (void)setCurrentView:(NSView*)newView
{
    if (!currentView) {
        currentView = newView;
        return;
    }
    NSView *contentView = [[self window] contentView];
    [[contentView animator] replaceSubview:currentView with:newView];
    currentView = newView;
}

- (NSView*) currentView
{
    return currentView;
}

- (IBAction)showStartView:(id)sender
{
    [transition setSubtype:kCATransitionFromLeft];
    [self setCurrentView:startView];
}
- (IBAction)showConfigureSSHView:(id)sender
{
    useSSH = NO;
    [transition setSubtype:kCATransitionFromRight];
    [self setCurrentView:configureSSHView];
    [[self window] makeFirstResponder:sshFirstResponder];
}
- (IBAction)showConfigureSCGIView:(id)sender
{
    [transition setSubtype:kCATransitionFromRight];
    [self setCurrentView:configureSCGIView];
}
- (IBAction)checkSSH:(id)sender
{
    [[self window] makeFirstResponder: nil];
    [self setErrorMessage: nil];
    [sshProxy closeTunnel];
    [sshProxy release];
    
    NSArray *sshHostPort = [sshHost componentsSeparatedByString: @":"];

    AMServer *server = [[AMServer alloc] init];
    server.host = [sshHostPort objectAtIndex:0];
    server.username = sshUsername;
	server.password = sshPassword;
	server.port = [sshHostPort count]>1?[sshHostPort objectAtIndex:0]:@"22";
    server.useSSHV2 = NO;
    server.compressionLevel = 0;
    
    sshProxy = [[AMSession alloc] init];
    sshProxy.sessionName = @"test";
	sshProxy.remoteHost = @"127.0.0.1";
	sshProxy.remotePort = 5000;
		
    sshProxy.localPort = 5000;
	
    sshProxy.currentServer = server;
	sshProxy.maxAutoReconnectRetries = 1;
	sshProxy.autoReconnect = NO;
    [server release];
	[sshProxy retain];
	[self setChecking:YES];
    [sshProxy openTunnel:^(AMSession *sender){
        [self setChecking:NO];
        if ([sender connected])
        {
            useSSH = YES;
            [self showConfigureSCGIView:nil];
        }
        else
            [self setErrorMessage: [sender error]];

        [sshProxy closeTunnel];
    }];
}
@end
