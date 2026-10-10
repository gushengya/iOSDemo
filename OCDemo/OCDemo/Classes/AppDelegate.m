//
//  AppDelegate.m
//  OCDemo
//
//  Created by user on 2026/7/2.
//

#import "AppDelegate.h"

#import <UserNotifications/UserNotifications.h>

#if __has_include(<BLMainframe/BLMainframe.h>)
    #import <BLMainframe/BLMainframe.h>
#endif

@interface AppDelegate ()
/// 主要业务入口
@property (nonatomic, strong, nullable) id <UIApplicationDelegate> mainframe;
@property (nonatomic, copy, nullable) NSDictionary *cachedLaunchOptions;
@property (nonatomic, assign) BOOL didPrepareMainframe;
@property (nonatomic, assign) BOOL didStartMainframe;
@end

@implementation AppDelegate

#pragma mark - ApplicationLaunch

/// 进程冷启动时由系统调用，早于 Scene 创建窗口。
/// 进入情况：用户点图标启动、被推送或后台任务拉起进程。从后台回前台不会再进。
/// 进程起来，此时还没有窗口，所以只做了 prepareMainframeOnce，界面启动放到 attachSceneWindow:。
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.cachedLaunchOptions = launchOptions;
    [self prepareMainframeOnce];
    // 使用 Scene 时，系统回调发生在窗口创建之前。界面启动放到 attachSceneWindow:。
    if (self.window != nil) {
        [self startMainframeIfNeeded];
    }
    return YES;
}

/// 由 SceneDelegate 在场景连接后调用，不是系统回调。
/// 进入情况：冷启动场景连上，或系统丢弃场景后重新创建。从后台回前台不会进。
/// App 已在运行时的外链、快捷方式不进这里，分别走 Scene 的 openURLContexts、performActionForShortcutItem。
/// Universal Link 和 Siri 的 NSUserActivity 冷启动、热启动都由系统回调 scene:continueUserActivity:，这里不再转发，避免处理两次。
- (void)attachSceneWindow:(UIWindow *)window connectionOptions:(UISceneConnectionOptions *)connectionOptions {
    // 记下已挂到 UIWindowScene 的窗口，CNMainframe 用它装根界面。
    self.window = window;
    NSMutableDictionary *launchOptions = [self.cachedLaunchOptions mutableCopy] ?: [NSMutableDictionary dictionary];
    // 点通知冷启动时，内容在 connectionOptions 里，不在 didFinishLaunching 的 launchOptions 里。
    if (connectionOptions.notificationResponse) {
        launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] = connectionOptions.notificationResponse.notification.request.content.userInfo;
    }
    self.cachedLaunchOptions = launchOptions;
    // 窗口就绪后只启动一次界面。场景重建不会再次装根控制器。
    [self startMainframeIfNeeded];

    // URL Scheme 冷启动，例如支付宝、微信回跳。系统不会再补一次 scene:openURLContexts:。
    for (UIOpenURLContext *context in connectionOptions.URLContexts) {
        [self application:UIApplication.sharedApplication openURL:context.URL options:@{}];
    }
    // 主屏幕快捷方式冷启动。热启动不会走到这个分支。
    if (connectionOptions.shortcutItem) {
        [self application:UIApplication.sharedApplication performActionForShortcutItem:connectionOptions.shortcutItem completionHandler:^(BOOL succeeded) {
        }];
    }
}

- (void)prepareMainframeOnce {
    if (self.didPrepareMainframe) {
        return;
    }
    self.didPrepareMainframe = YES;

#if __has_include(<BLMainframe/BLMainframe.h>)
    self.mainframe = [[BLMainframe alloc] init];
#endif
}

- (void)startMainframeIfNeeded {
    if (self.didStartMainframe || self.window == nil) {
        return;
    }
    self.didStartMainframe = YES;
    // 转发给CNMainframe处理
    if ([self.mainframe respondsToSelector:@selector(application:didFinishLaunchingWithOptions:)]) {
        [self.mainframe application:UIApplication.sharedApplication didFinishLaunchingWithOptions:self.cachedLaunchOptions];
    }
}

/// 启用 Scene 后系统不再调用，由 sceneDidBecomeActive: 转发。
/// 进入情况：冷启动界面可交互后、从后台回到前台、关掉控制中心/通知中心/来电后界面重新可操作。
- (void)applicationDidBecomeActive:(UIApplication *)application {
    if ([self.mainframe respondsToSelector:@selector(applicationDidBecomeActive:)]) {
        [self.mainframe applicationDidBecomeActive:application];
    }
}

/// 启用 Scene 后系统不再调用，由 sceneWillResignActive: 转发。
/// 进入情况：拉出控制中心、通知中心、来电、进入多任务界面，或即将进入后台之前。
- (void)applicationWillResignActive:(UIApplication *)application {
    if ([self.mainframe respondsToSelector:@selector(applicationWillResignActive:)]) {
        [self.mainframe applicationWillResignActive:application];
    }
}

/// 启用 Scene 后系统不再调用，由 sceneWillEnterForeground: 转发。
/// 进入情况：App 从后台回到前台，发生在变为活跃之前。冷启动不会进。
- (void)applicationWillEnterForeground:(UIApplication *)application {
    if ([self.mainframe respondsToSelector:@selector(applicationWillEnterForeground:)]) {
        [self.mainframe applicationWillEnterForeground:application];
    }
}
/// 启用 Scene 后系统不再调用，由 sceneDidEnterBackground: 转发。
/// 进入情况：用户回到桌面或切到其他 App，界面已经不可见。
- (void)applicationDidEnterBackground:(UIApplication *)application {
    if ([self.mainframe respondsToSelector:@selector(applicationDidEnterBackground:)]) {
        [self.mainframe applicationDidEnterBackground:application];
    }
}

/// 系统仍直接调用 AppDelegate。不保证每次被杀都会进。
/// 进入情况：用户从多任务划掉 App，或系统在前台因资源回收准备结束进程。挂起后被系统杀掉通常不进。
- (void)applicationWillTerminate:(UIApplication *)application {
    if ([self.mainframe respondsToSelector:@selector(applicationWillTerminate:)]) {
        [self.mainframe applicationWillTerminate:application];
    }
}

/// 系统仍直接调用 AppDelegate。
/// 进入情况：界面旋转、present 页面、或系统询问当前窗口允许哪些方向时。
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    if ([self.mainframe respondsToSelector:@selector(application:supportedInterfaceOrientationsForWindow:)]) {
        return [self.mainframe application:application supportedInterfaceOrientationsForWindow:window];
    }
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - openURL

/// 启用 Scene 后系统不再调用，由 scene:openURLContexts: 或冷启动 connectionOptions 转发。
/// 进入情况：其他 App 用 URL Scheme 打开本 App，例如支付宝、微信回跳。
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    if ([self.mainframe respondsToSelector:@selector(application:openURL:options:)]) {
        return [self.mainframe application:app openURL:url options:options];
    }
    return YES;
}

/// 启用 Scene 后系统不再调用，只由 scene:continueUserActivity: 转发。冷启动、热启动都走这一次。
/// 进入情况：Siri、Universal Link、Handoff，或通过 NSUserActivity 打开本 App。
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    if ([self.mainframe respondsToSelector:@selector(application:continueUserActivity:restorationHandler:)]) {
        return [self.mainframe application:application continueUserActivity:userActivity restorationHandler:restorationHandler];
    }
    return YES;
}

#pragma mark - Notifications

// iOS7-iOS13 performFetchWithCompletionHandler deprecated

/// 系统仍直接调用 AppDelegate，与 Scene 无关。
/// 进入情况：收到带 content-available 的静默推送，或后台被推送唤醒。
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    if ([self.mainframe respondsToSelector:@selector(application: didReceiveRemoteNotification: fetchCompletionHandler:)]) {
        [self.mainframe application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
    }
}
/// 系统仍直接调用 AppDelegate。
/// 进入情况：向系统注册远程推送成功，冷启动时用户已授权通知也会进。
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if ([self.mainframe respondsToSelector:@selector(application: didRegisterForRemoteNotificationsWithDeviceToken:)]) {
        [self.mainframe application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    }
}

/// 系统仍直接调用 AppDelegate。
/// 进入情况：推送注册失败，例如用户拒绝通知、模拟器不支持、描述文件或 Bundle Id 配置错误。
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if ([self.mainframe respondsToSelector:@selector(application: didFailToRegisterForRemoteNotificationsWithError:)]) {
        [self.mainframe application:application didFailToRegisterForRemoteNotificationsWithError:error];
    }
}

#pragma mark - shortcutItem

/// 启用 Scene 后系统不再调用。热启动由 windowScene:performActionForShortcutItem: 转发，冷启动由 connectionOptions.shortcutItem 转发。
/// 进入情况：用户点击主屏幕快捷方式。
-(void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    if ([self.mainframe respondsToSelector:@selector(application: performActionForShortcutItem:completionHandler:)]) {
        [self.mainframe application:application performActionForShortcutItem:shortcutItem completionHandler:completionHandler];
    }
}

#pragma mark - application 内存管理
/// 系统仍直接调用 AppDelegate。
/// 进入情况：系统内存紧张，要求 App 释放缓存。
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    if ([self.mainframe respondsToSelector:@selector(applicationDidReceiveMemoryWarning:)]) {
        [self.mainframe applicationDidReceiveMemoryWarning:application];
    }
}

@end


