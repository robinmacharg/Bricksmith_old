//==============================================================================
//
// File:		LDrawModel.h
//
// Purpose:		Represents a collection of Lego bricks that form a single model.
//
//  Created by Allen Smith on 2/19/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import <Cocoa/Cocoa.h>

#import "LDrawContainer.h"
@class ColorLibrary;
@class LDrawFile;
@class LDrawStep;

typedef enum {
	LDrawOfficialModel = 1,
	LDrawUnofficialModel = 2
} LDrawDotOrgModelStatusT;


////////////////////////////////////////////////////////////////////////////////
//
// class LDrawModel
//
////////////////////////////////////////////////////////////////////////////////
@interface LDrawModel : LDrawContainer <NSCoding>
{	
	NSString				*modelDescription;
	NSString				*fileName;
	NSString				*author;
	LDrawDotOrgModelStatusT	 ldrawDotOrgStatus;
	
	Box3					*cachedBounds;			// used only for optimized parts
	ColorLibrary			*colorLibrary;			// in-scope !COLOURS local to the model
	BOOL					 stepDisplayActive;		// YES if we are only display steps 1-currentStepDisplayed
	NSUInteger				 currentStepDisplayed;	// display up to and including this step index
	
	//steps are stored in the superclass.
	
	// Drag and Drop
	LDrawStep				*draggingDirectives;
}

//Initialization
+ (id) newModel;
+ (id) modelWithLines:(NSArray *)lines;
- (id) initNew;
- (id) initWithLines:(NSArray *)lines;

//Accessors
- (NSString *) category;
- (ColorLibrary *) colorLibrary;
- (NSArray *) draggingDirectives;
- (LDrawFile *)enclosingFile;
- (NSString *)modelDescription;
- (NSString *)fileName;
- (NSString *)author;
- (LDrawDotOrgModelStatusT) ldrawRepositoryStatus;
- (NSUInteger) maximumStepIndexForStepDisplay;
- (Tuple3) rotationAngleForStepAtIndex:(NSUInteger)stepNumber;
- (BOOL) stepDisplay;
- (NSArray *) steps;
- (LDrawStep *) visibleStep;

- (void) setDraggingDirectives:(NSArray *)directives;
- (void) setModelDescription:(NSString *)newDescription;
- (void) setFileName:(NSString *)newName;
- (void) setAuthor:(NSString *)newAuthor;
- (void) setLDrawRepositoryStatus:(LDrawDotOrgModelStatusT) newStatus;
- (void) setStepDisplay:(BOOL)flag;
- (void) setMaximumStepIndexForStepDisplay:(NSUInteger)stepIndex;

//Actions
- (LDrawStep *) addStep;
- (void) addStep:(LDrawStep *)newStep;
- (void) makeStepVisible:(LDrawStep *)step;

//Utilities
- (NSUInteger) maxStepIndexToOutput;
- (NSUInteger) numberElements;
- (void) optimizeStructure;
- (NSArray *) parseHeaderFromLines:(NSArray *) lines;
- (BOOL) line:(NSString *)line isValidForHeader:(NSString *)headerKey;

@end
