#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>

@class AMSession;

@interface SetupAssistantController : NSWindowController
{
    IBOutlet NSView         *currentView;
    IBOutlet NSView         *startView;
    IBOutlet NSView         *configureSSHView;
    IBOutlet NSView         *configureSCGIView;
    
    CATransition            *transition;
    
    NSString                *errorMessage;
    
    BOOL                    useSSH;
    
    NSString                *sshHost;
    NSString                *sshUsername;
    NSString                *sshPassword;
    BOOL                    sshUsePrivateKey;
    
    IBOutlet id             sshFirstResponder;
    
    AMSession                *sshProxy;
}
+ (SetupAssistantController *)sharedSetupAssistantController;
- (void) openSetupAssistant;

@property (retain) NSView    *currentView;

@property (retain) NSString  *errorMessage;

@property (retain) NSString  *sshHost;
@property (retain) NSString  *sshUsername;
@property (retain) NSString  *sshPassword;
@property (assign) BOOL      sshUsePrivateKey;

- (IBAction)showStartView:(id)sender;
- (IBAction)showConfigureSSHView:(id)sender;
- (IBAction)showConfigureSCGIView:(id)sender;
- (IBAction)checkSSH:(id)sender;
@end