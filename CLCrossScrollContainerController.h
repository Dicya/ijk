//
//  CLCrossScrollContainerController.h
//  ChanteLa
//
//  Created by Wenhai Xia on 2017/8/17.
//  Copyright © 2017年 xiaochang.com. All rights reserved.
//

#import "CLBaseViewController.h"

@protocol CLCrossContentSupplier <NSObject>

- (UIScrollView *)getScrollView;

@end

@protocol CLCrossHeaderProtocol <NSObject>

- (void)syncCurrentIndex:(NSUInteger)index;

@optional
- (void)syncContentHorizontalScrollRate:(CGFloat)rate;

@end

@interface CLCrossScrollContainerController : CLBaseViewController

@property (nonatomic, assign, readonly) CGFloat offsetY;
@property (nonatomic, strong) UIScrollView *horizontalScrollView;


- (instancetype)initWithHeaderView:(UIView<CLCrossHeaderProtocol> *)headerView
                      headerHeight:(CGFloat)headerHeight
                         fixHeight:(CGFloat)fixHeight
                       controllers:(NSArray<UIViewController<CLCrossContentSupplier> *> *)controllers
                         initIndex:(NSUInteger)initIndex;

- (void)reloadHeaderHeight:(CGFloat)headerHeight fixHeight:(CGFloat)fixHeight;

- (void)showContentWithIndex:(NSUInteger)index;

@end
