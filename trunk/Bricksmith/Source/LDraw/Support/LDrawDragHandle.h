//==============================================================================
//
// File:		LDrawDragHandle.h
//
// Purpose:		In-scene widget to manipulate a vertex.
//
// Notes:		Sub-classes LDrawDrawableElement to get some dragging behavior.
//
// Modified:	02/25/2011 Allen Smith. Creation Date.
//
//==============================================================================
#import <Foundation/Foundation.h>
#import <OpenGL/glu.h>

#import "LDrawDrawableElement.h"


////////////////////////////////////////////////////////////////////////////////
//
// LDrawDragHandle
//
////////////////////////////////////////////////////////////////////////////////
@interface LDrawDragHandle : LDrawDrawableElement
{
	NSInteger   tag;
	Point3		position;
	Point3		initialPosition;
	
	GLUquadric	*sphere;
	
	id          target;
	SEL			action;
}

- (id) initWithTag:(NSInteger)tag position:(Point3)positionIn;

// Accessors
- (Point3) initialPosition;
- (Point3) position;
- (NSInteger) tag;
- (id) target;

- (void) setAction:(SEL)action;
- (void) setPosition:(Point3)positionIn updateTarget:(BOOL)update;
- (void) setTarget:(id)sender;

- (void) draw:(NSUInteger) optionsMask parentColor:(LDrawColor *)parentColor;

@end

