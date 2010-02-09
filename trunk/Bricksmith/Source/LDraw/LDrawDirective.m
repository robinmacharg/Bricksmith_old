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
#import "MacLDraw.h"
	
@implementation LDrawDirective


#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//---------- directiveWithString: ------------------------------------[static]--
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
//				//The linecode (0, 1, 2, 3, 4, 5) identifies the type of command, 
//				// and is always the first character in the line.
//				NSString *lineCode = [lineFromFile substringToIndex:1];
//				Class LineTypeClass = [LDrawUtilities classForLineType:[lineCode intValue]];
//				//Now initialize whatever subclass we came up with for this line.
//				newDirective = [LineTypeClass directiveWithString:lineFromFile];
//
//------------------------------------------------------------------------------
+ (id) directiveWithString:(NSString *)lineFromFile
{
	id newDirective = [LDrawDirective new];
	
	return [newDirective autorelease];
	
}//end directiveWithString:


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
#pragma mark DIRECTIVES
#pragma mark -

//========== draw:parentColor: =================================================
//
// Purpose:		Issues the OpenGL code necessary to draw this element.
//
//				This method is intended to be overridden by subclasses.
//				LDrawDirective's implementation does nothing.
//
//==============================================================================
- (void) draw:(NSUInteger)optionsMask parentColor:(GLfloat *)parentColor
{
	//subclasses should override this with OpenGL code to draw the line.
	
}//end draw:parentColor:


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
		currentAncestor = [ancestors objectAtIndex:0];
		
		if([currentAncestor isKindOfClass:[LDrawFile class]])
			foundIt = YES;
	}
	
	if(foundIt == YES)
		return currentAncestor;
	else
		return nil;
	
}//end enclosingFile


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

//========== snapshot ==========================================================
//
// Purpose:		Record the current state of our object in a way suitable for 
//				undo/redo.
//
// Note:		Undo operations are stored on a *stack*, so the order of undo 
//				registration in the code is the opposite from the order in 
//				which the undo operations are executed.
//
//				Subclasses should only override this method to provide a custom 
//				undo name, but even that can be placed just as well in 
//				-registerUndoActions:.
//
//==============================================================================
- (void) snapshot
{
	// ** Read code bottom-to-top ** //
	
	NSDocument		*currentDocument	= [[NSDocumentController sharedDocumentController] currentDocument];
	NSUndoManager	*undoManager		= [currentDocument undoManager];
	

	//Now that all the undo actions have happened, post a notification that 
	// the object has changed.
	[[undoManager prepareWithInvocationTarget:[NSNotificationCenter defaultCenter]]
			postNotificationName:LDrawDirectiveDidChangeNotification
						  object:self];
	
	[self registerUndoActions:undoManager];
	//Now issue the commands necessary to revert our object to current values.
	
	[[undoManager prepareWithInvocationTarget:self] snapshot];
	//First thing to call is snapshot, so that redo commands are filled 
	// with the values of the current state.
	
}//end snapshot


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
- (void) flattenIntoLines:(LDrawStep *)lines
				triangles:(LDrawStep *)triangles
		   quadrilaterals:(LDrawStep *)quadrilaterals
					other:(LDrawStep *)everythingElse
			 currentColor:(LDrawColorT)currentColor
		 currentTransform:(Matrix4)transform
		  normalTransform:(Matrix3)normalTransform
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
