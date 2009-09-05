//==============================================================================
//
// File:		LDrawDocument.h
//
// Purpose:		Document controller for an LDraw document.
//
//				Opens the document and manages its editor and viewer.
//
//  Created by Allen Smith on 2/14/05.
//  Copyright (c) 2005. All rights reserved.
//==============================================================================
#import <Cocoa/Cocoa.h>

#import "ColorLibrary.h"
#import "LDrawUtilities.h"
#import "MatrixMath.h"
#import "RotationPanel.h"

@class DocumentToolbarController;
@class ExtendedSplitView;
@class LDrawContainer;
@class LDrawDirective;
@class LDrawDrawableElement;
@class LDrawFile;
@class LDrawFileOutlineView;
@class LDrawGLView;
@class LDrawModel;
@class LDrawMPDModel;
@class LDrawStep;
@class LDrawPart;
@class PartBrowserDataSource;

//Where new parts are inserted in the abscence of a peer selection.
typedef enum insertionMode {
	insertAtEnd,
	insertAtBeginning
} insertionModeT;


////////////////////////////////////////////////////////////////////////////////
//
// class LDrawDocument
//
////////////////////////////////////////////////////////////////////////////////
@interface LDrawDocument : NSDocument
{
	IBOutlet DocumentToolbarController	*toolbarController;
	IBOutlet NSObjectController			*bindingsController;
	
	// Window satellites
	IBOutlet NSDrawer					*partBrowserDrawer;
	IBOutlet PartBrowserDataSource		*partsBrowser;
	
	// Scope bar
	IBOutlet NSButton					*viewAllButton;
	IBOutlet NSButton					*viewStepsButton;
	IBOutlet NSPopUpButton				*submodelPopUpMenu;
	IBOutlet NSView						*scopeStepControlsContainer;
	IBOutlet NSTextField				*stepField;
	IBOutlet NSSegmentedControl			*stepNavigator;
	
	// Window contents
	IBOutlet ExtendedSplitView			*fileContentsSplitView;
	IBOutlet LDrawFileOutlineView		*fileContentsOutline;
	
	// LDraw graphic view
	IBOutlet ExtendedSplitView			*horizontalSplitView;
	IBOutlet ExtendedSplitView			*verticalDetailSplitView;
	IBOutlet LDrawGLView				*fileGraphicView;
	IBOutlet LDrawGLView				*fileDetailView1;
	IBOutlet LDrawGLView				*fileDetailView2;
	IBOutlet LDrawGLView				*fileDetailView3;
	
	@private
		LDrawFile		*documentContents;
		LDrawPart		*lastSelectedPart; //the part in the file which was most recently selected in the contents. (retained)
		NSArray			*selectedDirectives; //mirrors the selection of the file contents outline.
		insertionModeT	 insertionMode;
		gridSpacingModeT gridMode;
		LDrawGLView		*mostRecentLDrawView; //file graphic view which most recently had focus. Weak link.
}

//Accessors
- (LDrawFile *) documentContents;
- (NSWindow *)foremostWindow;
- (gridSpacingModeT) gridSpacingMode;
- (NSDrawer *) partBrowserDrawer;
- (Tuple3) viewingAngle;

- (void) setActiveModel:(LDrawMPDModel *)newActiveModel;
- (void) setCurrentStep:(NSInteger)requestedStep;
- (void) setDocumentContents:(LDrawFile *)newContents;
- (void) setGridSpacingMode:(gridSpacingModeT)newMode;
- (void) setLastSelectedPart:(LDrawPart *)newPart;
- (void) setStepDisplay:(BOOL)showStepsFlag;

//Activities
- (void) moveSelectionBy:(Vector3) movementVector;
- (void) nudgeSelectionBy:(Vector3) nudgeVector;
- (void) rotateSelectionAround:(Vector3)rotationAxis;
- (void) rotateSelection:(Tuple3)rotation mode:(RotationModeT)mode fixedCenter:(Point3 *)fixedCenter;
- (void) selectDirective:(LDrawDirective *)directiveToSelect byExtendingSelection:(BOOL)shouldExtend;
- (void) setSelectionToHidden:(BOOL)hideFlag;
- (void) setZoomPercentage:(CGFloat)newPercentage;

//Actions
- (void) changeLDrawColor:(id)sender;
- (void) insertLDrawPart:(id)sender;
- (void) panelMoveParts:(id)sender;
- (void) panelRotateParts:(id)sender;

// - miscellaneous
- (void) doMissingModelnameExtensionCheck:(id)sender;
- (void) doMissingPiecesCheck:(id)sender;
- (void) doMovedPiecesCheck:(id)sender;

// - Scope bar
- (IBAction) viewAll:(id)sender;
- (IBAction) viewSteps:(id)sender;
- (IBAction) stepFieldChanged:(id)sender;
- (IBAction) stepNavigatorClicked:(id)sender;

// - File menu
- (IBAction) exportSteps:(id)sender;

// - Edit menu
- (IBAction) copy:(id)sender;
- (IBAction) paste:(id)sender;
- (IBAction) delete:(id)sender;
- (IBAction) duplicate:(id)sender;
- (IBAction) orderFrontRotationPanel:(id)sender;
- (IBAction) quickRotateClicked:(id)sender;

// - Tools menu
- (IBAction) showInspector:(id)sender;
- (IBAction) toggleFileContentsDrawer:(id)sender;
- (IBAction) gridGranularityMenuChanged:(id)sender;
- (IBAction) showDimensions:(id)sender;
- (IBAction) showPieceCount:(id)sender;

// - View menu
- (IBAction) zoomActual:(id)sender;
- (IBAction) zoomIn:(id)sender;
- (IBAction) zoomOut:(id)sender;
- (IBAction) toggleStepDisplay:(id)sender;
- (IBAction) advanceOneStep:(id)sender;
- (IBAction) backOneStep:(id)sender;

// - Piece menu
- (IBAction) showParts:(id)sender;
- (IBAction) hideParts:(id)sender;
- (void) snapSelectionToGrid:(id)sender;

// - Models menu
- (IBAction) addModelClicked:(id)sender;
- (IBAction) addStepClicked:(id)sender;
- (IBAction) addPartClicked:(id)sender;
- (void) addSubmodelReferenceClicked:(id)sender;
- (IBAction) addLineClicked:(id)sender;
- (IBAction) addTriangleClicked:(id)sender;
- (IBAction) addQuadrilateralClicked:(id)sender;
- (IBAction) addConditionalClicked:(id)sender;
- (IBAction) addCommentClicked:(id)sender;
- (IBAction) addRawCommandClicked:(id)sender;
- (void) modelSelected:(id)sender;

//Undoable Activities
- (void) addDirective:(LDrawDirective *)newDirective toParent:(LDrawContainer * )parent;
- (void) addDirective:(LDrawDirective *)newDirective toParent:(LDrawContainer * )parent atIndex:(NSInteger)index;
- (void) deleteDirective:(LDrawDirective *)doomedDirective;
- (void) moveDirective:(LDrawDrawableElement *)object inDirection:(Vector3)moveVector;
- (void) rotatePart:(LDrawPart *)part byDegrees:(Tuple3)rotationDegrees aroundPoint:(Point3)rotationCenter;
- (void) setElement:(LDrawDrawableElement *)element toHidden:(BOOL)hideFlag;
- (void) setObject:(LDrawDirective <LDrawColorable>*)object toColor:(LDrawColorT)newColor;
- (void) setTransformation:(TransformComponents)newComponents forPart:(LDrawPart *)part;

//Notifications
- (void)partChanged:(NSNotification *)notification;
- (void)syntaxColorChanged:(NSNotification *)notification;

//Menus
- (void) addModelsToMenus;
- (void) clearModelMenus;

//Utilites
- (void) addModel:(LDrawMPDModel *)newModel preventNameCollisions:(BOOL)flag;
- (void) addStep:(LDrawStep *)newStep;
- (void) addPartNamed:(NSString *)partName;
- (void) addStepComponent:(LDrawDirective *)newDirective;

- (BOOL) canDeleteDirective:(LDrawDirective *)directive displayErrors:(BOOL)errorFlag;
- (void) connectLDrawGLView:(LDrawGLView *)glView;
- (BOOL) elementsAreSelectedOfVisibility:(BOOL)visibleFlag;
- (NSAttributedString *) formatDirective:(LDrawDirective *)item withStringRepresentation:(NSString *)representation;
- (void) loadDataIntoDocumentUI;
- (NSArray *) selectedObjects;
- (LDrawMPDModel *) selectedModel;
- (LDrawStep *) selectedStep;
- (LDrawDirective *) selectedStepComponent;
- (LDrawPart *) selectedPart;
- (void) updateInspector;
- (void) updateViewingAngleToMatchStep;
- (void) writeDirectives:(NSArray *)directives toPasteboard:(NSPasteboard *)pasteboard;
- (NSArray *) pasteFromPasteboard:(NSPasteboard *) pasteboard preventNameCollisions:(BOOL)renameModels;

@end
