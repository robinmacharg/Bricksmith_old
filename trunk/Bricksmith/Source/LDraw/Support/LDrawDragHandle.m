//==============================================================================
//
// File:		LDrawDragHandle.m
//
// Purpose:		In-scene widget to manipulate a vertex.
//
// Modified:	02/25/2011 Allen Smith. Creation Date.
//
//==============================================================================
#import "LDrawDragHandle.h"

#import OPEN_GL_HEADER
#import <stdlib.h>

#import "LDrawUtilities.h"

// Shared tag to draw the standard drag handle sphere
static GLuint   vaoTag          = 0;
static GLuint   vboTag          = 0;
static GLuint   vboVertexCount  = 0;


@implementation LDrawDragHandle

//========== initWithTag:position: =============================================
//
// Purpose:		Initialize the object with a tag to identify what vertex it is 
//				connected to. 
//
//==============================================================================
- (id) initWithTag:(NSInteger)tagIn
		  position:(Point3)positionIn
{
	self = [super init];
	if(self)
	{
		tag             = tagIn;
		position        = positionIn;
		initialPosition = positionIn;
		
		[LDrawDragHandle makeSphereWithLongitudinalCount:8 latitudinalCount:8];
	}
	
	return self;

}//end initWithTag:position:


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== initialPosition ===================================================
//
// Purpose:		Returns the coordinate this handle what at when initialized.
//
//==============================================================================
- (Point3) initialPosition
{
	return self->initialPosition;
}


//========== isSelected ========================================================
//
// Purpose:		Drag handles only show up when their associated primitive is 
//				selected, so we always report being selected. This will make us 
//				more transparent to the view selection code. 
//
//==============================================================================
- (BOOL) isSelected
{
	return YES;
}


//========== position ==========================================================
//
// Purpose:		Returns the world-coordinate location of the handle.
//
//==============================================================================
- (Point3) position
{
	return self->position;
}


//========== tag ===============================================================
//
// Purpose:		Returns the identifier for this handle. Used to associate the 
//				handle with a vertex. 
//
//==============================================================================
- (NSInteger) tag
{
	return self->tag;
}


//========== target ============================================================
//
// Purpose:		Returns the object which owns the drag handle.
//
//==============================================================================
- (id) target
{
	return self->target;
}


#pragma mark -

//========== setAction: ========================================================
//
// Purpose:		Sets the method to invoke when the handle is repositioned.
//
//==============================================================================
- (void) setAction:(SEL)actionIn
{
	self->action = actionIn;
}


//========== setPosition:updateTarget: =========================================
//
// Purpose:		Updates the current handle position, and triggers the action if 
//				update flag is YES. 
//
//==============================================================================
- (void) setPosition:(Point3)positionIn
		updateTarget:(BOOL)update
{
	self->position = positionIn;
	
	if(update)
	{
		[NSApp sendAction:self->action to:self->target from:self];
	}
}//end setPosition:updateTarget:


//========== setTarget: ========================================================
//
// Purpose:		Sets the object to invoke the action on.
//
//==============================================================================
- (void) setTarget:(id)sender
{
	self->target = sender;
}


#pragma mark -
#pragma mark DRAWING
#pragma mark -

//========== draw:parentColor: =================================================
//
// Purpose:		Draw the drag handle.
//
//==============================================================================
- (void) draw:(NSUInteger) optionsMask parentColor:(LDrawColor *)parentColor
{
	if((optionsMask & DRAW_HIT_TEST_MODE) != 0)
	{
		GLuint hitTag = [LDrawUtilities makeHitTagForObject:self];
		glLoadName( hitTag );
	}
	
	glPushMatrix();
	{
		glTranslatef(self->position.x, self->position.y, self->position.z);
		glScalef(2.0, 2.0, 2.0);
		
		glBindVertexArrayAPPLE(vaoTag);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, vboVertexCount);
		glBindVertexArrayAPPLE(0); // Failing to unbind can cause bizarre crashes if other VAOs are in display lists
	}
	glPopMatrix();
	
}//end draw:parentColor:


#pragma mark -
#pragma mark ACTIONS
#pragma mark -

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
	Point3 newPosition = V3Add(self->position, moveVector);
	
	[self setPosition:newPosition updateTarget:YES];
	
}//end moveBy:


//---------- makeSphereWithLongitudinalCount:latitudinalCount: -------[static]--
//
// Purpose:		Populates the shared tag used to draw drag handle spheres.
//
//------------------------------------------------------------------------------
+ (void) makeSphereWithLongitudinalCount:(int)longitudeSections
						latitudinalCount:(int)latitudeSections
{
	// Bail if we've already done it.
	if(vboTag != 0)
	{
		return;
	}

	float           latitudeRadians     = (M_PI / latitudeSections); // lat. wraps halfway around sphere
	float           longitudeRadians    = (2*M_PI / longitudeSections); // long. wraps all the way
	int             vertexCount         = 0;
	VBOVertexData   *vertexes           = NULL;
	int             latitudeCount       = 0;
	int             longitudeCount      = 0;
	float           latitude            = 0;
	float           longitude           = 0;
	int             counter             = 0;
	GLfloat         sphereColor[4];
	
	// A pleasant lavender color
	sphereColor[0] = 0.50;
	sphereColor[1] = 0.53;
	sphereColor[2] = 1.00;
	sphereColor[3] = 1.00;
	
	//---------- Generate Sphere -----------------------------------------------
	
	// Each latitude strip begins with two vertexes at the prime meridian, then 
	// has two more vertexes per segment thereafter. 
	vertexCount = (2 + longitudeSections*2) * latitudeSections; 
	vertexes    = calloc(vertexCount, sizeof(VBOVertexData));
	
	// Calculate vertexes for each strip of latitude.
	for(latitudeCount = 0; latitudeCount < latitudeSections; latitudeCount += 1 )
	{
		latitude = (latitudeCount * latitudeRadians);
		
		// Include the prime meridian twice; once to start the strip and once to 
		// complete the last triangle of the -1 meridian. 
		for(longitudeCount = 0; longitudeCount <= longitudeSections; longitudeCount += 1 )
		{
			longitude = longitudeCount * longitudeRadians;
		
			VBOVertexData   *top    = vertexes + counter;
			VBOVertexData   *bottom = vertexes + counter + 1;
		
			// Top vertex
			top->position[0]    = cos(longitude)*sin(latitude);
			top->position[1]    = sin(longitude)*sin(latitude);
			top->position[2]    = cos(latitude);
			top->normal[0]      = top->position[0]; // it's a unit sphere; the normal is the same as the vertex.
			top->normal[1]      = top->position[1];
			top->normal[2]      = top->position[2];
			memcpy(top->color, sphereColor, sizeof(sphereColor));
			
			counter++;
			
			// Bottom vertex
			bottom->position[0] = cos(longitude)*sin(latitude + latitudeRadians);
			bottom->position[1] = sin(longitude)*sin(latitude + latitudeRadians);
			bottom->position[2] = cos(latitude + latitudeRadians);
			bottom->normal[0]   = bottom->position[0];
			bottom->normal[1]   = bottom->position[1];
			bottom->normal[2]   = bottom->position[2];
			memcpy(bottom->color, sphereColor, sizeof(sphereColor));
			
			counter++;
		}
	}

	//---------- Optimize ------------------------------------------------------
	
	vboVertexCount = counter;
	
	glGenBuffers(1, &vboTag);
	glBindBuffer(GL_ARRAY_BUFFER, vboTag);
	
	glBufferData(GL_ARRAY_BUFFER, vboVertexCount * sizeof(VBOVertexData), vertexes, GL_STATIC_DRAW);
	free(vertexes);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	
	// Encapsulate in a VAO
	glGenVertexArraysAPPLE(1, &vaoTag);
	glBindVertexArrayAPPLE(vaoTag);
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_NORMAL_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);
	glBindBuffer(GL_ARRAY_BUFFER, vboTag);
	glVertexPointer(3, GL_FLOAT, sizeof(VBOVertexData), NULL);
	glNormalPointer(GL_FLOAT,    sizeof(VBOVertexData), (GLvoid*)(sizeof(float)*3));
	glColorPointer(4, GL_FLOAT,  sizeof(VBOVertexData), (GLvoid*)(sizeof(float)*3 + sizeof(float)*3) );
}


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		Party like it's May 21, 2011!
//
//==============================================================================
- (void) dealloc
{
	[super dealloc];
}


@end
