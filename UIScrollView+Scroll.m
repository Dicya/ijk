//
//  UIScrollView+Scroll.m
//  show
//
//  Created by 曾陆洋 on 16/7/20.
//  Copyright © 2016年 changba. All rights reserved.
//

#import "UIScrollView+Scroll.h"
#import "UIScrollView+Extension.h"
#import "UIView+Additional.h"

@implementation UIScrollView (Scroll)

- (void)adjustScrollViewContentX:(UIView *)centerView margin:(CGFloat)margin
{
    CGFloat offset = centerView.frame.origin.x - (self.bounds.size.width- (margin+centerView.bounds.size.width))/2;
    if(offset<=0.0f)
    {
        offset = 0.0;
    }
    else if(offset>=self.contentSizeWidth-self.width)
    {
        offset = self.contentSizeWidth-self.width;
    }
    [self setContentOffset:CGPointMake(offset, 0)  animated:YES];
}

@end
