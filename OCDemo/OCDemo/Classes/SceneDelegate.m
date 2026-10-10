//
//  SceneDelegate.m
//  OCDemo
//
//  Created by user on 2026/7/2.
//

#import "SceneDelegate.h"
#import "AppDelegate.h"

@interface SceneDelegate ()

@end

@implementation SceneDelegate

/// 场景即将连上会话时由系统调用。
/// 进入情况：冷启动创建界面、系统丢弃场景后再次创建。从后台回前台不会进。
/// 冷启动的外链、Universal Link、快捷方式、通知点击从 connectionOptions 带入。
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:UIWindowScene.class]) {
        return;
    }
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window = window;
    [appDelegate attachSceneWindow:window connectionOptions:connectionOptions];
}

/// 场景被释放时由系统调用。不等于进程退出，applicationWillTerminate: 仍可能另外发生。
/// 进入情况：场景进入后台后系统回收，或用户划掉任务后会话被丢弃。之后场景可能被重新创建并再次 willConnect。
- (void)sceneDidDisconnect:(UIScene *)scene {
}


/// 场景变为可交互时由系统调用，并转发给 AppDelegate。
/// 进入情况：冷启动界面显示完成、从后台回到前台、关闭控制中心/通知中心/来电后。
- (void)sceneDidBecomeActive:(UIScene *)scene {
    AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    [appDelegate applicationDidBecomeActive:UIApplication.sharedApplication];
}

/// 场景即将失去交互时由系统调用，并转发给 AppDelegate。
/// 进入情况：拉出控制中心、通知中心、来电、进入多任务，或即将进入后台之前。
- (void)sceneWillResignActive:(UIScene *)scene {
    AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    [appDelegate applicationWillResignActive:UIApplication.sharedApplication];
}

/// 场景从后台回到前台时由系统调用，并转发给 AppDelegate。发生在变为活跃之前。
/// 进入情况：用户从桌面或其他 App 切回本 App。冷启动也会进。
- (void)sceneWillEnterForeground:(UIScene *)scene {
    AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    [appDelegate applicationWillEnterForeground:UIApplication.sharedApplication];
}

/// 场景进入后台时由系统调用，并转发给 AppDelegate。
/// 进入情况：用户回到桌面或切到其他 App，界面已经不可见。
- (void)sceneDidEnterBackground:(UIScene *)scene {
    AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    [appDelegate applicationDidEnterBackground:UIApplication.sharedApplication];
}

/// App 已在运行时，用 URL Scheme 打开本场景，由系统调用并转发给 AppDelegate。
/// 进入情况：支付宝、微信等回跳。冷启动的 URL 在 willConnect 的 connectionOptions 里，不进这里。
- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    for (UIOpenURLContext *context in URLContexts) {
        [appDelegate application:UIApplication.sharedApplication openURL:context.URL options:@{}];
    }
}

/// 用 NSUserActivity 打开本场景时由系统调用，并转发给 AppDelegate。冷启动、热启动都只进这里一次。
/// 进入情况：Siri、Universal Link、Handoff。冷启动时系统也会在 willConnect 之后再回调本方法，不要在 attachSceneWindow: 里提前处理。
- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity {
    AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    [appDelegate application:UIApplication.sharedApplication continueUserActivity:userActivity restorationHandler:^(NSArray<id<UIUserActivityRestoring>> * _Nullable restorableObjects) {
    }];
}

/// App 已在运行时，用户点击主屏幕快捷方式，由系统调用并转发给 AppDelegate。
/// 冷启动点快捷方式时，系统放进 connectionOptions.shortcutItem，一般不会再进这里。
- (void)windowScene:(UIWindowScene *)windowScene performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    [appDelegate application:UIApplication.sharedApplication performActionForShortcutItem:shortcutItem completionHandler:completionHandler];
}


@end
