//==============================================================================
//
// File:		PartBrowserTableView.m
//
// Purpose:		Table-view extensions specific to the tables used in the 
//			    Bricksmith Part Browser. 
//
//  Created by Allen Smith on 6/11/07.
//  Copyright 2007. All rights reserved.
//==============================================================================
#import "PartBrowserTableView.h"

#import "BezierPathCategory.h"

@implementation PartBrowserTableView

//========== dragImageForRows:event:dragImageOffset: ===========================
//
// Purpose:		Return a better image for part drag-and-drop.
//
// Notes:		Unfortunately, we can't just return an image of the part itself, 
//			    since its orientation or size can change depending on what view 
//			    it is dragged into. 
//
//==============================================================================
- (NSImage *)dragImageForRows:(NSArray *)dragRows
						event:(NSEvent *)dragEvent
			  dragImageOffset:(NSPointPointer)dragImageOffset
{
	NSImage *arrowCursorImage	= [[NSCursor arrowCursor] image];
	NSSize	 arrowSize			= [arrowCursorImage size];
	NSImage	*brickImage			= [NSImage imageNamed:@"Brick"];
	float	 border				= 3;
	NSSize	 dragImageSize		= NSMakeSize([brickImage size].width + border*2, [brickImage size].height + border*2);
	NSImage	*dragImage			= [[NSImage alloc] initWithSize:dragImageSize];
	
	// turns out the arrow cursor image is a 24 x 24 picture, and the arrow 
	// itself occupies only a small part of the lefthand side of that space. 
	// Looks like it's very difficult to get the drag image over to the right of 
	// the arrow without hardcoding some values. 
	*dragImageOffset = NSMakePoint(arrowSize.width/2 + [dragImage size].width/2, -arrowSize.height / 2);

	[dragImage lockFocus];
		
		[[NSColor colorWithDeviceWhite:0.6 alpha:0.75] set];
		[[NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, dragImageSize.width,dragImageSize.height) radiusPercentage:50.0] fill];
		
		[brickImage drawAtPoint:NSMakePoint(border, border) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		
	[dragImage unlockFocus];
	
	return [dragImage autorelease];
}//end dragImageForRows:event:dragImageOffset:


//========== keyDown: ==========================================================
//
// Purpose:		Intercept keyboard events so we can translate Return into a 
//			    double-click. 
//
//==============================================================================
- (void)keyDown:(NSEvent *)theEvent
{
	NSString	*characters = [theEvent charactersIgnoringModifiers];
	unichar		 firstChar	= '\0';
	
	if([characters length] > 0)
		firstChar = [characters characterAtIndex:0];
	
	switch(firstChar)
	{
		case NSEnterCharacter:			// Enter key
		case NSCarriageReturnCharacter:	// Return key
		case NSNewlineCharacter:		// ???
			if([self doubleAction] != NULL)
				[[self target] performSelector:[self doubleAction] withObject:self];
			break;
		
		default:
			[super keyDown:theEvent];
	}
		
}//end keyDown:


@end
