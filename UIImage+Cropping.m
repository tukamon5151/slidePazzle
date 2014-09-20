//
//  UIImage+Cropping.m
//  SlidePazzle
//
//  Created by 塚本雄大 on 2014/08/21.
//  Copyright (c) 2014年 Yudai Tsukamoto. All rights reserved.
//

#import "UIImage+Cropping.h"

@implementation UIImage (Cropping)

-(UIImage *)croppedImageInRect:(CGRect)rect
{
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
    UIImage *croopedImgae =[UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return croopedImgae;
}
@end
