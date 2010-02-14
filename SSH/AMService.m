#import "AMService.h"

@implementation AMService

@synthesize serviceLocalPorts;
@synthesize serviceRemotePorts;

#pragma mark -
#pragma mark Initializations

- (id) initWithPorts:(NSString*)localports remotePorts:(NSString*)remoteports;
{
	self = [super init];
	
	[self setServiceLocalPorts:localports];
	[self setServiceRemotePorts:remoteports];
	
	return self;
}

- (void) dealloc
{
	[serviceRemotePorts release];
	[serviceLocalPorts release];
	
	[super dealloc];
}

- (id) initWithCoder:(NSCoder *)coder
{
	self = [super init];
	
	self.serviceLocalPorts	= [coder decodeObjectForKey:@"serviceLocalPorts"];
	self.serviceRemotePorts	= [coder decodeObjectForKey:@"serviceRemotePorts"];
	
	return self;
}

- (void) encodeWithCoder:(NSCoder *) coder
{	
	[coder encodeObject:serviceRemotePorts forKey:@"serviceRemotePorts"];
	[coder encodeObject:serviceLocalPorts forKey:@"serviceLocalPorts"];
}


@end
