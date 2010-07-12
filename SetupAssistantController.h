#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>

@class ProcessesController;

@interface SetupAssistantController : NSWindowController
{
    IBOutlet NSView              *currentView;
    IBOutlet NSView              *startView;
    IBOutlet NSView              *configureSSHView;
    IBOutlet NSView              *configureSCGIView;
    
    CATransition                 *transition;
    
    NSString                     *errorMessage;
    
    BOOL                         useSSH;
    
    NSString                     *sshHost;
    NSString                     *sshUsername;
    NSString                     *sshPassword;
    BOOL                         sshUsePrivateKey;
    IBOutlet id                  sshFirstResponder;
    int                          sshLocalPort;
    BOOL                         checking;
    
    NSString                     *scgiHost;
    IBOutlet id                  scgiFirstResponder;
    int                          currentProcessIndex;
    
    ProcessesController          *pc;
    
    void (^openSetupAssistantHandler)(id sender);
    
    IBOutlet NSPopUpButton       *_downloadsPathPopUp;
}
+ (SetupAssistantController *)sharedSetupAssistantController;
- (void) openSetupAssistant:(void (^)(id sender))handler;

@property (copy) void (^openSetupAssistantHandler)(id sender);

@property (retain) NSView    *currentView;

@property (retain) NSString  *errorMessage;

@property (retain) NSString  *sshHost;
@property (retain) NSString  *sshUsername;
@property (retain) NSString  *sshPassword;
@property (assign) BOOL      sshUsePrivateKey;
@property (assign) int       sshLocalPort;

@property (retain) NSString  *scgiHost;

@property (assign) BOOL      checking;

- (IBAction)showStartView:(id)sender;
- (IBAction)showConfigureSSHView:(id)sender;
- (IBAction)showConfigureSCGIView:(id)sender;
- (IBAction)checkSSH:(id)sender;
- (IBAction)checkSCGI:(id)sender;
- (void) downloadsPathShow: (id) sender;
@end