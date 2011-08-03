//==============================================================================
//
// File:		LDrawDirective.m
//
// Purpose:		Base class for all LDraw objects provides a few basic utilities.
//
//  Created by Allen Smith on 2/19/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import "LDrawDirective.h"

#import "LDrawContainer.h"
#import "LDrawFile.h"
#import "LDrawModel.h"
	
@implementation LDrawDirective


#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//========== init ==============================================================
//
// Purpose:		Start me up. This should be called before any other subclass 
//				initialization code.
//
//==============================================================================
- (id) init
{
	self = [super init];
	
	enclosingDirective = nil;
	
	return self;
	
}//end init


//========== initWithLines:inRange: ============================================
//
// Purpose:		Convenience method to perform a blocking parse operation
//
//==============================================================================
- (id) initWithLines:(NSArray *)lines
			 inRange:(NSRange)range
{
	LDrawDirective      *directive  = nil;
	dispatch_group_t    group       = NULL;
	
#if USE_BLOCKS
	group = dispatch_group_create();
#endif

	directive = [self initWithLines:lines inRange:range parentGroup:group];
	
#if USE_BLOCKS
	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
	dispatch_release(group);
#endif
	
	return directive;
	
}//end initWithLines:inRange:



//========== initWithLines:inRange:parentGroup: ================================
//
// Purpose:		Returns the LDraw directive based on lineFromFile, a single line 
//				of LDraw code from a file.
//
//				This method is intended to be overridden by subclasses.
//				LDrawDirective's implementation simply returns a useless empty 
//				directive.
//
//				A subclass implementation would look something like:
//				---------------------------------------------------------------
//
//				Class LineTypeClass = [LDrawUtilities classForDirectiveBeginningWithLine:lineFromFile];
//				// Then initialize whatever subclass we came up with for this line.
//
//==============================================================================
- (id) initWithLines:(NSArray *)lines
			 inRange:(NSRange)range
		 parentGroup:(dispatch_group_t)parentGroup
{
	self = [self init]; // call basic initializer
	
	if([lines count] == 0)
	{
		[self autorelease];
		self = nil;
	}
	
	return self;
	
}//end initWithLines:inRange:


//========== initWithCoder: ====================================================
//
// Purpose:		Reads a representation of this object from the given coder,
//				which is assumed to always be a keyed decoder. This allows us to 
//				read and write LDraw objects as NSData.
//
//==============================================================================
- (id) initWithCoder:(NSCoder *)decoder
{
	//The superclass doesn't support NSCoding. So we just call the default init.
	self = [super init];
	
	[self setEnclosingDirective:[decoder decodeObjectForKey:@"enclosingDirective"]];
	
	return self;
	
}//end initWithCoder:


//========== encodeWithCoder: ==================================================
//
// Purpose:		Writes a representation of this object to the given coder,
//				which is assumed to always be a keyed decoder. This allows us to 
//				read and write LDraw objects as NSData.
//
//==============================================================================
- (void) encodeWithCoder:(NSCoder *)encoder
{
	//self = [super encodeWithCoder:encoder]; //super doesn't implement this method.
	
	//We encode the parent conditionally--it won't actually get encoded unless 
	// someone else encodes the parent unconditionally.
	[encoder encodeConditionalObject:enclosingDirective forKey:@"enclosingDirective"];
	
}//end encodeWithCoder:


//========== copyWithZone: =====================================================
//
// Purpose:		Returns a duplicate of this object. 
//				This thing has issules. Note caveats in LDrawContainer.
//
//==============================================================================
- (id) copyWithZone:(NSZone *)zone
{
	//Allocate a new instance because we don't inherit -copy: from anybody.
	// Note the code to ensure that the correct subclass is allocated!
	// Since LDrawDirective is the root LDraw class, all [subclass copy] 
	// messages wind up here.
	LDrawDirective *copied = [[[self class] allocWithZone:zone] init];
	
	[copied setEnclosingDirective:nil]; //if that is to be copied, then it should be assigned via accessors.
	[copied setSelected:self->isSelected];
	
	return copied;
	
}//end copyWithZone:


#pragma mark -

//---------- rangeOfDirectiveBeginningAtIndex:inLines:maxIndex: ------[static]--
//
// Purpose:		Returns the range from the first to the last LDraw line of the 
//				directive which starts at index. 
//
//				This is a core method of the LDraw parser. It allows supporting 
//				multiline directives and parallelization in parsing. 
//
// Parameters:	index	- Index of first line to be considered for the directive
//				lines	- (Potentially) All the lines of the enclosing file. The 
//						  directive is represented by a subset of the lines in 
//						  the range between index and maxIndex. 
//				maxIndex- Index of the last line which could possibly be part of 
//						  the directive. 
//
// Notes:		Subclasses of LDrawDirective override this method. You should 
//				ALWAYS call this method on a subclass. Find the subclass using 
//				+[LDrawUtilities classForDirectiveBeginningWithLine:].
//
//------------------------------------------------------------------------------
+ (NSRange) rangeOfDirectiveBeginningAtIndex:(NSUInteger)index
									 inLines:(NSArray *)lines
									maxIndex:(NSUInteger)maxIndex
{
	// Most LDraw directives are only one line. For those that aren't the 
	// subclass should override this method and perform its own parsing. 
	return NSMakeRange(index, 1);
	
}//end rangeOfDirectiveBeginningAtIndex:inLines:maxIndex:


#pragma mark -
#pragma mark DIRECTIVES
#pragma mark -

//========== draw:viewScale:parentColor: =======================================
//
// Purpose:		Issues the OpenGL code necessary to draw this element.
//
//				This method is intended to be overridden by subclasses.
//				LDrawDirective's implementation does nothing.
//
//==============================================================================
- (void) draw:(NSUInteger)optionsMask viewScale:(float)scaleFactor parentColor:(LDrawColor *)parentColor

{
	//subclasses should override this with OpenGL code to draw the line.
	
}//end draw:viewScale:parentColor:


//========== hitTest:transform:viewScale:boundsOnly:creditObject:hits: =======
//
// Purpose:		Tests the directive and any of its children for intersections 
//				between the pickRay and the directive's drawn content. 
//
// Parameters:	pickRay - in world coordinates
//				transform - transformation to apply to directive points to get 
//						to world coordinates 
//				scaleFactor - the window zoom level (1.0 == 100%)
//				boundsOnly - test the bounding box, rather than the 
//						fully-detailed geometry 
//				creditObject - object which should get credit if the 
//						current object has been hit. (Used to credit nested 
//						geometry to its parent.) If nil, the hit object credits 
//						itself. 
//				hits - keys are hit objects. Values are NSNumbers of hit depths.
//
//==============================================================================
- (void) hitTest:(Ray3)pickRay
	   transform:(Matrix4)transform
	   viewScale:(float)scaleFactor
	  boundsOnly:(BOOL)boundsOnly
	creditObject:(id)creditObject
			hits:(NSMutableDictionary *)hits
{
	//subclasses should override this with hit-detection code
}


//========== write =============================================================
//
// Purpose:		Returns the LDraw code for this directive, which can then be 
//				written out to a LDraw file and read by any LDraw interpreter.
//
//				This method is intended to be overridden by subclasses.
//				LDrawDirective's implementation does nothing.
//
//==============================================================================
- (NSString *) write
{
	//Returns a representation of the line which can be written out to a file.
	return [NSString string]; //empty string; subclasses should override this method.
	
}//end write


#pragma mark -
#pragma mark DISPLAY
#pragma mark -

//========== browsingDescription ===============================================
//
// Purpose:		Returns a representation of the directive as a short string 
//				which can be presented to the user.
//
//==============================================================================
- (NSString *) browsingDescription
{
	return [NSString stringWithFormat:@"%@", [self class]];
	
}//end browsingDescription


//========== iconName ==========================================================
//
// Purpose:		Returns the name of image file used to display this kind of 
//				object.
//
//==============================================================================
- (NSString *) iconName
{
	return @""; //Nothing.
	
}//end iconName


//========== inspectorClassName ================================================
//
// Purpose:		Returns the name of the class used to inspect this one.
//
//==============================================================================
- (NSString *) inspectorClassName
{
	return @"";
	
}//end inspectorClassName


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -


//========== ancestors =========================================================
//
// Purpose:		Returns the ancestors enclosing this directive (as well as the 
//				directive itself), with the oldest ancestor (highest node) at
//				the first index.
//
//==============================================================================
- (NSArray *) ancestors
{
	NSMutableArray *ancestors		= [NSMutableArray arrayWithCapacity:3];
	LDrawDirective *currentAncestor = self;
	
	while(currentAncestor != nil){
		[ancestors insertObject:currentAncestor atIndex:0];
		currentAncestor = [currentAncestor enclosingDirective];
	}
	
	return ancestors;
	
}//end ancestors


//========== enclosingDirective ================================================
//
// Purpose:		Bricksmith imposes a rigid hierarchy on the data in a file:
//
//				LDrawFile
//					|
//					|-----> LDrawMPDModels
//								|
//								|-----> LDrawSteps
//											|
//											|-----> LDrawParts
//											|
//											|-----> LDraw Primitives
//											|
//											|-----> LDrawMetaCommands
//
//				With the exception of LDrawFile at the root, all directives 
//				must be enclosed within another directive. This method returns 
//				the directive in which this one is stored. 
//
// Notes:		LDrawFiles return nil.
//
//==============================================================================
- (LDrawContainer *) enclosingDirective
{
	return enclosingDirective;
	
}//end enclosingDirective


//========== enclosingFile =====================================================
//
// Purpose:		Returns the highest LDrawFile which contains this directive, or 
//				nil if the directive is not in the hierarchy of an LDrawFile.
//
//==============================================================================
- (LDrawFile *) enclosingFile
{
	NSArray     *ancestors      = [self ancestors];
	id          currentAncestor = nil;
	BOOL        foundIt         = NO;
	NSInteger   counter         = 0;
	
	//loop through the ancestors looking for an LDrawFile.
	for(counter = 0; counter < [ancestors count] && foundIt == NO; counter++)
	{
		currentAncestor = [ancestors objectAtIndex:counter];
		
		if([currentAncestor isKindOfClass:[LDrawFile class]])
			foundIt = YES;
	}
	
	if(foundIt == YES)
		return currentAncestor;
	else
		return nil;
	
}//end enclosingFile


//========== enclosingModel ====================================================
//
// Purpose:		Returns the highest LDrawModel which contains this directive, or 
//				nil if the directive is not in the hierarchy of an LDrawModel.
//
//==============================================================================
- (LDrawModel *) enclosingModel
{
	NSArray     *ancestors      = [self ancestors];
	id          currentAncestor = nil;
	BOOL        foundIt         = NO;
	NSInteger   counter         = 0;
	
	//loop through the ancestors looking for an LDrawFile.
	for(counter = 0; counter < [ancestors count] && foundIt == NO; counter++)
	{
		currentAncestor = [ancestors objectAtIndex:counter];
		
		if([currentAncestor isKindOfClass:[LDrawModel class]])
			foundIt = YES;
	}
	
	if(foundIt == YES)
		return currentAncestor;
	else
		return nil;
	
}//end enclosingModel


//========== isSelected ========================================================
//
// Purpose:		Returns whether this directive thinks it's selected.
//
//==============================================================================
- (BOOL) isSelected
{
	return self->isSelected;

}//end isSelected


#pragma mark -

//========== setEnclosingDirective: ============================================
//
// Purpose:		Just about all directives can be nested inside another one, so 
//				this is where this method landed.
//
//==============================================================================
- (void) setEnclosingDirective:(LDrawContainer *)newParent
{
	enclosingDirective = newParent;
	
}//end setEnclosingDirective:


//========== setSelected: ======================================================
//
// Purpose:		Somebody make this a protocol method.
//
//==============================================================================
- (void) setSelected:(BOOL)flag
{
	self->isSelected = flag;
	
}//end setSelected:

#pragma mark -
#pragma mark <INSPECTABLE>
#pragma mark -

//========== lockForEditing ====================================================
//
// Purpose:		Provide thread-safety for this object during inspection.
//
//==============================================================================
- (void) lockForEditing
{
	[[self enclosingFile] lockForEditing];
	
}//end lockForEditing


//========== unlockEditor ======================================================
//
// Purpose:		Provide thread-safety for this object during inspection.
//
//==============================================================================
- (void) unlockEditor
{
	[[self enclosingFile] unlockEditor];
	
}//end unlockEditor


#pragma mark -
#pragma mark UTILITIES
#pragma mark -
//This is stuff that didn't really go anywhere else.

//========== description =======================================================
//
// Purpose:		Overrides NSObject method to get a more meaningful description 
//				suitable for printing to the console.
//
//==============================================================================
- (NSString *) description
{
	return [NSString stringWithFormat:@"%@\n%@", [self class], [self write]];
	
}//end description


//========== flattenIntoLines:triangles:quadrilaterals:other:currentColor: =====
//
// Purpose:		Appends the directive (or a copy of the directive) into the 
//				appropriate container. 
//
// Notes:		This is used to flatten a complicated hiearchy of primitives and 
//				part references to files containing yet more primitives into a 
//				single flat list, which may be drawn to produce a shape visually 
//				identical to the original structure. The flattened structure, 
//				however, has the advantage that it is much faster to traverse 
//				during drawing. 
//
//				This is the core of -[LDrawModel optimizeStructure].
//
//==============================================================================
- (void) flattenIntoLines:(NSMutableArray *)lines
				triangles:(NSMutableArray *)triangles
		   quadrilaterals:(NSMutableArray *)quadrilaterals
					other:(NSMutableArray *)everythingElse
			 currentColor:(LDrawColor *)parentColor
		 currentTransform:(Matrix4)transform
		  normalTransform:(Matrix3)normalTransform
				recursive:(BOOL)recursive
{
	// By default, a directive does not add itself to the list, an indication 
	// that it is not drawn. Subclasses override this routine to add themselves 
	// to the appropriate list. 

}//end flattenIntoLines:triangles:quadrilaterals:other:currentColor:


//========== isAncestorInList: =================================================
//
// Purpose:		Given a list of LDrawContainers, returns YES if any of the 
//				containers is a direct ancestor of the receiver. An ancestor is 
//				specified by enclosingDirective; each enclosingDirective can 
//				also have an ancestor. This method searchs the whole chain.
//
// Note:		I think this method is potentially buggy. Shouldn't we be doing 
//				pointer equality tests?
//
//==============================================================================
- (BOOL)isAncestorInList:(NSArray *)containers
{
	LDrawDirective	*ancestor		= self;
	BOOL			 foundInList	= NO;
	
	do
	{
		ancestor = [ancestor enclosingDirective];
		foundInList = [containers containsObject:ancestor];
		
	}while(ancestor != nil && foundInList == NO);
	
	return foundInList;
	
}//end isAncestorInList:


//========== noteNeedsDisplay ==================================================
//
// Purpose:		An object can certainly be displayed in multiple views, and we 
//				don't really care to find out which ones here. So we just post 
//				a notification, and anyone can pick that up.
//
//==============================================================================
- (void) noteNeedsDisplay
{
	[[NSNotificationCenter defaultCenter]
					postNotificationName:LDrawDirectiveDidChangeNotification
								  object:self];
}//end setNeedsDisplay


//========== optimizeOpenGL ====================================================
//
// Purpose:		The caller is asking this instance to optimize itself for faster 
//				drawing. 
//
//				OpenGL optimization is not thread-safe. No OpenGL optimization 
//				is ever performed during parsing because of the thread-safety 
//				limitation, so you are responsible for calling this method on 
//				newly-parsed models. 
//
//==============================================================================
- (void) optimizeOpenGL
{
	// only meaningful in a subclass
	
}//end optimizeOpenGL


//========== registerUndoActions: ==============================================
//
// Purpose:		Registers the undo actions that are unique to this subclass, 
//				not to any superclass.
//
//==============================================================================
- (void) registerUndoActions:(NSUndoManager *)undoManager
{
	//LDrawDirectives are fairly abstract, so all undoable attributes come 
	// from subclasses.
	
}//end registerUndoActions:


@end
