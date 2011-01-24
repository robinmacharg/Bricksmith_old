//==============================================================================
//
// File:		LDrawDrawableElement.m
//
// Purpose:		Abstract superclass for all LDraw elements that can actually be 
//				drawn (polygons and parts). The class wraps common functionality 
//				such as color and mouse-selection.
//
//  Created by Allen Smith on 4/20/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import "LDrawDrawableElement.h"

#import <OpenGL/glu.h>

#import "ColorLibrary.h"
#import "LDrawColor.h"
#import "LDrawContainer.h"
#import "MacLDraw.h"

@implementation LDrawDrawableElement

#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -


//========== init ==============================================================
//
// Purpose:		Create a fresh object. This is the default initializer.
//
//==============================================================================
- (id) init
{
	self = [super init];
	
	self->hidden = NO;
	
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
	self = [super initWithCoder:decoder];
	
	[self setLDrawColor:[decoder	decodeObjectForKey:@"color"]];
	[self setHidden:[decoder		decodeBoolForKey:@"hidden"]];
	
	// If the part's color comes from the library, use the library version 
	// instead of the dearchived one. 
	//
	// Note: This won't help us for file-local colors. They are messy. We don't 
	//		 know what model we belong to until after the part's step has been 
	//		 fully unpacked and added to the model. Only then can we finally 
	//		 retrieve the model's local color library. Currently we have no 
	//		 hooks for that operation; we need a -directiveDidMoveToModel: call 
	//		 and distribute it to all children. 
	ColorLibrary    *colorLibrary   = [ColorLibrary sharedColorLibrary];
	LDrawColor      *libraryColor   = [colorLibrary colorForCode:[self->color colorCode]];
	if(libraryColor)
	{
		[self setLDrawColor:libraryColor];
	}
	
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
	[super encodeWithCoder:encoder];
	
	[encoder encodeObject:self->color	forKey:@"color"];
	[encoder encodeBool:hidden			forKey:@"hidden"];
	
}//end encodeWithCoder:



//========== copyWithZone: =====================================================
//
// Purpose:		Returns a duplicate of this file.
//
//==============================================================================
- (id) copyWithZone:(NSZone *)zone
{
	LDrawDrawableElement *copied = (LDrawDrawableElement *)[super copyWithZone:zone];
	
	// Colors are references, so they don't get copied
	[copied setLDrawColor:[self LDrawColor]];
	
	return copied;
	
}//end copyWithZone:


#pragma mark -
#pragma mark DIRECTIVES
#pragma mark -

//========== draw:parentColor: =================================================
//
// Purpose:		Draws the part. This is a wrapper method that just sets up the 
//				drawing context (the color), then calls a subroutine which 
//				actually draws the element.
//
//==============================================================================
- (void) draw:(NSUInteger)optionsMask parentColor:(LDrawColor *)parentColor
{
	//[super draw]; //does nothing anyway; don't call it.
	
	if(self->hidden == NO)
	{
		// If the part is selected, we need to give some indication. We do this by 
		// drawing it as a wireframe instead of a filled color. This setting also 
		// conveniently applies to all referenced parts herein. 
		if(self->isSelected == YES)
		{
			// a bug on Intel iMacs is causing the wireframe not to get drawn 
			// unless lighting OR blending is off. We don't need blending here 
			// because we are already drawing wireframes!
			glDisable(GL_BLEND);
			glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
		}
		
		// Load names for mouse-selection, if that's the mode we're in.
		// Only elements contained within a step should ever wind up here.
		// Any other nestings are invalid.
		if((optionsMask & DRAW_HIT_TEST_MODE) != 0)
		{
			LDrawContainer  *enclosingStep  = [self enclosingDirective];
			NSInteger       partIndex       = [enclosingStep indexOfDirective:self]; 
			NSInteger       stepIndex       = [[enclosingStep enclosingDirective] indexOfDirective:enclosingStep];
			glLoadName( stepIndex*STEP_NAME_MULTIPLIER + partIndex );
			//SERIOUS FLAW!!! This object is not required to have a parent. But 
			// currently, such an orphan would never be drawn. So life goes on.
		}
		
		//Draw, for goodness sake!
		
		switch([self->color colorCode])
		{
			case LDrawCurrentColor:
				// Just draw; don't fool with colors. A significant portion of our 
				// drawing code probably falls into this category.
				[self drawElement:optionsMask withColor:parentColor];
				break;
				
			case LDrawEdgeColor:
				[self drawElement:optionsMask withColor:[self->color complimentColor]];
				break;
			
			case LDrawColorCustomRGB:
			default:
				[self drawElement:optionsMask withColor:self->color];
				break;
		}
		
		// Done drawing a selected part? Then switch back to normal filled 
		// drawing. 
		if(self->isSelected == YES)
		{
			glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
			glEnable(GL_BLEND);
		}
	}
	
}//end draw:optionsMask:


//========== writeToVertexBuffer:parentColor: ==================================
//
// Purpose:		Resolve the correct color
//
//==============================================================================
- (VBOVertexData *) writeToVertexBuffer:(VBOVertexData *)vertexBuffer
							parentColor:(LDrawColor *)parentColor
{
	VBOVertexData *endPointer = NULL;
	
	if(parentColor == nil || self->color == nil)
	{
		NSLog(@"nil color");
	}
	
	switch([self->color colorCode])
	{
		case LDrawCurrentColor:
			//Just draw; don't fool with colors. A significant portion of our 
			// drawing code probably falls into this category.
			endPointer = [self writeElementToVertexBuffer:vertexBuffer withColor:parentColor];
			break;
			
		case LDrawEdgeColor:
			// We'll need to turn this on to support file-local colors.
			//				ColorLibrary	*colorLibrary	= [[[self enclosingDirective] enclosingModel] colorLibrary];
			//				LDrawColor		*colorObject	= [colorLibrary colorForCode:self->color];
			endPointer = [self writeElementToVertexBuffer:vertexBuffer withColor:[parentColor complimentColor]];
			break;
			
		case LDrawColorCustomRGB:
		default:
			endPointer = [self writeElementToVertexBuffer:vertexBuffer withColor:self->color];
			break;
	}
	
	return endPointer;
	
}//end writeToVertexBuffer:parentColor:


//========== drawElement:withColor: ============================================
//
// Purpose:		Draws the actual drawable stuff (polygons, etc.) of the element. 
//				This is a subroutine of the -draw: method, which wraps some 
//				shared functionality such as setting colors.
//
//==============================================================================
- (void) drawElement:(NSUInteger) optionsMask withColor:(LDrawColor *)drawingColor
{
	//implemented by subclasses.
	
}//end drawElement:withColor:


//========== writeElementToVertexBuffer:withColor: =============================
//
// Purpose:		Copies the actual vertex data into the buffer, now that setup 
//				has been done in -writeToVertexBuffer: 
//
//==============================================================================
- (VBOVertexData *) writeElementToVertexBuffer:(VBOVertexData *)vertexBuffer
									 withColor:(LDrawColor *)drawingColor
{
	//implemented by subclasses.
	return NULL;
}

#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== boundingBox3 ======================================================
//
// Purpose:		Returns the minimum and maximum points of the box which 
//				perfectly contains this object.
//
//==============================================================================
- (Box3) boundingBox3
{
	Box3 bounds = InvalidBox;
	
	//You shouldn't be here. Look in a subclass.
	
	return bounds;
	
}//end boundingBox3


//========== projectedBoundingBoxWithModelView:projection:view: ================
//
// Purpose:		Returns the 2D projection (you should ignore the z) of the 
//				object's bounds. 
//
//==============================================================================
- (Box3) projectedBoundingBoxWithModelView:(const GLdouble *)modelViewGLMatrix
								projection:(const GLdouble *)projectionGLMatrix
									  view:(const GLint *)viewport
{
	Box3        bounds              = [self boundingBox3];
	GLdouble    windowGLPoint[3];
	Point3      windowPoint         = ZeroPoint3;
	Box3        projectedBounds     = InvalidBox;
	
	if(V3EqualBoxes(bounds, InvalidBox) == NO)
	{		
		// front lower left
		gluProject(bounds.min.x, bounds.min.y, bounds.min.z, 
				   modelViewGLMatrix, 
				   projectionGLMatrix, 
				   viewport, 
				   &windowGLPoint[0], &windowGLPoint[1], &windowGLPoint[2]);
		windowPoint     = V3Make(windowGLPoint[0], windowGLPoint[1], windowGLPoint[2]);
		projectedBounds = V3UnionBoxAndPoint(projectedBounds, windowPoint);
		
		// front lower right
		gluProject(bounds.max.x, bounds.min.y, bounds.min.z, 
				   modelViewGLMatrix, 
				   projectionGLMatrix, 
				   viewport, 
				   &windowGLPoint[0], &windowGLPoint[1], &windowGLPoint[2]);
		windowPoint     = V3Make(windowGLPoint[0], windowGLPoint[1], windowGLPoint[2]);
		projectedBounds = V3UnionBoxAndPoint(projectedBounds, windowPoint);
		
		// front upper right
		gluProject(bounds.max.x, bounds.max.y, bounds.min.z, 
				   modelViewGLMatrix, 
				   projectionGLMatrix, 
				   viewport, 
				   &windowGLPoint[0], &windowGLPoint[1], &windowGLPoint[2]);
		windowPoint     = V3Make(windowGLPoint[0], windowGLPoint[1], windowGLPoint[2]);
		projectedBounds = V3UnionBoxAndPoint(projectedBounds, windowPoint);
		
		// front upper left
		gluProject(bounds.min.x, bounds.max.y, bounds.min.z, 
				   modelViewGLMatrix, 
				   projectionGLMatrix, 
				   viewport, 
				   &windowGLPoint[0], &windowGLPoint[1], &windowGLPoint[2]);
		windowPoint     = V3Make(windowGLPoint[0], windowGLPoint[1], windowGLPoint[2]);
		projectedBounds = V3UnionBoxAndPoint(projectedBounds, windowPoint);
		
		// back lower left
		gluProject(bounds.min.x, bounds.min.y, bounds.max.z, 
				   modelViewGLMatrix, 
				   projectionGLMatrix, 
				   viewport, 
				   &windowGLPoint[0], &windowGLPoint[1], &windowGLPoint[2]);
		windowPoint     = V3Make(windowGLPoint[0], windowGLPoint[1], windowGLPoint[2]);
		projectedBounds = V3UnionBoxAndPoint(projectedBounds, windowPoint);
		
		// back lower right
		gluProject(bounds.max.x, bounds.min.y, bounds.max.z, 
				   modelViewGLMatrix, 
				   projectionGLMatrix, 
				   viewport, 
				   &windowGLPoint[0], &windowGLPoint[1], &windowGLPoint[2]);
		windowPoint     = V3Make(windowGLPoint[0], windowGLPoint[1], windowGLPoint[2]);
		projectedBounds = V3UnionBoxAndPoint(projectedBounds, windowPoint);
		
		// back upper right
		gluProject(bounds.max.x, bounds.max.y, bounds.max.z, 
				   modelViewGLMatrix, 
				   projectionGLMatrix, 
				   viewport, 
				   &windowGLPoint[0], &windowGLPoint[1], &windowGLPoint[2]);
		windowPoint     = V3Make(windowGLPoint[0], windowGLPoint[1], windowGLPoint[2]);
		projectedBounds = V3UnionBoxAndPoint(projectedBounds, windowPoint);
		
		// back upper left
		gluProject(bounds.min.x, bounds.max.y, bounds.max.z, 
				   modelViewGLMatrix, 
				   projectionGLMatrix, 
				   viewport, 
				   &windowGLPoint[0], &windowGLPoint[1], &windowGLPoint[2]);
		windowPoint     = V3Make(windowGLPoint[0], windowGLPoint[1], windowGLPoint[2]);
		projectedBounds = V3UnionBoxAndPoint(projectedBounds, windowPoint);
	}
	
	return projectedBounds;
	
}//end projectedBoundingBoxWithModelView:projection:view:


//========== isHidden ==========================================================
//
// Purpose:		Returns whether this element will be drawn or not.
//
//==============================================================================
- (BOOL) isHidden
{
	return self->hidden;
	
}//end isHidden


//========== LDrawColor ========================================================
//
// Purpose:		Returns the LDraw color code of the receiver.
//
//==============================================================================
-(LDrawColor *) LDrawColor
{
	return color;
	
}//end LDrawColor


//========== position ==========================================================
//
// Purpose:		Returns some position for the element. This is used by 
//				drag-and-drop. This is not necessarily human-usable information.
//
//==============================================================================
- (Point3) position
{
	return ZeroPoint3;
	
}//end position


#pragma mark -

//========== setEnclosingDirective: ============================================
//
// Purpose:		We are being added to another directive.
//
//==============================================================================
- (void) setEnclosingDirective:(LDrawContainer *)newParent
{
	enclosingDirective = newParent;
	
}//end setEnclosingDirective:


//========== setHidden: ========================================================
//
// Purpose:		Sets whether this part will be drawn, or whether it will be 
//				skipped during drawing. This setting only affects drawing; 
//				hidden parts will always be written out. Also, note that 
//				hiddenness is a temporary state; it is not saved and restored.
//
//==============================================================================
- (void) setHidden:(BOOL) flag
{
	self->hidden = flag;
	
}//end setHidden:


//========== setLDrawColor: ====================================================
//
// Purpose:		Sets the color of this element.
//
//==============================================================================
- (void) setLDrawColor:(LDrawColor *)newColor
{
	[newColor retain];
	[self->color release];
	self->color = newColor;
	
}//end setLDrawColor:


#pragma mark -
#pragma mark MOVEMENT
#pragma mark -

//========== displacementForNudge: =============================================
//
// Purpose:		Returns the amount by which the element wants to move, given a 
//				"nudge" in the specified direction. A "nudge" is generated by 
//				pressing the arrow keys. If they feel it appropriate, subclasses 
//				are perfectly welcome to scale this value. (LDrawParts do this.)
//
//==============================================================================
- (Vector3) displacementForNudge:(Vector3)nudgeVector
{
	//possibly refined by subclasses.
	return nudgeVector;
	
}//end displacementForNudge:


//========== moveBy: ===========================================================
//
// Purpose:		Displace the receiver by the given amounts in each direction. 
//				The amounts in moveVector or relative to the element's current 
//				location.
//
//				Subclasses are required to move by exactly this amount. Any 
//				adjustments they wish to make need to be returned in 
//				-displacementForNudge:.
//
//==============================================================================
- (void) moveBy:(Vector3)moveVector
{
	//implemented by subclasses.
	
}//end moveBy:


//========== position:snappedToGrid: ===========================================
//
// Purpose:		Orients position at discrete points separated by the given grid 
//				spacing. 
//
// Notes:		This method may be overridden by subclasses to provide more 
//				intelligent grid alignment. 
//
//				This method is provided mainly as a service to drag-and-drop. 
//				In the case of LDrawParts, you should generally avoid this 
//				method in favor of 
//				-[LDrawPart components:snappedToGrid:minimumAngle:].
//
//==============================================================================
- (Point3) position:(Point3)position
	  snappedToGrid:(float)gridSpacing
{
	position.x = roundf(position.x/gridSpacing) * gridSpacing;
	position.y = roundf(position.y/gridSpacing) * gridSpacing;
	position.z = roundf(position.z/gridSpacing) * gridSpacing;
	
	return position;
	
}//end position:snappedToGrid:


#pragma mark -
#pragma mark UTILITIES
#pragma mark -

//========== flattenIntoLines:triangles:quadrilaterals:other:currentColor: =====
//
// Purpose:		Appends the directive into the appropriate container. 
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
	// Resolve the correct color and set it. Our subclasses will be responsible 
	// for then adding themselves to the correct list. 

	// Figure out the actual color of the directive.
	
	if([self->color colorCode] == LDrawCurrentColor)
	{
		if([parentColor colorCode] == LDrawCurrentColor)
		{
			// just add
		}
		else
		{
			// set directiveCopy to parent color
			[self setLDrawColor:parentColor];
		}
	}
	else if([self->color colorCode] == LDrawEdgeColor)
	{
		if([parentColor colorCode] == LDrawCurrentColor)
		{
			// just add
		}
		else
		{
			// set directiveCopy to compliment color
			LDrawColor  *complimentColor        = [parentColor complimentColor];
			
			[self setLDrawColor:complimentColor];
			
			// then add.
		}
	}
	else
	{
		// This directive is already explicitly colored. Just add.
	}
	
}//end flattenIntoLines:triangles:quadrilaterals:other:currentColor:


@end
