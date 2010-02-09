//==============================================================================
//
// File:		MatrixMath.h
//
// Purpose:		Mathematical library for computer graphics
//
//				Stolen heavily from GraphicsGems.h  
//				Version 1.0 - Andrew Glassner
//				from "Graphics Gems", Academic Press, 1990
//
//==============================================================================
#ifndef _MatrixMath_
#define _MatrixMath_


#include <OpenGL/GL.h>
#include <stdbool.h>

#pragma mark Data Types
#pragma mark -

////////////////////////////////////////////////////////////////////////////////
//
// 3D geometry types
//
////////////////////////////////////////////////////////////////////////////////

// 3D point
typedef struct Point3Struct
{
	float x, y, z;
	
} Point3, Vector3, Tuple3;


// 3D integer point
typedef struct IntPoint3Struct
{
	int x, y, z;
	
} IntPoint3;


// 3D Box
typedef struct Box3dStruct
{
	Point3 min, max;
	
} Box3;


// 3x3 Matrix
typedef struct Matrix3Struct
{
	float element[3][3]; // [row][column]
	
} Matrix3;


////////////////////////////////////////////////////////////////////////////////
//
// 4D geometry types
//
////////////////////////////////////////////////////////////////////////////////

//4-by-4 matrix
typedef struct Matrix4Struct
{
	float element[4][4]; // [row][column]
	
} Matrix4;


// 4-component vector
typedef struct
{
	float x,y,z,w;
	
} Point4, Vector4, Tuple4;


// Transformation components; the data encoded in a transformation matrix.
typedef struct
{
 	Tuple3	scale;
 	float	shear_XY;
 	float	shear_XZ;
 	float	shear_YZ;
 	Tuple3	rotate;		//in radians
	Vector3	translate;
 	Tuple4	perspective;
	
} TransformComponents;


#pragma mark -
#pragma mark Constants
#pragma mark -
////////////////////////////////////////////////////////////////////////////////
//
// Constants
//
////////////////////////////////////////////////////////////////////////////////

#define PI				M_PI
#define SMALL_NUMBER	1.e-6		//"close enough" zero for floating-point. 1e-8 is too small.

extern const Box3					InvalidBox;
extern const TransformComponents	IdentityComponents;
extern const Matrix3				IdentityMatrix3;
extern const Matrix4				IdentityMatrix4;
extern const Point3					ZeroPoint3;
extern const Point4					ZeroPoint4;

#pragma mark -
#pragma mark Macros
#pragma mark -
////////////////////////////////////////////////////////////////////////////////
//
// Macros
//
////////////////////////////////////////////////////////////////////////////////

// Radians to Degrees
#define degrees(radians) ( (radians) * 180/PI)

// Degrees to Radians
#define radians(degrees) ( (degrees) * PI/180)


/* find minimum of a and b */
// Defined for us by Objective-C
#if !defined(MIN)
#define MIN(a,b)	(((a)<(b))?(a):(b))	
#endif

/* find maximum of a and b */
#if !defined(MAX)
#define MAX(a,b)	(((a)>(b))?(a):(b))	
#endif

/* swap a and b (see Gem by Wyvill) */
#define SWAP(a,b)	{ a^=b; b^=a; a^=b; }

// Linear Interpolation
// from a (when t=0) to b (when t=1)
// (equivalent to a*(1 - t) + b*t
#define LERP(t, a, b)					\
(										\
 (a) + ( ((b) - (a))*(t) )				\
)

/* clamp the input v to the specified range [l-h] */
#define CLAMP(v, l, h)					\
(										\
	(v) < (l) ?							\
		(l)								\
	: (v) > (h) ?						\
		(h)								\
	: v									\
)


////////////////////////////////////////////////////////////////////////////////
//
// memory allocation macros
//
////////////////////////////////////////////////////////////////////////////////

/* create a new instance of a structure (see Gem by Hultquist) */
#define NEWSTRUCT(x)	(struct x *)(malloc((unsigned)sizeof(struct x)))

/* create a new instance of a type */
#define NEWTYPE(x)	(x *)(malloc((unsigned)sizeof(x)))


#pragma mark -
#pragma mark Prototypes
#pragma mark -
////////////////////////////////////////////////////////////////////////////////
//
// Function Prototypes
//
////////////////////////////////////////////////////////////////////////////////

extern bool		FloatsApproximatelyEqual(float float1, float float2);

// 2-D
extern float	Matrix2x2Determinant( float, float, float, float);

// 3-D
extern Vector3	V3Make(float x, float y, float z);
extern Vector3*	V3Duplicate(Vector3 *a);
extern Vector3	V3FromV4(Vector4 originalVector);
extern bool		V3EqualPoints(Point3 point1, Point3 point2);
extern bool		V3PointsWithinTolerance(Point3 point1, Point3 point2);
extern float	V3SquaredLength(Vector3 v);
extern float	V3Length(Vector3 v);
extern Vector3	V3Negate(Vector3 v);
extern Vector3	V3Normalize(Vector3 v);
extern Vector3	V3Scale(Vector3 v, float);
extern Vector3	V3Add(Vector3 a, Vector3 b);
extern Vector3	V3Sub(Vector3 a, Vector3 b);
extern float	V3Dot(Vector3 a, Vector3 b);
extern Vector3	V3Lerp(Vector3 lo, Vector3 hi, float alpha);
extern Vector3	V3Combine(Vector3 a, Vector3 b, float ascl, float bscl);
extern Vector3	V3Mul(Vector3 a, Vector3 b);
extern float	V3DistanceBetween2Points(Point3 a, Point3 b);
extern Vector3	V3Cross(Vector3 a, Vector3 b);
extern Point3	V3Midpoint(Point3 point1, Point3 point2);
extern Vector3	V3IsolateGreatestComponent(Vector3 vector);
extern void		V3Print(Point3 point);

extern Box3		V3BoundsFromPoints(Point3 point1, Point3 point2);
extern Point3	V3CenterOfBox(Box3 box);
extern int		V3EqualBoxes(Box3 box1, Box3 box2);
extern Box3		V3UnionBox(Box3 aBox, Box3 bBox);
extern Box3		V3UnionBoxAndPoint(Box3 box, Point3 point);

extern Point3	V3MulPointByMatrix(Point3 pin, Matrix3 m);
extern Vector3	V3MulPointByProjMatrix(Point3 pin, Matrix4 m);
extern float	Matrix3x3Determinant( float, float, float, float, float, float, float, float, float );
extern Matrix3	Matrix3MakeNormalTransformFromProjMatrix(Matrix4 transformationMatrix);

// 4-D
extern Vector4	V4Make(float x, float y, float z, float w);
extern Vector4	V4FromPoint3(Vector3 originalVector);
extern Vector4	V4MulPointByMatrix(Vector4 pin, Matrix4 m);
extern Matrix4	Matrix4CreateFromGLMatrix4(const GLfloat *glMatrix);
extern Matrix4	Matrix4CreateTransformation(TransformComponents *);
extern int		Matrix4DecomposeTransformation( Matrix4 originalMatrix, TransformComponents *decomposed);
extern Tuple3	Matrix4DecomposeXYZRotation(Matrix4 matrix);
extern Tuple3	Matrix4DecomposeZYXRotation(Matrix4 matrix);
extern Matrix4*	Matrix4Multiply(Matrix4 *a, Matrix4 *b, Matrix4 *result);
extern void		Matrix4MultiplyGLMatrices(GLfloat *a, GLfloat *b, GLfloat *result);
extern void		Matrix4GetGLMatrix4(Matrix4 matrix, GLfloat *glTransformation);
extern Matrix4	Matrix4Rotate(Matrix4 original, Tuple3 degreesToRotate);
extern Matrix4	Matrix4Translate(Matrix4 original, Vector3 displacement);
extern Matrix4	Matrix4Transpose(Matrix4 a);
extern Matrix4	Matrix4Invert(Matrix4 in);
extern void		Matrix4Adjoint( Matrix4 *, Matrix4 * );
extern float	Matrix4x4Determinant( Matrix4 * );
extern void		Matrix4Print(Matrix4 *matrix);


#endif // _MatrixMath_
