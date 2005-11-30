//
//  ExtendedSplitView.m
//  Bricksmith
//
//  Created by Allen Smith on 11/11/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "ExtendedSplitView.h"


@implementation ExtendedSplitView

- (NSString *) autosaveName {
	return self->autosaveName;
}


- (void) setAutosaveName:(NSString *)newName {
	[newName retain];
	[self->autosaveName release];
	
	autosaveName = newName;
}

- (void) restoreConfiguration {

	NSUserDefaults	*userDefaults	= [NSUserDefaults standardUserDefaults];
	NSArray			*subviews		= [self subviews];
	NSView			*currentSubview	= nil;
	NSRect			 currentRect	= NSZeroRect;
	NSString		*rectString		= nil;
	NSMutableArray	*frameSizes		= [NSMutableArray array];
	int				 counter		= 0;
	
	if(self->autosaveName != nil){
		frameSizes = [userDefaults objectForKey:self->autosaveName];
		if(frameSizes != nil && [subviews count] == [frameSizes count])
		{
			for(counter = 0; counter < [subviews count]; counter++){
				currentSubview	= [subviews objectAtIndex:counter];
				rectString		= [frameSizes objectAtIndex:counter];
				currentRect		= NSRectFromString(rectString);
				
				if(NSMinX(currentRect) == 1e6 && NSMinY(currentRect) == 1e6) {
					currentRect.size.height = 0;
					currentRect.size.width = 0;
				}				   
				
				[currentSubview setFrame:currentRect];
			}
		}
	}
	[self adjustSubviews];
	
}//end restoreConfiguration


- (void) saveConfiguration{
	
	NSUserDefaults	*userDefaults	= [NSUserDefaults standardUserDefaults];
	NSArray			*subviews		= [self subviews];
	NSView			*currentSubview	= nil;
	NSRect			 currentRect	= NSZeroRect;
	NSString		*rectString		= nil;
	NSMutableArray	*frameSizes		= [NSMutableArray array];
	int				 counter		= 0;
	
	for(counter = 0; counter < [subviews count]; counter++){
		currentSubview	= [subviews objectAtIndex:counter];
		currentRect		= [currentSubview frame];
		rectString		= NSStringFromRect(currentRect);
		[frameSizes addObject:rectString];
	}
	
	if(self->autosaveName != nil){
		NSLog(@"saving");
		[userDefaults setObject:frameSizes forKey:self->autosaveName];
	}
	
}//end saveConfiguration


- (void) dealloc {
	if(self->autosaveName != nil)
		[self saveConfiguration];
	[super dealloc];
}

@end
