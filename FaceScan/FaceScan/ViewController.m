//
//  ViewController.m
//  FaceScan
//
//  Created by 汤迪希 on 29/03/2018.
//  Copyright © 2018 DC. All rights reserved.
//

#import "ViewController.h"
#import "GPUImageBeautifyFilter.h"

@interface ViewController () <ARSCNViewDelegate, ARSessionDelegate>

@property (nonatomic, strong) ARSCNView *sceneView;
@property (nonatomic, strong) SCNNode *sceneNode;
@property (nonatomic, strong) SCNNode *faceNode;

@property (nonatomic, strong) GPUImageView *captureView;
@property (nonatomic, strong) GPUImageVideoCamera *camera;
@property (nonatomic, strong) GPUImageBeautifyFilter *beautifyFilter;

@property (nonatomic, strong) dispatch_queue_t faceTrackingQueue;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setupViews];
	[self setupLive];
    [self setupSession];
}

- (void)setupViews {
	[self.view addSubview:self.captureView];
	[self.view addSubview:self.sceneView];
}

- (void)setupLive {
	[self.camera addTarget:self.beautifyFilter];
	[self.beautifyFilter addTarget:self.captureView];
	[self.camera startCameraCapture];
}

- (void)setupSession {
    
    ARFaceTrackingConfiguration *configuration = [[ARFaceTrackingConfiguration alloc] init];
    configuration.lightEstimationEnabled = YES;
    
    [self.sceneView.session runWithConfiguration:configuration
                                         options:ARSessionRunOptionResetTracking | ARSessionRunOptionRemoveExistingAnchors];
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
	
	
	
}

#pragma mark - Lazy Loading

- (ARSCNView *)sceneView {
    if (! _sceneView) {
			
		CGRect rect = CGRectMake(0, 0, 375, 812);
			
        _sceneView = [[ARSCNView alloc] initWithFrame:rect options:nil];
		_sceneView.center = self.view.center;
		
        _sceneView.showsStatistics = YES;
        _sceneView.delegate = self;
        _sceneView.session.delegate = self;
		
    }
    return _sceneView;
}

- (SCNNode *)faceNode {
    if (! _faceNode) {
        ARSCNFaceGeometry *faceGeometry = [ARSCNFaceGeometry faceGeometryWithDevice:self.sceneView.device];
		faceGeometry.firstMaterial.diffuse.contents = UIColor.whiteColor;
        faceGeometry.firstMaterial.lightingModelName = SCNLightingModelPhong;
        
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

- (GPUImageView *)captureView {
	if (! _captureView) {
		_captureView = [[GPUImageView alloc] initWithFrame:self.sceneView.frame];
	}
	return _captureView;
}

- (GPUImageVideoCamera *)camera {
	if (! _camera) {
		_camera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
		_camera.horizontallyMirrorFrontFacingCamera = YES;
		_camera.outputImageOrientation = UIInterfaceOrientationPortrait;
	}
	return _camera;
}

- (GPUImageBeautifyFilter *)beautifyFilter {
	if (! _beautifyFilter) {
		_beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
	}
	return _beautifyFilter;
}

@end
