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
#import "ProcessDescriptor.h"

@implementation ProcessesController
SYNTHESIZE_SINGLETON_FOR_CLASS(ProcessesController);

- (id) init
{
    if ((self = [super init]))
    {
        NSData * data;
		
        if ((data = [[NSUserDefaults standardUserDefaults] dataForKey: NIProcessListKey]))
		{
			@try {
				_processesDescriptors = [[NSKeyedUnarchiver unarchiveObjectWithData: data] retain];
			}
			@catch (NSException * e) {
				NSLog(@"Unable to unarchive settings: %@", e);
				_processesDescriptors = [[[NSMutableArray alloc] init] retain];
			}
		}
        else
        {
            _processesDescriptors = [[[NSMutableArray alloc] init] retain];
        }
    }
    
    return self;
}

- (void) dealloc
{
    [_processesDescriptors release];
    [super dealloc];
}


-(NSInteger) count
{
	return [_processesDescriptors count];
}

-(ProcessDescriptor*) processDescriptorAtIndex:(NSInteger) index;
{
	return [_processesDescriptors objectAtIndex:index];
}

-(void) addProcessDescriptor:(ProcessDescriptor*) descriptor
{
	[_processesDescriptors addObject:descriptor];
}

- (void) saveProcesses
{
    [[NSUserDefaults standardUserDefaults] setObject: [NSKeyedArchiver archivedDataWithRootObject: _processesDescriptors] forKey: NIProcessListKey];
}
@end
