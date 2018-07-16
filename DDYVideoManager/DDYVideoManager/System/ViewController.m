#import "ViewController.h"
#import "DDYCameraController.h"
#import "DDYAuthorityManager.h"

@interface ViewController ()

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation ViewController

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 140, 120, 240)];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _imageView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *takeButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:@"take" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [button setBackgroundColor:[UIColor lightGrayColor]];
        [button addTarget:self action:@selector(handleTake) forControlEvents:UIControlEventTouchUpInside];
        [button setFrame:CGRectMake(0, 100, 120, 30)];
        button;
    });
    [self.view addSubview:takeButton];
    [self.view addSubview:self.imageView];
}

- (void)handleTake {
    [DDYAuthorityManager ddy_AudioAuthAlertShow:YES success:^{
        [DDYAuthorityManager ddy_CameraAuthAlertShow:YES success:^{
            DDYCameraController *cameraVC = [DDYCameraController new];
            [cameraVC setTakePhotoBlock:^(UIImage *image, UIViewController *vc) {
                self.imageView.image = image;
                [vc dismissViewControllerAnimated:YES completion:^{   }];
            }];
            [self presentViewController:cameraVC animated:YES completion:^{ }];
        } fail:^(AVAuthorizationStatus authStatus) { }];
    } fail:^(AVAuthorizationStatus authStatus) { }];
    
}

@end
