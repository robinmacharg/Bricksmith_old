//==============================================================================
//
// File:		LDrawGLView.h
//
// Purpose:		Draws an LDrawFile with OpenGL.
//
//  Created by Allen Smith on 4/17/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import <Cocoa/Cocoa.h>
#import <OpenGL/GL.h>

#import "LDrawColor.h"
#import "MatrixMath.h"

//Forward declarations
@class LDrawDirective;
@class LDrawDocument;

////////////////////////////////////////////////////////////////////////////////
//
//		Types and Constants
//
////////////////////////////////////////////////////////////////////////////////

#define SIMPLIFICATION_THRESHOLD	0.4 //seconds
#define CAMERA_DISTANCE_FACTOR		7	//cameraLocation = modelSize * CAMERA_DISTANCE_FACTOR


typedef enum {
	ProjectionModePerspective	= 0,
	ProjectionModeOrthographic	= 1
} ProjectionModeT;


typedef enum {
	LDrawGLDrawNormal			= 0,	//full draw
	LDrawGLDrawExtremelyFast	= 1		//bounds only
} RotationDrawModeT;


typedef enum {
	RotateSelectTool			= 0,	//click to select, drag to rotate
	AddToSelectionTool			= 1,	//clicked parts are added to the current selection
	PanScrollTool				= 2,	//"grabber" to scroll around while dragging
	SmoothZoomTool				= 3,	//zoom in and out based on drag direction
	ZoomInTool					= 4,	//click to zoom in
	ZoomOutTool					= 5		//click to zoom out
} ToolModeT;


typedef enum {
	ViewingAngle3D				= 0,
	ViewingAngleFront			= 1,
	ViewingAngleBack			= 2,
	ViewingAngleLeft			= 3,
	ViewingAngleRight			= 4,
	ViewingAngleTop				= 5,
	ViewingAngleBottom			= 6
} ViewingAngleT;


////////////////////////////////////////////////////////////////////////////////
//
//		LDrawGLView
//
////////////////////////////////////////////////////////////////////////////////
@interface LDrawGLView : NSOpenGLView <LDrawColorable>
{
	BOOL				 acceptsFirstResponder;	//YES if we can become key
	NSString			*autosaveName;
	GLfloat				 cameraDistance;
	LDrawColorT			 color;					//default color to draw parts if none is specified
	NSString			*currentKeyCharacters;	//identifies the current keys down, independent of modifiers (empty string if no keys down)
	unsigned int		 currentKeyModifiers;	//identifiers the current modifiers down (including device-dependent)
	LDrawDirective		*fileBeingDrawn;		//Should only be an LDrawFile or LDrawModel.
												// if you want to do anything else, you must 
												// tweak the selection code in LDrawDrawableElement
												// and here in -mouseUp: to handle such cases.
	BOOL				 isDragging;			//true if the last mousedown was followed by a drag.
	GLfloat				 glColor[4];			//OpenGL equivalent of the LDrawColor.
	ProjectionModeT		 projectionMode;
	RotationDrawModeT	 rotationDrawMode;		//drawing detail while rotating.
	ToolModeT			 toolMode;				//current tool in effect.
	ViewingAngleT		 viewingAngle;			//our orientation
	
	IBOutlet LDrawDocument	*document;			//optional weak link. Enables editing capabilities.
}

//Accessors
- (LDrawColorT) LDrawColor;
- (NSPoint) centerPoint;
- (Matrix4) getInverseMatrix;
- (ViewingAngleT) viewingAngle;
- (float) zoomPercentage;
- (void) setAcceptsFirstResponder:(BOOL)flag;
- (void) setAutosaveName:(NSString *)newName;
- (void) setLDrawColor:(LDrawColorT)newColor;
- (void) setLDrawDirective:(LDrawDirective *) newFile;
- (void) setProjectionMode:(ProjectionModeT) newProjectionMode;
- (void) setViewingAngle:(ViewingAngleT) newAngle;
- (void) setZoomPercentage:(float) newPercentage;

//Actions
- (IBAction) viewingAngleSelected:(id)sender;
- (IBAction) zoomIn:(id)sender;
- (IBAction) zoomOut:(id)sender;

//Events
- (void)mousePartSelection:(NSEvent *)theEvent;
- (LDrawDirective *) getPartFromHits:(GLuint *)nameBuffer hitCount:(GLuint)numberHits;
- (void) panDragged:(NSEvent *)theEvent;
- (void)rotationDragged:(NSEvent *)theEvent;
- (void) zoomDragged:(NSEvent *)theEvent;

//Notifications
- (void) displayNeedsUpdating:(NSNotification *)notification;

//Utilities
- (void) resetFrameSize;
- (void) restoreConfiguration;
- (void) makeProjection;
- (void) saveConfiguration;
- (void) scrollCenterToPoint:(NSPoint)newCenter;

@end

////////////////////////////////////////////////////////////////////////////////
//
//		Delegate Methods
//
////////////////////////////////////////////////////////////////////////////////
@interface NSObject (LDrawGLViewDelegate)

- (void) LDrawGLViewBecameFirstResponder:(LDrawGLView *)glView;

//Delegate method is called when the user has changed the selection of parts 
// by clicking in the view. This does not actually do any selecting; that is 
// left entirely to the delegate. Some may rightly question the design of this 
// system.
- (void)	LDrawGLView:(LDrawGLView *)glView
 wantsToSelectDirective:(LDrawDirective *)directiveToSelect
   byExtendingSelection:(BOOL) shouldExtend;
@end