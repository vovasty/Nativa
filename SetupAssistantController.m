#import "SetupAssistantController.h"
#import "SynthesizeSingleton.h"

@implementation SetupAssistantController

@dynamic currentView;

SYNTHESIZE_SINGLETON_FOR_CLASS(SetupAssistantController);

- (id) init
{
    if ((self = [super initWithWindowNibName: @"SetupAssistant"]))
    {
        
    }
    
    return self;
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
    [transition setSubtype:kCATransitionFromRight];
    [self setCurrentView:configureSSHView];
}
- (IBAction)showConfigureSCGIView:(id)sender
{
    [transition setSubtype:kCATransitionFromRight];
    [self setCurrentView:configureSCGIView];
}
- (IBAction)checkSSH:(id)sender
{
    [self showConfigureSCGIView:nil];
}
@end
