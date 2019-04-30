//
//  CLCrossScrollContainerController.m
//  ChanteLa
//
//  Created by Wenhai Xia on 2017/8/17.
//  Copyright © 2017年 xiaochang.com. All rights reserved.
//

#import "CLCrossScrollContainerController.h"
#import "Masonry.h"
#import "FBKVOController.h"
#import "UIScrollView+Extension.h"

@interface CLCrossScrollContainerController () <UIScrollViewDelegate> {
    CGFloat _headerHeight;
    CGFloat _fixHeight;
    NSUInteger _currentIndex;
}

@property (nonatomic, strong) UIView<CLCrossHeaderProtocol> *headerView;
@property (nonatomic, strong) NSArray<UIViewController<CLCrossContentSupplier> *> *contentControllers;
@property (nonatomic, assign) CGPoint currentContentOffset;

@end

@implementation CLCrossScrollContainerController

- (void)dealloc
{
    NSLog(@"CLCrossScrollContainerController dealloc");
}

- (instancetype)initWithHeaderView:(UIView<CLCrossHeaderProtocol> *)headerView
                      headerHeight:(CGFloat)headerHeight
                         fixHeight:(CGFloat)fixHeight
                       controllers:(NSArray<UIViewController<CLCrossContentSupplier> *> *)controllers
                         initIndex:(NSUInteger)initIndex
{
    self = [super init];
    if (self) {
        self.headerView = headerView;
        self.contentControllers = controllers;
        _headerHeight = headerHeight;
        _fixHeight = fixHeight;
        _currentIndex = initIndex;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor whiteColor];
    _currentContentOffset = CGPointMake(0, -_headerHeight);
    [self initContainerView];
    self.horizontalScrollView.hidden = YES;
    
    if (self.navigationController.interactivePopGestureRecognizer != nil) {
        [self.horizontalScrollView.panGestureRecognizer requireGestureRecognizerToFail:self.navigationController.interactivePopGestureRecognizer];
        //        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.horizontalScrollView setContentOffset:CGPointMake(self.view.width * _currentIndex, 0)];
    self.horizontalScrollView.hidden = NO;
}

- (void)initContainerView
{
    self.horizontalScrollView = [[UIScrollView alloc] init];
    self.horizontalScrollView.pagingEnabled = YES;
    self.horizontalScrollView.bounces = NO;
    self.horizontalScrollView.delegate = self;
    [self.view addSubview:self.horizontalScrollView];
    self.horizontalScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    weakify(self)
    [self.horizontalScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        strongify(self)
        make.edges.equalTo(self.view);
    }];
    
    if (@available(iOS 11.0, *)) {
        self.horizontalScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    [self loadAllContentControllers];
    [self loadHeaderView];
    [self updateScrollViewObserver];
}

- (void)loadHeaderView
{
    self.headerView.translatesAutoresizingMaskIntoConstraints = NO;
    UIScrollView *scrollView = [self getCurrentContentScrollView];
    [scrollView addSubview:self.headerView];
    weakify(self)
    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        strongify(self)
        make.left.mas_offset(0.0f);
        make.width.equalTo(self.view.mas_width);
        make.top.mas_offset(0.0f);
        make.height.mas_offset(_headerHeight);
    }];
}

- (void)reloadHeaderHeight:(CGFloat)headerHeight fixHeight:(CGFloat)fixHeight
{
    _headerHeight = headerHeight;
    _fixHeight = fixHeight;
    
    CGFloat y = 0.0f;
    if (self.currentContentOffset.y < - _fixHeight) {
        y = -_headerHeight;
    } else {
        y = -_headerHeight + self.currentContentOffset.y + _fixHeight;
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        weakify(self)
        [self.headerView mas_remakeConstraints:^(MASConstraintMaker *make) {
            strongify(self)
            make.left.mas_offset(0.0f);
            make.width.equalTo(self.view.mas_width);
            make.top.mas_offset(y);
            make.height.mas_offset(_headerHeight);
        }];
        
        for (UIViewController<CLCrossContentSupplier> *controller in self.contentControllers) {
            UIScrollView *scrollView = [controller getScrollView];
            [scrollView setContentInsetTop:_headerHeight];
        }
        
        [self.view layoutIfNeeded];
    }];
}

- (void)loadAllContentControllers
{
    weakify(self)
    [self.contentControllers enumerateObjectsUsingBlock:^(UIViewController<CLCrossContentSupplier> * _Nonnull controller, NSUInteger idx, BOOL * _Nonnull stop) {
        strongify(self)
        [self addChildViewController:controller];
        [self.horizontalScrollView addSubview:controller.view];
        [controller didMoveToParentViewController:self];
        UIScrollView *scrollView = [controller getScrollView];
        [scrollView setContentInsetTop:_headerHeight];
        scrollView.contentOffset = _currentContentOffset;
        controller.view.translatesAutoresizingMaskIntoConstraints = NO;
        if (idx == 0) {
            [controller.view mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.mas_equalTo(0.0f);
                make.width.equalTo(self.view);
                make.height.equalTo(self.view);
                make.top.mas_equalTo(0.0f);
                make.bottom.mas_equalTo(0.0f);

                if (self.contentControllers.count == 1) {
                    make.right.mas_equalTo(0.0f);
                }
            }];

            return;
        }

        UIViewController<CLCrossContentSupplier> *preController = self.contentControllers[idx - 1];
        [controller.view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(preController.view.mas_right);
            make.width.equalTo(self.view);
            make.height.equalTo(self.view);
            make.top.mas_equalTo(0.0f);
            make.bottom.mas_equalTo(0.0f);

            if (idx == self.contentControllers.count - 1) {
                make.right.mas_equalTo(0.0f);
            }
        }];
    }];
}

- (void)updateScrollViewObserver
{
    [self.KVOController unobserveAll];
    weakify(self);
    [self.KVOController observe:[self getCurrentContentScrollView] keyPath:@"contentOffset" options:NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
        strongify(self)
        UIScrollView *currentScrollView = [self getCurrentContentScrollView];
        self.currentContentOffset = currentScrollView.contentOffset;
        [self syncAllScrollViewOffset];
        [self updateHeaderViewPosition];
    }];
}

- (UIScrollView *)getCurrentContentScrollView
{
    UIViewController<CLCrossContentSupplier> *currentContentSupplier = self.contentControllers[_currentIndex];
    
    return [currentContentSupplier getScrollView];
}

- (void)syncAllScrollViewOffset
{
    for (UIViewController<CLCrossContentSupplier> *contentSupplier in self.contentControllers) {
        if (contentSupplier == self.contentControllers[_currentIndex]) {
            continue;
        }
        
        [self syncSpecialScrollViewOffset:contentSupplier];
    }
}

- (void)syncSpecialScrollViewOffset:(UIViewController<CLCrossContentSupplier> *)contentController
{
    UIScrollView *otherScrollView = [contentController getScrollView];
    
    if (self.currentContentOffset.y < - _fixHeight) {
        otherScrollView.contentOffset = self.currentContentOffset;
    } else {
        if (otherScrollView.contentOffset.y > - _fixHeight) {
            return;
        } else {
            otherScrollView.contentOffset = CGPointMake(0, - _fixHeight);
        }
    }
}

- (void)suspendHeaderView
{
    if (self.headerView.superview == self.view) {
        return;
    }
    [self.headerView removeFromSuperview];
    
    CGFloat y = 0.0f;
    if (self.currentContentOffset.y < - _fixHeight) {
        y = -(_headerHeight + self.currentContentOffset.y);
    } else {
        y = -(_headerHeight - _fixHeight);
    }
    
    [self.view addSubview:self.headerView];
    weakify(self)
    [self.headerView mas_remakeConstraints:^(MASConstraintMaker *make) {
        strongify(self)
        make.left.mas_offset(0.0f);
        make.width.equalTo(self.view.mas_width);
        make.top.mas_offset(y);
        make.height.mas_offset(_headerHeight);
    }];
    [self.view layoutIfNeeded];
}

- (void)embedHeaderView
{
    if (self.headerView.superview == [self getCurrentContentScrollView]) {
        return;
    }
    [self.headerView removeFromSuperview];
    
    CGFloat y = 0.0f;
    if (self.currentContentOffset.y < - _fixHeight) {
        y = -_headerHeight;
    } else {
        y = -_headerHeight + self.currentContentOffset.y + _fixHeight;
    }
    
    [[self getCurrentContentScrollView] addSubview:self.headerView];
    weakify(self)
    [self.headerView mas_remakeConstraints:^(MASConstraintMaker *make) {
        strongify(self)
        make.left.mas_offset(0.0f);
        make.width.equalTo(self.view.mas_width);
        make.top.mas_offset(y);
        make.height.mas_offset(_headerHeight);
    }];
    [self.view layoutIfNeeded];
}

- (void)updateHeaderViewPosition
{
    CGFloat y = 0.0f;
    if (self.currentContentOffset.y < - _fixHeight) {
        y = -_headerHeight;
    } else {
        y = -_headerHeight + self.currentContentOffset.y + _fixHeight;
    }
    
    weakify(self)
    [self.headerView mas_remakeConstraints:^(MASConstraintMaker *make) {
        strongify(self)
        make.left.mas_offset(0.0f);
        make.width.equalTo(self.view.mas_width);
        make.top.mas_offset(y);
        make.height.mas_offset(_headerHeight);
    }];
    
    [[self getCurrentContentScrollView] layoutIfNeeded];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSInteger index = scrollView.contentOffset.x / ScreenSize.width;
    [self.headerView syncCurrentIndex:index];
    _currentIndex = index;
    self.currentContentOffset = [self getCurrentContentScrollView].contentOffset;
    [self updateScrollViewObserver];
    [self embedHeaderView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        NSInteger index = scrollView.contentOffset.x / ScreenSize.width;
        [self.headerView syncCurrentIndex:index];
        _currentIndex = index;
        self.currentContentOffset = [self getCurrentContentScrollView].contentOffset;
        [self updateScrollViewObserver];
        [self embedHeaderView];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self suspendHeaderView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self.headerView respondsToSelector:@selector(syncContentHorizontalScrollRate:)]) {
        CGFloat rate = scrollView.contentOffset.x / scrollView.contentSize.width;
        [self.headerView syncContentHorizontalScrollRate:rate];
    }
}

#pragma mark - property set & get

- (void)showContentWithIndex:(NSUInteger)index
{
    _currentIndex = index;
    self.currentContentOffset = [self getCurrentContentScrollView].contentOffset;
    [self updateScrollViewObserver];
    [self embedHeaderView];
    [self.horizontalScrollView setContentOffset:CGPointMake(self.view.width * _currentIndex, 0)];
}

- (void)setCurrentContentOffset:(CGPoint)currentContentOffset
{
    _currentContentOffset = currentContentOffset;
    self.offsetY = _currentContentOffset.y;
}

- (void)setOffsetY:(CGFloat)offsetY
{
    [self willChangeValueForKey:@"offsetY"];
    _offsetY = offsetY + _headerHeight;
    [self didChangeValueForKey:@"offsetY"];
}

@end
