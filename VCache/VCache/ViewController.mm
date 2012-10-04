//
//  ViewController.m
//  VCache
//
//  Created by Pavlo Gryb on 10/4/12.
//  Copyright (c) 2012 Pavlo Gryb. All rights reserved.
//

#import "ViewController.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};

	// positionX, positionY, positionZ,     normalX, normalY, normalZ,
#define TRIANGLE() 0.5f, -0.5f, -0.5f,        1.0f, 0.0f, 0.0f,  	0.5f, 0.5f, -0.5f,         1.0f, 0.0f, 0.0f,    	0.5f, -0.5f, 0.5f,         1.0f, 0.0f, 0.0f

GLfloat gTestVertexData[] =
{
	TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),
	TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),
	TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),
	TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),
	TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),
	TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),
	TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),
	TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),TRIANGLE(),
};


GLshort gIndicies32_pattern[]=
{
	0,1,2, 3,4,5, 6,7,8, 9,10,11, 12,13,14, 15,16,17, 18,19,20, 11,22,23, 24,25,26, 27,28,29, 30,31,32, 33,34,35, 36,37,38, 39,40,41, 42,43,44, 45,46,47,
	48,49,50, 51,52,53, 54,55,56, 57,58,59, 60,61,62, 63,64,65, 66,67,68, 69,70,71, 72,73,74, 75,76,77, 78,79,80, 81,82,83, 84,85,86, 87,88,89, 90,91,92, 93,94,95,
};

GLshort gIndicies16_pattern[]=
{
	0,1,2, 3,4,5, 6,7,8, 9,10,11, 12,13,14, 15,16,17, 18,19,20, 11,22,23, 24,25,26, 27,28,29, 30,31,32, 33,34,35, 36,37,38, 39,40,41, 42,43,44, 45,46,47,
};

GLshort gIndicies8_pattern[]=
{
	0,1,2, 3,4,5, 6,7,8, 9,10,11, 12,13,14, 15,16,17, 18,19,20, 11,22,23,
};

GLshort gIndicies4_pattern[]=
{
	0,1,2, 3,4,5, 6,7,8, 9,10,11,
};

GLshort gIndicies2_pattern[]=
{
	0,1,2, 3,4,5,
};

//GLshort* pattern = gIndicies16_pattern;
//int patternSize = sizeof(gIndicies16_pattern);
GLshort* pattern = gIndicies2_pattern;
int patternSize = sizeof(gIndicies2_pattern);

//GLshort* pattern = gIndicies32_pattern;
//int patternSize = sizeof(gIndicies32_pattern);

static int triangleCount=(((65000/3)/32)*32);

@interface ViewController () {
    GLuint _program;
    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    float _rotation;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
		GLuint _indexBuffer;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation ViewController

- (void)dealloc
{
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    [_context release];
    [_effect release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2] autorelease];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGL];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }

    // Dispose of any resources that can be recreated.
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    [self loadShaders];
    
    self.effect = [[[GLKBaseEffect alloc] init] autorelease];
    self.effect.light0.enabled = GL_TRUE;
    self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);
    
    glEnable(GL_DEPTH_TEST);
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(gTestVertexData), gTestVertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
		
    glBindVertexArrayOES(0);
		//
		// ib
		// 
		GLshort* indicies = new GLshort[triangleCount*3];
	int numPatterns = triangleCount*3*2/patternSize;
		for(int n=0;n<numPatterns;n++)
		{
			memcpy(&indicies[n*patternSize/sizeof(GLshort)],&pattern[0],patternSize/sizeof(GLshort));
		}
		//
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, triangleCount*3*sizeof(GLshort), indicies, GL_STATIC_DRAW);
		delete [] indicies;
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);

    glDeleteBuffers(1, &_indexBuffer);
    
    self.effect = nil;
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{

    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -10.0f);
    baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, _rotation, 0.0f, 1.0f, 0.0f);
    
    // Compute the model view matrix for the object rendered with GLKit
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -1.5f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
  
    self.effect.transform.modelviewMatrix = modelViewMatrix;
    
    // Compute the model view matrix for the object rendered with ES2
    modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 1.5f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
	_rotation = 3.14f;//self.timeSinceLastUpdate * 0.5f;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindVertexArrayOES(_vertexArray);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    
    // Render the object with GLKit
    //[self.effect prepareToDraw];
		//glDrawElements(GL_TRIANGLES, triangleCount, GL_UNSIGNED_SHORT,0);
    
    // Render the object again with ES2
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
  
	for(int y=0;y<10;y++)
	{
		glDrawElements(GL_TRIANGLES, triangleCount*3, GL_UNSIGNED_SHORT,0);
	}
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIB_NORMAL, "normal");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

@end
