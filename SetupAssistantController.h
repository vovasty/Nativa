#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>

@interface SetupAssistantController : NSWindowController
{
    IBOutlet NSView         *currentView;
    IBOutlet NSView         *startView;
    IBOutlet NSView         *configureSSHView;
    IBOutlet NSView         *configureSCGIView;
    
    CATransition *transition;
}
+ (SetupAssistantController *)sharedSetupAssistantController;
- (void) openSetupAssistant;

@property(retain)NSView *currentView;

- (IBAction)showStartView:(id)sender;
- (IBAction)showConfigureSSHView:(id)sender;
- (IBAction)showConfigureSCGIView:(id)sender;
- (IBAction)checkSSH:(id)sender;
@end