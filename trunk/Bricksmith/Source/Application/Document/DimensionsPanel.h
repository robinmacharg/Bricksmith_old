//==============================================================================
//
// File:		DimensionsPanel.h
//
// Purpose:		Dialog to display the dimensions for a model.
//
//  Created by Allen Smith on 8/21/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import <Cocoa/Cocoa.h>

@class LDrawContainer;

@interface DimensionsPanel : NSPanel{
	LDrawContainer *container;
	
	IBOutlet DimensionsPanel *dimensionsPanel;
}

//Initialization
+ (DimensionsPanel *) dimensionPanelForContainer:(LDrawContainer *)containerIn;
- (id) initWithContainer:(LDrawContainer *)container;

//Accessors
- (LDrawContainer *) container;
- (void) setContainer:(LDrawContainer *)newContainer;

//Actions
- (IBAction) okButtonClicked:(id)sender;

@end
