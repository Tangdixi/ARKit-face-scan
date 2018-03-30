//
//  ViewController.m
//  FaceScan
//
//  Created by 汤迪希 on 29/03/2018.
//  Copyright © 2018 DC. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <ARSCNViewDelegate, ARSessionDelegate>

@property (nonatomic, strong) ARSCNView *sceneView;
@property (nonatomic, strong) SCNNode *sceneNode;
@property (nonatomic, strong) SCNNode *faceNode;

@property (nonatomic, strong) dispatch_queue_t faceTrackingQueue;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setupViews];
    [self setupSession];
}

- (void)setupViews {
    
    [self.view addSubview:self.sceneView];
}

- (void)setupSession {
    
    ARFaceTrackingConfiguration *configuration = [[ARFaceTrackingConfiguration alloc] init];
    configuration.lightEstimationEnabled = YES;
    
    [self.sceneView.session runWithConfiguration:configuration
                                         options:ARSessionRunOptionResetTracking |ARSessionRunOptionRemoveExistingAnchors];
}

- (void)updateFaceNode {
    [self.sceneNode.childNodes makeObjectsPerformSelector:@selector(removeFromParentNode)];
    
    [self.sceneNode addChildNode:self.faceNode];
}

#pragma mark - ARSCNViewDelegate

- (void)renderer:(id<SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
    
    self.sceneNode = node;
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.faceTrackingQueue, ^{
        [weakSelf updateFaceNode];
    });
}

- (void)renderer:(id<SCNSceneRenderer>)renderer didUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
    ARFaceAnchor *faceAnchor = (ARFaceAnchor *)anchor;
    ARSCNFaceGeometry *faceGeometry = (ARSCNFaceGeometry *)self.faceNode.geometry;
    
    [faceGeometry updateFromFaceGeometry:faceAnchor.geometry];
}

#pragma mark - ARSessionDelegate

- (void)session:(ARSession *)session didUpdateFrame:(ARFrame *)frame {
    
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:frame.capturedImage];
    
    CGAffineTransform translate = CGAffineTransformMakeTranslation(ciImage.extent.size.height, 0);
    CGAffineTransform scale = CGAffineTransformMakeScale(0.821, 1);
    CGAffineTransform rotate = CGAffineTransformMakeRotation(M_PI/2);
    
    CGAffineTransform transform = CGAffineTransformConcat(rotate, translate);
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;

    CGAffineTransform translation2 = [frame displayTransformForOrientation:orientation viewportSize:self.view.bounds.size];
    
    CIImage *rotateImage = [ciImage imageByApplyingTransform:translation2];
    CGAffineTransform translate2 = CGAffineTransformMakeTranslation(rotateImage.extent.size.width, 0);
    
    CIImage *finalImage = [rotateImage imageByApplyingTransform:translate];
    
    CIFilter *filter = [CIFilter filterWithName:@"CIColorInvert"];
    [filter setValue:nil
              forKey:kCIInputImageKey];
    
    CIContext *context = [[CIContext alloc] init];
    
    CGImageRef cgImage = [context createCGImage:filter.outputImage
                                       fromRect:CGRectMake(0, 0, rotateImage.extent.size.width, rotateImage.extent.size.height)];
    
    
//    self.sceneView.scene.background.contents = (__bridge id)cgImage;
    
//    CGImageRelease(cgImage);
}

#pragma mark - Lazy Loading

- (ARSCNView *)sceneView {
    if (! _sceneView) {
        _sceneView = [[ARSCNView alloc] initWithFrame:self.view.bounds options:nil];
        _sceneView.showsStatistics = YES;
        _sceneView.delegate = self;
        _sceneView.session.delegate = self;
    }
    return _sceneView;
}

- (SCNNode *)faceNode {
    if (! _faceNode) {
        ARSCNFaceGeometry *faceGeometry = [ARSCNFaceGeometry faceGeometryWithDevice:self.sceneView.device];
        faceGeometry.firstMaterial.diffuse.contents = UIColor.clearColor;
        faceGeometry.firstMaterial.lightingModelName = SCNLightingModelPhysicallyBased;
        
        _faceNode = [[SCNNode alloc] init];
        _faceNode.geometry = faceGeometry;
    }
    return _faceNode;
}

- (dispatch_queue_t)faceTrackingQueue {
    if (_faceTrackingQueue == NULL) {
        _faceTrackingQueue = dispatch_queue_create("com.sceneKit.faceTracking.whee", DISPATCH_QUEUE_CONCURRENT);
    }
    return _faceTrackingQueue;
}

@end
