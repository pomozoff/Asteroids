//
//  AAKOpenGLView.m
//  Asteroids
//
//  Created by Anton Pomozov on 26.06.14.
//  Copyright (c) 2014 Akademon Ltd. All rights reserved.
//

#import "AAKOpenGLView.h"

static const uint positionValues = 3;
static const uint colorValues = 4;

typedef struct {
    float Position[positionValues];
    float Color[colorValues];
} Vertex;

const Vertex Vertices[] = {
    {{ 1, -1, 0}, {1, 0, 0, 1}},
    {{ 1,  1, 0}, {0, 1, 0, 1}},
    {{-1,  1, 0}, {0, 0, 1, 1}},
    {{-1, -1, 0}, {0, 0, 0, 1}}
};

const GLubyte Indices[] = {
    0, 1, 2,
    2, 3, 0
};

@interface AAKOpenGLView() {
    GLuint _colorRenderBuffer;
    GLuint _positionSlot;
    GLuint _colorSlot;
}

@property (nonatomic, strong) EAGLContext *context;

@end

@implementation AAKOpenGLView

#pragma mark - Lifecycle

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        _context = [self setupContext];
        if (!_context) {
			return nil;
        }
        _colorRenderBuffer = [self setupRenderBufferForContext:_context withLayer:[self setupLayer]];
        [self setupFrameBufferWithColorRenderBuffer:_colorRenderBuffer];
        [self compileShaders];
        [self setupVertexBuffersObjects];
        [self renderInContext:_context];
    }
    return self;
}
+ (Class)layerClass {
    return [CAEAGLLayer class];
}

#pragma mark - Properties

#pragma mark - Private functions

- (void)renderInContext:(EAGLContext *)context {
    glClearColor(3.0/255.0, 9.0/255.0, 38.0/255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    glVertexAttribPointer(_positionSlot, positionValues, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot,    colorValues, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *) (sizeof(float) * positionValues));
    glDrawElements(GL_TRIANGLES, sizeof(Indices) / sizeof(GLubyte), GL_UNSIGNED_BYTE, 0);
    
    [context presentRenderbuffer:GL_RENDERBUFFER];
}

- (CAEAGLLayer *)setupLayer {
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    eaglLayer.opaque = YES;
    return eaglLayer;
}
- (EAGLContext *)setupContext {
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        return nil;
    }
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"Failed to set current OpenGL context");
        return nil;
    }
    return context;
}
- (GLuint)setupRenderBufferForContext:(EAGLContext *)context withLayer:(CAEAGLLayer *)layer {
    GLuint colorRenderBuffer;
    glGenRenderbuffers(1, &colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderBuffer);
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    
    return colorRenderBuffer;
}
- (void)setupFrameBufferWithColorRenderBuffer:(GLuint)colorRenderBuffer {
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderBuffer);
}
- (GLuint)compileShader:(NSString *)shaderPath withType:(GLenum)shaderType {
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath
                                                       encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        return 0;
    }
    
    GLuint shaderHandle = glCreateShader(shaderType);
    const char *shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    glCompileShader(shaderHandle);
    
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        return 0;
    }
    return shaderHandle;
}
- (void)compileShaders {
    GLuint vertexShader = [self compileShader:[[NSBundle mainBundle] pathForResource:@"simple" ofType:@"vsh"]
                                     withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:[[NSBundle mainBundle] pathForResource:@"simple" ofType:@"fsh"]
                                       withType:GL_FRAGMENT_SHADER];

    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        return;
    }
    
    glUseProgram(programHandle);
    
    _positionSlot = glGetAttribLocation(programHandle, "Position");
    _colorSlot = glGetAttribLocation(programHandle, "SourceColor");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
}
- (void)setupVertexBuffersObjects {
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
}

@end
