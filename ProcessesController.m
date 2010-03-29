//
//  ProcessesController.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 03.02.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "ProcessesController.h"
#import "SynthesizeSingleton.h"
#import "PreferencesController.h"
#import "AMSession.h"
#import "AMServer.h"
#import "RTConnection.h"
#import "RTorrentController.h"

@interface ProcessesController(Private)
-(NSMutableDictionary *) dictionaryForIndex:(NSInteger) index;
-(void) setObject:(id) object forKey:(NSString *) key forIndex:(NSInteger) index;
-(id) object:(NSString *) key forIndex:(NSInteger) index;
@end

@implementation ProcessesController
SYNTHESIZE_SINGLETON_FOR_CLASS(ProcessesController);

- (id) init
{
    if ((self = [super init]))
    {
		NSArray *procs;
		if ((procs = [[NSUserDefaults standardUserDefaults] arrayForKey: @"Processes"]))
			_processes = [procs mutableCopy];
		else 
		{
			_processes = [[NSMutableArray alloc] init];
			[_processes retain];
		}
    }
    
    return self;
}

- (void) dealloc
{
	[_processes release];
    [super dealloc];
}


-(NSInteger) count
{
	return [_processes count];
}

- (void) saveProcesses
{
    NSMutableArray * processes = [NSMutableArray arrayWithCapacity: [_processes count]];
    for (NSDictionary * dict in _processes)
    {
        NSMutableDictionary * tempDict = [dict mutableCopy];
		//don't archive the ProcessObject
        [tempDict removeObjectForKey: @"ProcessObject"];

        [processes addObject: tempDict];
		
        [tempDict release];
    }
    
	[[NSUserDefaults standardUserDefaults] setObject: processes forKey: @"Processes"];
}


-(void) setName:(NSString *)name forIndex:(NSInteger) index
{
	[self setObject:name forKey:@"Name" forIndex:index];
	
}
-(NSString *) nameForIndex:(NSInteger) index
{
	return [self object:@"Name" forIndex:index];
}

-(void) setProcessType:(NSString *)type forIndex:(NSInteger) index
{
	[self setObject:type forKey:@"ProcessType" forIndex:index];
}

-(NSString *) processTypeForIndex:(NSInteger) index
{
	return [self object:@"ProcessType" forIndex:index];
}

-(void) setConnectionType:(NSString *)type forIndex:(NSInteger) index
{
	[self setObject:type forKey:@"ConnectionType" forIndex:index];
}

-(NSString *) connectionTypeForIndex:(NSInteger) index
{
	return [self object:@"ConnectionType" forIndex:index];
}

-(void) setHost:(NSString *)host forIndex:(NSInteger) index
{
	[self setObject:host forKey:@"Host" forIndex:index];
}

-(NSString *) hostForIndex:(NSInteger) index
{
	return [self object:@"Host" forIndex:index];
}

-(void) setPort:(NSInteger)port forIndex:(NSInteger) index
{
	[self setObject:[NSNumber numberWithInteger:port] forKey:@"Port" forIndex:index];
}
-(NSInteger) portForIndex:(NSInteger) index
{
	return [[self object:@"Port" forIndex:index] intValue];
}

-(void) setLocalDownloadsFolder:(NSString *)folder forIndex:(NSInteger) index
{
	[self setObject:folder forKey:@"LocalDownloadsFolder" forIndex:index];
}

-(NSString *) localDownloadsFolderForIndex:(NSInteger) index
{
	return [self object:@"LocalDownloadsFolder" forIndex:index];
}

-(void) setSshHost:(NSString *)host forIndex:(NSInteger) index
{
	[self setObject:host forKey:@"SSHHost" forIndex:index];
}

-(NSString *) sshHostForIndex:(NSInteger) index
{
	return [self object:@"SSHHost" forIndex:index];
}

-(void) setSshPort:(NSInteger)port forIndex:(NSInteger) index
{
	[self setObject:[NSNumber numberWithInteger:port] forKey:@"SSHPort" forIndex:index];
}

-(NSInteger) sshPortForIndex:(NSInteger) index
{
	return [[self object:@"SSHPort" forIndex:index] intValue];
}

-(void) setSshLocalPort:(NSInteger)port forIndex:(NSInteger) index
{
	[self setObject:[NSNumber numberWithInteger:port] forKey:@"SSHLocalPort" forIndex:index];
}

-(NSInteger) sshLocalPortForIndex:(NSInteger) index
{
	return [[self object:@"SSHLocalPort" forIndex:index] intValue];
}

-(void) setSshUser:(NSString *)user forIndex:(NSInteger) index
{
	[self setObject:user forKey:@"SSHUser" forIndex:index];
}

-(NSString *) sshUserForIndex:(NSInteger) index
{
	return [self object:@"SSHUser" forIndex:index];
}

-(void) setSshPassword:(NSString *)password forIndex:(NSInteger) index
{
	[self setObject:password forKey:@"SSHPassword" forIndex:index];
}
-(NSString *) sshPasswordForIndex:(NSInteger) index
{
	return [self object:@"SSHPassword" forIndex:index];
}

-(void) setMaxReconnects:(NSInteger)maxReconnects forIndex:(NSInteger) index
{
	[self setObject:[NSNumber numberWithInteger:maxReconnects] forKey:@"MaxReconnects" forIndex:index];
}

-(NSInteger) maxReconnectsForIndex:(NSInteger) index
{
	return [[self object:@"MaxReconnects" forIndex:index] intValue];
}

-(void) setGroupsField:(NSUInteger)groupsField forIndex:(NSInteger) index
{
	[self setObject:[NSNumber numberWithInteger:groupsField] forKey:@"GroupsField" forIndex:index];
}

-(NSUInteger) groupsFieldForIndex:(NSInteger) index
{
	return [[self object:@"GroupsField" forIndex:index] intValue];
}

- (NSInteger) addProcess
{
    //find the lowest index
    NSInteger index;
    for (index = 0; index < [_processes count]; index++)
    {
        BOOL found = NO;
        for (NSDictionary * dict in _processes)
            if ([[dict objectForKey: @"Index"] integerValue] == index)
            {
                found = YES;
                break;
            }
        
        if (!found)
            break;
    }
    
    [_processes addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInteger: index], @"Index", [NSNumber numberWithInteger: 1], @"GroupsField", nil]];
	return index;
}

- (NSInteger) indexForRow: (NSInteger) row
{
    return [[[_processes objectAtIndex: row] objectForKey: @"Index"] integerValue];
}

-(void) openProcess:(void (^)(NSString *error)) handler forIndex:(NSInteger) index;
{
	AMSession* proxy = nil;
	if ([[self connectionTypeForIndex:index] isEqualToString: @"SSH"])
	{
		proxy = [[AMSession alloc] init];
		proxy.sessionName = [self nameForIndex:index];
		proxy.remoteHost = [self hostForIndex:index];
		proxy.remotePort = [self portForIndex:index];
		
		proxy.localPort = [self sshLocalPortForIndex:index];
		
		AMServer *server = [[AMServer alloc] init];
		server.host = [self sshHostForIndex:index];
		server.username = [self sshUserForIndex:index];
		server.password = [self sshPasswordForIndex:index];
		server.port = [NSString stringWithFormat:@"%d", [self sshPortForIndex:index]];
		proxy.currentServer = server;
		proxy.maxAutoReconnectRetries = [self maxReconnectsForIndex:index];
		proxy.autoReconnect = YES;
		[server release];
	}
	RTConnection* connection = [[RTConnection alloc] initWithHostPort:[self hostForIndex:index] port:[self portForIndex:index] proxy:proxy];
	
	RTorrentController *process = [[RTorrentController alloc] initWithConnection:connection];

	[process openConnection: handler];

	[process setGroupField: [self groupsFieldForIndex:index]];
	
	[self setObject:process forKey:@"ProcessObject" forIndex:index];
	
	[process release];
	[connection release];
	[proxy release];
}

-(void) closeProcessForIndex:(NSInteger) index
{
	[[self object:@"ProcessObject" forIndex:index] closeConnection];
}

-(id<TorrentController>) processForIndex:(NSInteger) index
{
	return [self object:@"ProcessObject" forIndex:index];
}
@end

@implementation ProcessesController(Private)
-(NSMutableDictionary *) dictionaryForIndex:(NSInteger) index
{
	if (index != -1)
    {
        for (NSInteger i = 0; i < [_processes count]; i++)
		{
            NSMutableDictionary* dict = [_processes objectAtIndex: i];
			if (index == [[dict objectForKey: @"Index"] integerValue])
                return dict;
		}
    }
    return nil;
}

-(void) setObject:(id) object forKey:(NSString *) key forIndex:(NSInteger) index
{
	NSMutableDictionary* dict = [self dictionaryForIndex:index];
	[dict setObject:object forKey: key];
}

-(id) object:key forIndex:(NSInteger) index
{
	NSMutableDictionary* dict = [self dictionaryForIndex:index];
	return [dict objectForKey: key] ;
}
@end
