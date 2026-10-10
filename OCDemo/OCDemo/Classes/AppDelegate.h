//
//  AppDelegate.h
//  OCDemo
//
//  Created by user on 2026/7/2.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong, nullable) UIWindow *window;

/// Scene 连上后挂上窗口，并只执行一次界面启动。
- (void)attachSceneWindow:(UIWindow *)window connectionOptions:(UISceneConnectionOptions *)connectionOptions;

@end

