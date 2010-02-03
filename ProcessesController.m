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
            _processesDescriptors = [[NSKeyedUnarchiver unarchiveObjectWithData: data] retain];
        else
        {
            //default groups
			ProcessDescriptor* pd = [[ProcessDescriptor alloc] init];
			pd.name = @"local";
			pd.processType = @"rtorrent";
			pd.manualConfig = YES;
			pd.host = @"127.0.0.1";
			pd.port = 5000;
			
            _processesDescriptors = [[NSMutableArray alloc] initWithObjects: pd, nil];
            [self saveProcesses]; //make sure this is saved right away
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

- (void) saveProcesses
{
    [[NSUserDefaults standardUserDefaults] setObject: [NSKeyedArchiver archivedDataWithRootObject: _processesDescriptors] forKey: NIProcessListKey];
}
@end
