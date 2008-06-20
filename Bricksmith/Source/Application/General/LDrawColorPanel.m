//==============================================================================
//
// File:		LDrawColorPanel.m
//
// Purpose:		Color-picker for Bricksmith. The color panel is used to browse, 
//				select, and apply LDraw colors. The colors are presented by 
//				both swatch and name.
//
//  Created by Allen Smith on 2/26/05.
//  Copyright 2005. All rights reserved.
//==============================================================================
#import "LDrawColorPanel.h"

#import "ColorLibrary.h"
#import "LDrawColor.h"
#import "LDrawColorBar.h"
#import "LDrawColorCell.h"
#import "LDrawColorWell.h"
#import "MacLDraw.h"
#import "StringCategory.h"

@implementation LDrawColorPanel

//There is supposed to be only one of these.
LDrawColorPanel *sharedColorPanel = nil;


//========== awakeFromNib ======================================================
//
// Purpose:		Brings the LDraw color panel to life.
//
// Note:		Please note that this method is called BEFORE most class
//				initialization code. For instance, awake is called before the 
//				table's data is even loaded, so you can't sort the data here.
//
//==============================================================================
- (void) awakeFromNib
{
	LDrawColorCell	*colorCell		= [[[LDrawColorCell alloc] init] autorelease];
	NSTableColumn	*colorColumn	= [colorTable tableColumnWithIdentifier:@"colorCode"];
	
	[colorColumn setDataCell:colorCell];
	
	//Remember, this method is called twice for an LDrawColorPanel; the first time 
	// is for the File's Owner, which is promptly overwritten.
	
}//end awakeFromNib


#pragma mark -
#pragma mark INITIALIZATION
#pragma mark -

//---------- sharedColorPanel ----------------------------------------[static]--
//
// Purpose:		Returns the global instance of the color panel.
//
//------------------------------------------------------------------------------
+ (LDrawColorPanel *) sharedColorPanel
{
	if(sharedColorPanel == nil)
		sharedColorPanel = [[LDrawColorPanel alloc] init];
	
	return sharedColorPanel;
	
}//end sharedColorPanel


//========== init ==============================================================
//
// Purpose:		Brings the LDraw color panel to life.
//
//==============================================================================
- (id) init
{
	id		 oldself	= [super init];
	NSArray	*colorList	= [[ColorLibrary sharedColorLibrary] colors];

	[NSBundle loadNibNamed:@"ColorPanel" owner:self];
	
	self = colorPanel; //this don't look good, but it works.
						//this takes the place of calling [super init]
						// Note that connections in the Nib file must be made 
						// to the colorPanel, not to the File's Owner!
						
	//While the data is being loaded in the table, a color will automatically 
	// be selected. We do not want this color-selection to generate a 
	// changeColor: message, so we turn on this flag.
	updatingToReflectFile = YES;
	
		//Obtain the list of colors to display.
		self->colorListController	= [[NSArrayController alloc] initWithContent:colorList];
		
		//Owing to the very messy way I set up this Nib, I must force a resort here.
		// see awakeFromNib for details.
		[self tableView:colorTable sortDescriptorsDidChange:[colorTable sortDescriptors]];
		[colorTable reloadData];
		
		[self setLDrawColor:LDrawRed];
	updatingToReflectFile = NO;
	
	[self setDelegate:self];
	[self setWorksWhenModal:YES];
	[self setLevel:NSStatusWindowLevel];
	[self setBecomesKeyOnlyIfNeeded:YES];
	
	[oldself release];
	
	return self;
	
}//end init


#pragma mark -
#pragma mark ACCESSORS
#pragma mark -

//========== LDrawColor ========================================================
//
// Purpose:		Returns the color code of the panel's currently-selected color.
//
//==============================================================================
- (LDrawColorT) LDrawColor
{
	int			selectedRow			= [colorTable selectedRow];
	LDrawColor	*selectedColor		= nil;
	LDrawColorT	selectedColorCode	= LDrawColorBogus;
	
	//It is possible there are no rows selected, if a search has limited the 
	// color list out of existence.
	if(selectedRow >= 0)
	{
		selectedColor		= [[self->colorListController arrangedObjects] objectAtIndex:selectedRow];
		selectedColorCode	= [selectedColor colorCode];
	}
	//Just return whatever was last selected.
	else
		selectedColorCode = [colorBar LDrawColor];
	
	return selectedColorCode;
	
}//end LDrawColor


//========== setLDrawColor: ====================================================
//
// Purpose:		Chooses newColor in the color table. As long as newColor is a 
//				valid color, this method will select it, even if it has to 
//				change the found set.
//
//==============================================================================
- (void) setLDrawColor:(LDrawColorT)newColor
{
	//Try to find the color we are after in the current list.
	int rowToSelect = [self indexOfColorCode:newColor]; //will be the row index for the color we want.
	
	if(rowToSelect == NSNotFound)
	{
		//It wasn't in the currently-displayed list. Search the master list.
		[self->colorListController setFilterPredicate:nil];
		rowToSelect = [self indexOfColorCode:newColor];
	}
	
	//We'd better have found it by now!
	if(rowToSelect != NSNotFound)
	{
		[colorTable selectRow:rowToSelect byExtendingSelection:NO];
		[colorBar setLDrawColor:newColor];
	}
	
}//end setLDrawColor:

#pragma mark -
#pragma mark ACTIONS
#pragma mark -

//========== orderOut: =========================================================
//
// Purpose:		The color panel is being closed. If there is an active color 
//				well, it needs to deactivate.
//
//==============================================================================
- (void) orderOut:(id)sender
{
	//deactivate active color well.
	if([LDrawColorWell activeColorWell] != nil)
		[LDrawColorWell setActiveColorWell:nil];
	
	[super orderOut:sender];
	
}//end orderOut:


//========== sendAction ========================================================
//
// Purpose:		Dispatches the change-color action as appropriate. If there is 
//				an active color well, it will be the sole recipient of the color 
//				change. Otherwise, a nil-targeted -changeLDrawColor: message 
//				will be dispatched.
//
//==============================================================================
- (void) sendAction
{
	LDrawColorWell *activeColorWell = [LDrawColorWell activeColorWell];

	if(activeColorWell != nil)
	{
		//we have an active color well, so it is the only one whose color should 
		// change.
		[activeColorWell changeLDrawColorWell:self];
	}
	else
	{
		//Well, our color has changed. Presumably, somebody wants to update a 
		// part color in response to this momentous event. But who knows who? So 
		// we just send this message toddling along, and let whoever want it get 
		// it.
		//
		//But--if this notification is coming in response to selecting a 
		// different part in the file, then our color did not *really* change; 
		// we are just displaying a new one. In that case, we don't want any 
		// parts changing colors.
		if(updatingToReflectFile == NO)
		{
			[NSApp sendAction:@selector(changeLDrawColor:)
						   to:nil //just send it somewhere!
						 from:self]; //it's from us (we'll be the sender)
			
		}
		
		//Clients that are tracking the global color state always need to know 
		// about the current color, though!
		[[NSNotificationCenter defaultCenter]
							postNotificationName:LDrawColorDidChangeNotification
										  object:[NSNumber numberWithInt:[self LDrawColor]] ];
	}

}//end sendAction


//========== searchFieldChanged: ===============================================
//
// Purpose:		The user has changed the search string. We need to research 
//				the list of colors for those whose names match the new string.
//
// Notes:		For the sake of concise code, I do not bother to optimize this 
//				search. After all, we only have 64 colors; that's no time.
//
//==============================================================================
- (IBAction) searchFieldChanged:(id)sender
{
	NSString		*searchString				= [sender stringValue];
	NSPredicate		*searchPredicate			= nil;
	LDrawColorT		 currentColor				= [self LDrawColor];
	int				 indexOfPreviousSelection	= 0;
	
	searchPredicate = [self predicateForSearchString:searchString];
	
	//Update the table with our results.
	[self->colorListController setFilterPredicate:searchPredicate];
	[self->colorTable reloadData];
	
	//Restore the selection
	indexOfPreviousSelection = [self indexOfColorCode:currentColor];
	if(indexOfPreviousSelection != NSNotFound)
	{
		[colorTable selectRowIndexes: [NSIndexSet indexSetWithIndex:indexOfPreviousSelection]
				byExtendingSelection: NO];
	}
	// The previous color is no longer in the list. This is a major dilemma.
	// I have chosen to automatically select the first color, since I don't want 
	// to introduce the UI confusion of empty selection.
	else
	{
		[colorTable selectRowIndexes: [NSIndexSet indexSetWithIndex:0]
				byExtendingSelection: NO];
	}
	
}//end searchFieldChanged:


//========== updateSelectionWithObjects: =======================================
//
// Purpose:		Updates the selected color based on the colors in 
//				selectedObjects, which should be a list of LDrawDirectives 
//				which have been selected in a document window.
//
//				If two or more directives have different colors, then the color 
//				of the last object selected is displayed.
//
//				If there are no colorable directives in selectedObjects, then 
//				the color selection remains unchanged.
//
//==============================================================================
- (void) updateSelectionWithObjects:(NSArray *)selectedObjects
{
	id			currentObject	= [selectedObjects lastObject];
	LDrawColorT	objectColor		= [self LDrawColor];
	
	//Find the color code of the last object selected. I suppose this is rather 
	// tacky to do such a simple search, but I would prefer not to write the 
	// interface required to denote multiple selection.
	if(currentObject != nil)
	{
		if([currentObject conformsToProtocol:@protocol(LDrawColorable)])
			objectColor = [currentObject LDrawColor];
	}
	
	updatingToReflectFile = YES;
		[self setLDrawColor:objectColor];
	updatingToReflectFile = NO;
	
}//end updateSelectionWithObjects:


#pragma mark -
#pragma mark UTILITIES
#pragma mark -

//========== predicateForSearchString: =========================================
//
// Purpose:		Returns a search predicate suitable for finding colors based on 
//				the given search string. 
//
//				If the search string consists entirely of numerals, the 
//				predicate will search for colors having that exact integer code. 
//
//==============================================================================
- (NSPredicate *) predicateForSearchString:(NSString *)searchString
{
	NSPredicate		*searchPredicate		= nil;
	BOOL			 searchByCode			= NO; //color name search by default.
	NSScanner		*digitScanner			= nil;
	int				 colorCode				= nil;
	
	// If there is no string, then clear the search predicate (find all).
	if([searchString length] == 0)
		searchPredicate = nil;
	else
	{
		// Find out whether this search is intended to be based on the LDraw 
		// code. If the search string can be parsed into an integer, we'll 
		// assume this is a color-code search. Otherwise, it will be a name 
		// search. 
		digitScanner	= [NSScanner scannerWithString:searchString];
		searchByCode	= [digitScanner scanInt:&colorCode];
		
		// If it is an LDraw code search, try to find a color code equal to the 
		// search number entered. 
		if(searchByCode == YES)
		{
			searchPredicate = [NSPredicate predicateWithFormat:@"%K == %d", @"colorCode", colorCode];
		}
		else
		{
			// This is a search based on color names. If we can find the search 
			// string in any component of the color string, we consider it a 
			// match. 
			searchPredicate = [NSPredicate predicateWithFormat:@"%K CONTAINS[cd] %@", @"localizedName", searchString];
		}
	}
	
	return searchPredicate;
	
}//end predicateForSearchString:


//========== indexOfColorCode: =================================================
//
// Purpose:		Returns the row index of colorCodeSought in the panel's table, 
//				or NSNotFound if colorCodeSought is not displayed. 
//
//==============================================================================
- (int) indexOfColorCode:(LDrawColorT)colorCodeSought
{
	NSArray			*visibleColors	= [self->colorListController arrangedObjects];
	int				 numberColors	= [visibleColors count];
	LDrawColor		*currentColor	= nil;
	LDrawColorT		 currentCode	= LDrawColorBogus;
	int				 rowToSelect	= NSNotFound; //will be the row index for the color we want.
	int				 counter		= 0;
	
	//Search through all the colors in the current color set and see if the 
	// one we are after is in there. A brute force search.
	for(counter = 0; counter < numberColors && rowToSelect == NSNotFound; counter++)
	{
		currentColor	= [visibleColors objectAtIndex:counter];
		currentCode		= [currentColor colorCode];
		
		if(currentCode == colorCodeSought)
			rowToSelect = counter;
	}
	
	return rowToSelect;
	
}//end indexOfColorCode:


#pragma mark -
#pragma mark DATA SOURCES
#pragma mark -
#pragma mark Table

//**** NSTableDataSource ****
//========== numberOfRowsInTableView: ==========================================
//
// Purpose:		Should return the number of parts in the category currently 
//				being browsed.
//
//==============================================================================
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [[self->colorListController arrangedObjects] count];
	
}//end numberOfRowsInTableView:


//**** NSTableDataSource ****
//========== tableView:objectValueForTableColumn:row: ===============================
//
// Purpose:		Displays information for the part in the record.
//
//==============================================================================
- (id)				tableView:(NSTableView *)tableView
	objectValueForTableColumn:(NSTableColumn *)tableColumn
						  row:(int)rowIndex
{
	if(rowIndex == -1 )
		NSLog(@"AAAAAA!");

	LDrawColor		*colorObject		= [[self->colorListController arrangedObjects] objectAtIndex:rowIndex];
	NSString		*columnIdentifier	= [tableColumn identifier];
	
	id				 cellValue			= [colorObject valueForKey:columnIdentifier];
	
	return cellValue;
	
}//end tableView:objectValueForTableColumn:row:


//**** NSTableDataSource ****
//========== tableView:sortDescriptorsDidChange: ===============================
//
// Purpose:		Resort the table elements.
//
//==============================================================================
- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
	NSArray *newDescriptors = [tableView sortDescriptors];
	
	[self->colorListController setSortDescriptors:newDescriptors];
	[tableView reloadData];
	
}//end tableView:sortDescriptorsDidChange:


#pragma mark -
#pragma mark DELEGATES
#pragma mark -

//**** NSTableView ****
//========== tableViewSelectionDidChange: ======================================
//
// Purpose:		Need to update everything to indicate that a new color was 
//				selected.
//
//==============================================================================
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	//Update internal information.
	[self->colorBar setLDrawColor:[self LDrawColor]];
	
	[self sendAction];
	
}//end tableViewSelectionDidChange:


//**** NSWindow ****
//========== windowWillReturnUndoManager: ======================================
//
// Purpose:		Allows Undo to keep working transparently through this window by 
//				allowing the undo request to forward on to the active document.
//
//==============================================================================
- (NSUndoManager *) windowWillReturnUndoManager:(NSWindow *)sender
{
	NSDocument *currentDocument = [[NSDocumentController sharedDocumentController] currentDocument];
	
	return [currentDocument undoManager];
	
}//end windowWillReturnUndoManager:


#pragma mark -
#pragma mark DESTRUCTOR
#pragma mark -

//========== dealloc ===========================================================
//
// Purpose:		The Roll has been called up Yonder, and we will be there.
//
//==============================================================================
- (void) dealloc
{
	[colorListController	release];
	
	[super dealloc];
	
}//end dealloc


@end
