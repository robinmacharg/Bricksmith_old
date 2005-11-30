//
//  ExtendedSplitView.h
//  Bricksmith
//
//  Created by Allen Smith on 11/11/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ExtendedSplitView : NSSplitView {
	NSString *autosaveName;
}

- (NSString *) autosaveName;
- (void) setAutosaveName:(NSString *)newName;

- (void) restoreConfiguration;
- (void) saveConfiguration;

@end
