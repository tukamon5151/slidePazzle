//
//  ViewController.m
//  SlidePazzle
//
//  Created by 塚本雄大 on 2014/08/21.
//  Copyright (c) 2014年 Yudai Tsukamoto. All rights reserved.
//

#import "ViewController.h"
#import "UIImage+Cropping.h"

static NSInteger const kNumberOfRows=5;
static NSInteger const kNumberOfColumns=5;
static NSInteger const kNumberOfPieces=kNumberOfColumns * kNumberOfRows -1;

@interface ViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIButton *chooseImageButton;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak,nonatomic) UIImageView *imageView;
@property (strong,nonatomic)NSArray *pieceViews;
@property (strong,nonatomic)NSTimer *timer;
@property (strong,nonatomic)NSDate *startDate;
@property (assign,nonatomic)CGPoint pointOfBlank;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib

   //    分割した画像を配置するびゅ−の作成
    NSMutableArray *pieceViews = [NSMutableArray array];
    for (NSInteger i=0; i<kNumberOfPieces; i++) {
//        UIImageViewのインスタンスの作成
        UIImageView *pieceView=[[UIImageView alloc]init];
//        mainViewのサブビューとして追加
        [self.mainView addSubview:pieceView];
//        配列に追加
    
        [pieceViews addObject:pieceView];
    }
    self.pieceViews=pieceViews;
    
        //        分割前の画像を表示する為のビューを作成
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:self.mainView.bounds];
    [self.mainView addSubview:imageView];
    self.imageView =imageView;
 
}
//ゲーム中かどうかの判断
-(BOOL)isPlaying
{
    return  self.imageView.hidden;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)performChooseImageButtonAction:(id)sender {
//    ゲーム中の場合その何も起きない
    if ([self isPlaying]) {
        return;
    }
// UIImagePickerControllerのインスタンスを作成
    UIImagePickerController *controller=[[UIImagePickerController alloc]init];
//    画像の取得元をフォトライブラリに設定
    controller.sourceType=UIImagePickerControllerSourceTypePhotoLibrary;
//    画像を選択後に正方形に加工する様に設定
    controller.allowsEditing=YES;
//    デリゲートをselfに設定
    controller.delegate=self;
//    UIImagePickerControllerを表示
    [self presentViewController:controller animated:YES completion:nil];
    
}
-(BOOL)isSloved
{
    for (NSInteger i=0; i<kNumberOfPieces; i++) {
        UIImageView *pieceView = self.pieceViews[i];
        if(i != pieceView.tag)
            return NO;
    }
    return YES;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (![self isPlaying]) {
        return;
    }
//    タッチを示すオブジェクトを取得
    UITouch *touch = [touches anyObject];
//    タッチ情報からタッチ座標を取得
    CGPoint location = [touch locationInView:self.mainView];
//    タッチ座標がmainView内であれば処理する
    if(CGRectContainsPoint(self.mainView.bounds, location)){
//       タッチ座標から4×4の座標を計算する
        CGFloat width= self.mainView.frame.size.width/kNumberOfColumns;
        CGFloat height=self.mainView.frame.size.height/kNumberOfRows;
        CGPoint point = CGPointMake((int)(location.x/width),(int)(location.y/height));
//        ピースを移動させる
        [self movePieceFromPoint:point withAnimation:YES];
//        パズうが完成していれば処理を行う
        if ([self isSloved]) {
//タイマーを止めて破棄
            [self.timer invalidate];
            self.timer = nil;
//            手前の画像を表示
            self.imageView.hidden=NO;
            [UIView animateWithDuration:0.5f animations:^{
//                フェードイン
                self.imageView.alpha=1;
            }completion:^(BOOL finished){
//                フェードイン完了後にゲームクリアのアラート表示
               NSString *titile =@"ゲームクリア！！";
                NSString *message=[NSString stringWithFormat:
                                   @"タイムは %@ です！",self.timeLabel.text];
                [[[UIAlertView alloc]initWithTitle:titile
                                           message:message
                                          delegate:nil
                                 cancelButtonTitle:@"OK!"
                                 otherButtonTitles:nil]show];
            }];
        }
    }
}

- (IBAction)performStartButtonAction:(id)sender {
//    ゲーム中の場合は何もせず終了
    if ([self isPlaying])
        return;
//    手前の画像をフェードアウト
    [UIView animateWithDuration:0.5f animations:^{
//        ビューのalpha値をアニメーションさせることでフェードアウトさせる
        self.imageView.alpha=0;
    }completion:^(BOOL finished){
//        フェードアウトのアニメション完了後に隠す
        self.imageView.hidden=YES;
    }];
//    乱数のシードを設定
    srand(time(0));
//    ランダムにピースを動かす
    for (NSInteger i=0; i<3000; i++) {
        NSInteger index=rand()%kNumberOfPieces;
        CGPoint point=[self pointFromIndex:index];
        [self movePieceFromPoint:point withAnimation:NO];
    }
//    ゲーム開始時間を保持
    self.startDate=[NSDate date];
//    念の為タイマーを止める
    [self.timer invalidate];
//    タイマーを作成・作動させて保持する
//    0.1秒ごとにselfにupdateTimeLabelメッセージを送る
    self.timer =[NSTimer scheduledTimerWithTimeInterval:0.1
                                                 target:self
                                                selector:@selector(updateTimeLabel)
                                               userInfo:nil repeats:YES];
    
}
-(void)imagePickerController:(UIImagePickerController *)picker
    didFinishPickingMediaWithInfo:(NSDictionary *)info
{
//    正方形に加工済みの画像を取得
    UIImage *image=info[UIImagePickerControllerEditedImage];
//    取得した画像をimageViewに設定
    self.imageView.image=image;

//    分割したピースの幅と高さの計算

    CGFloat width= image.size.width/kNumberOfColumns;
    CGFloat height= image.size.height/kNumberOfRows;
    
    for (NSInteger i=0; i<kNumberOfPieces; i++) {
        CGFloat x=(i % kNumberOfColumns)*width;
        CGFloat y=(i / kNumberOfColumns)*height;
        CGRect rect=CGRectMake(x, y, width, height);
//    画像を切り出す
        UIImage *croppedImage =[image croppedImageInRect:rect];
//        分割後の画像を設定するためのビューを取得
        UIImageView *pieceView = self.pieceViews[i];
//        ビューの座標を設定
        pieceView.frame = [self pieceFrameAtIndex:i];
//ビューに分割後の画像を設定
        pieceView.image=croppedImage;
//        ビューの現在位置を表すインデックスをタグとして保存
        pieceView.tag=i;
    }
//    現在の空き座標を表すプロパティを一番右下の座標に設定
    self.pointOfBlank=CGPointMake(kNumberOfColumns -1,kNumberOfRows);
//    スタートボタンを表示
    self.startButton.hidden=NO;
//    UIImgaePickerControllerを閉じる
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    
}

-(CGPoint)pointFromIndex:(NSInteger)index
{
    return CGPointMake(index % kNumberOfColumns, index / kNumberOfColumns);
}
-(NSInteger)indexFromPoint:(CGPoint)point
{
    return point.y * kNumberOfColumns + point.x;
}
-(CGRect)pieceFrameAtIndex:(NSInteger)index
{
    CGPoint point = [self pointFromIndex:index];
    CGFloat width = self.mainView.frame.size.width/kNumberOfColumns;
    CGFloat height  =self.mainView.frame.size.height/kNumberOfRows;
    return CGRectMake(point.x*width, point.y*height, width, height);
    
}

-(BOOL)canMovePieceFromPoint:(CGPoint)point
{
    if (CGPointEqualToPoint(self.pointOfBlank, point))
        return NO;
    
    return self.pointOfBlank.x==point.x || self.pointOfBlank.y==point.y;
    
}
-(void)movePieceFromPoint:(CGPoint)point withAnimation:(BOOL)animation
{
    if(![self canMovePieceFromPoint:point])
        return;
//    移動方向を決定する
    NSInteger step;
    if(self.pointOfBlank.x==point.x)
        step = self.pointOfBlank.y>point.y ? kNumberOfColumns:-kNumberOfColumns;
        else
            step = self.pointOfBlank.x>point.x?1:-1;
//    移動対象のピースを格納する配列
    NSMutableArray *targetPieceViews = [NSMutableArray array];
    NSInteger indexOfBlank =[self indexFromPoint:self.pointOfBlank];
    NSInteger index =[self indexFromPoint:point];
//    移動対象のピースを抽出する
    while (index!=indexOfBlank) {
        for (UIImageView *pieceView in self.pieceViews){
            if(pieceView.tag==index){
                [targetPieceViews addObject:pieceView];
                break;
            }
        }
        index +=step;
    }
//    移動対象のピースを実際に動かす
//アニメーションが必要な場合は0.2病かけてアニメーションさせる
//    アニメーションが不要な場合はアニメーション時間を0秒にする事で即座に反映させる
    [UIView animateWithDuration:animation ? 0.2f : 0 animations:^{
//        このブロック内でアニメーション対象のプロパティを変更すると、指定した時間でアニメーションする
        for (UIImageView *pieceView in targetPieceViews){
            pieceView.tag+=step;
            pieceView.frame=[self pieceFrameAtIndex:pieceView.tag];
            
        }
    }];
    self.pointOfBlank=point;
}
-(void)updateTimeLabel
{
    if (![self isPlaying]) {
        return;
    }
//    開始時間から現在までの経過時間を秒単位で取得
    NSUInteger time =(NSUInteger)[[NSDate date]timeIntervalSinceDate:self.startDate];
    
                      NSUInteger hour =time /(60*60);
                      NSUInteger minute = (time %(60*60)/60);
                      NSUInteger second = (time %(60*60)%60);
                      self.timeLabel.text=[NSString stringWithFormat:@"%01d:%02d:%02d",hour,minute,second];
}

@end
