/******************************************************************************
 * Nativa - MacOS X UI for rtorrent
 * http://www.aramzamzam.net
 *
 * Copyright Solomenchuk V. 2010.
 * Solomenchuk Vladimir <vovasty@aramzamzam.net>
 *
 * Licensed under the GPL, Version 3.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.gnu.org/licenses/gpl-3.0.html
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *****************************************************************************/

#import "SetupAssistantController.h"
#import "SynthesizeSingleton.h"
#import "AMSession.h"
#import "AMServer.h"

#import <netinet/in.h>

@interface SetupAssistantController(Private)
-(int) findFreePort:(int) startPort endPort:(int)endPort;
@end

@implementation SetupAssistantController

@dynamic currentView;
@synthesize sshHost, sshUsername, sshPassword, sshUsePrivateKey, errorMessage, checking, sshLocalPort;
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
    [sshProxy closeTunnel];
    [sshProxy release];
    sshProxy = nil;
    [self setChecking:NO];
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
    
    sshLocalPort = [self findFreePort:5000 endPort:5010];
    if (sshLocalPort == 0)
    {
        [self setErrorMessage: @"unable to find free local port"];
        return;
    }
    
    NSLog(@"using %d as local port", sshLocalPort);
    
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
		
    sshProxy.localPort = sshLocalPort;
	
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
@implementation SetupAssistantController(Private)
-(int) findFreePort:(int) startPort endPort:(int)endPort
{
    CFSocketRef socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM,
                            IPPROTO_TCP, 0, NULL, NULL);
	if (!socket)
	{
		NSLog(@"unable to create socket");
		return 0;
	}
    
	int fileDescriptor = CFSocketGetNative(socket);
    int reuse = false;
    
	if (setsockopt(fileDescriptor, SOL_SOCKET, SO_REUSEADDR,
                   (void *)&reuse, sizeof(int)) != 0)
	{
		NSLog(@"Unable to set socket options.");
		return 0;
	}
	
	struct sockaddr_in address;
	memset(&address, 0, sizeof(address));
	address.sin_len = sizeof(address);
	address.sin_family = AF_INET;
	address.sin_addr.s_addr = htonl(INADDR_ANY);
	CFDataRef addressData = nil;
    
    int resultPort = 0;
    
    for(int i=startPort;i<=endPort;i++)
    {
        address.sin_port = htons(i);
        addressData =
            CFDataCreate(NULL, (const UInt8 *)&address, sizeof(address));
        [(id)addressData autorelease];
        
        if (CFSocketSetAddress(socket, addressData) == kCFSocketSuccess)
        {
            resultPort = i;
            NSLog(@"port %d is free", i);
            break;
        }
        NSLog(@"port %d is busy", i);
    }

    CFSocketInvalidate(socket);
    CFRelease(socket);
    socket = nil;

    if (resultPort == 0)
        NSLog(@"Unable to bind socket to address.");

    return resultPort;
}
@end
