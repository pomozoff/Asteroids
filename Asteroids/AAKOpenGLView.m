//
//  AAKOpenGLView.m
//  Asteroids
//
//  Created by Anton Pomozov on 26.06.14.
//  Copyright (c) 2014 Akademon Ltd. All rights reserved.
//

#import "AAKOpenGLView.h"

@interface AAKOpenGLView()

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, assign) GLuint colorRenderBuffer;

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
        [self renderInContext:_context];
    }
    return self;
}
+ (Class)layerClass {
    return [CAEAGLLayer class];
}

#pragma mark - Properties

#pragma mark - Private functions

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

- (void)renderInContext:(EAGLContext *)context {
    glClearColor(3.0/255.0, 9.0/255.0, 38.0/255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    [context presentRenderbuffer:GL_RENDERBUFFER];
}

@end
