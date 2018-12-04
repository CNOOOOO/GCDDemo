//
//  ViewController.m
//  GCDDemo
//
//  Created by Mac2 on 2018/11/14.
//  Copyright © 2018年 Mac2. All rights reserved.
//

/************************************GCD**************************************
1、任务
 同步执行（sync）:
->同步添加任务到指定的队列中，在添加的任务执行结束之前，当前线程会一直等待，直到队列里面的任务完成之后再继续执行。
->只能在当前线程中执行任务，不具备开启新线程的能力。
 异步执行（async）:
->异步添加任务到指定的队列中，它不会做任何等待，可以继续执行任务。
->可以在新的线程中执行任务，具备开启新线程的能力。
 
2、队列
 串行队列（Serial Dispatch Queue）:
->每次只有一个任务被执行。让任务一个接着一个地执行。（只开启一个线程，一个任务执行完毕后，再执行下一个任务）。
 并发队列（Concurrent Dispatch Queue）：
->可以让多个任务并发（同时）执行。（可以开启多个线程，并且同时执行任务）
 主队列（Main Dispatch Queue）：
 ->一种特殊的串行队列，所有放在主队列中的任务，都会放到主线程中执行，可使用dispatch_get_main_queue()获得主队列。
 全局并发队列（Global Dispatch Queue）：
 ->可以使用dispatch_get_global_queue来获取。需要传入两个参数。第一个参数表示队列优先级，一般用DISPATCH_QUEUE_PRIORITY_DEFAULT。第二个参数暂时没用，用0即可。
*****************************************************************************/

#import "ViewController.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface ViewController ()

@property (nonatomic, strong) UIButton *buttonOne;//同步执行+串行队列
@property (nonatomic, strong) UIButton *buttonTwo;//同步执行+并发队列
@property (nonatomic, strong) UIButton *buttonThree;//异步执行+串行队列
@property (nonatomic, strong) UIButton *buttonFour;//异步执行+并发队列
@property (nonatomic, strong) UIButton *buttonFive;//主线程调用 同步执行+主队列
@property (nonatomic, strong) UIButton *buttonSix;//其他线程调用 同步执行+主队列
@property (nonatomic, strong) UIButton *buttonSeven;//异步执行+主队列
@property (nonatomic, strong) UIButton *buttonEight;//栅栏
@property (nonatomic, strong) UIButton *buttonNine;//dispatch_group_notify
@property (nonatomic, strong) UIButton *buttonTen;//dispatch_group_wait
@property (nonatomic, strong) UIButton *buttonEleven;//dispatch_group_enter、dispatch_group_leave
@property (nonatomic, strong) UIButton *buttonTwelve;//信号量将异步执行转成同步执行
@property (nonatomic, strong) UIButton *buttonThirteen;//信号量保证线程安全
@property (nonatomic, assign) int ticketSurplusCount;//剩余票数
@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CFRunLoopObserverRef ob = CFRunLoopObserverCreateWithHandler(CFAllocatorGetDefault(), kCFRunLoopAllActivities, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        NSLog(@"runloop状态改变%zd", activity);
    });
    CFRunLoopAddObserver(CFRunLoopGetCurrent(), ob, kCFRunLoopDefaultMode);
    CFRelease(ob);
    
    self.buttonOne = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonOne.frame = CGRectMake(SCREEN_WIDTH / 2 - 50, 30, 100, 40);
    [self.buttonOne setTitle:@"同步串行" forState:UIControlStateNormal];
    [self.buttonOne setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.buttonOne.titleLabel.font = [UIFont systemFontOfSize:15];
    self.buttonOne.backgroundColor = [UIColor blackColor];
    self.buttonOne.layer.masksToBounds = YES;
    self.buttonOne.layer.cornerRadius = 6;
    [self.buttonOne addTarget:self action:@selector(syncAndSerial) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.buttonOne];
    
    self.buttonTwo = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonTwo.frame = CGRectMake(SCREEN_WIDTH / 2 - 50, 90, 100, 40);
    [self.buttonTwo setTitle:@"同步并发" forState:UIControlStateNormal];
    [self.buttonTwo setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.buttonTwo.titleLabel.font = [UIFont systemFontOfSize:15];
    self.buttonTwo.backgroundColor = [UIColor blackColor];
    self.buttonTwo.layer.masksToBounds = YES;
    self.buttonTwo.layer.cornerRadius = 6;
    [self.buttonTwo addTarget:self action:@selector(syncAndConcurrent) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.buttonTwo];
    
    self.buttonThree = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonThree.frame = CGRectMake(SCREEN_WIDTH / 2 - 50, 150, 100, 40);
    [self.buttonThree setTitle:@"异步串行" forState:UIControlStateNormal];
    [self.buttonThree setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.buttonThree.titleLabel.font = [UIFont systemFontOfSize:15];
    self.buttonThree.backgroundColor = [UIColor blackColor];
    self.buttonThree.layer.masksToBounds = YES;
    self.buttonThree.layer.cornerRadius = 6;
    [self.buttonThree addTarget:self action:@selector(asyncAndSerial) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.buttonThree];
    
    self.buttonFour = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonFour.frame = CGRectMake(SCREEN_WIDTH / 2 - 50, 210, 100, 40);
    [self.buttonFour setTitle:@"异步并发" forState:UIControlStateNormal];
    [self.buttonFour setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.buttonFour.titleLabel.font = [UIFont systemFontOfSize:15];
    self.buttonFour.backgroundColor = [UIColor blackColor];
    self.buttonFour.layer.masksToBounds = YES;
    self.buttonFour.layer.cornerRadius = 6;
    [self.buttonFour addTarget:self action:@selector(asyncAndConcurrent) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.buttonFour];
    
    self.buttonFive = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonFive.frame = CGRectMake(SCREEN_WIDTH / 2 - 90, 270, 180, 40);
    [self.buttonFive setTitle:@"主线程调用同步主队列" forState:UIControlStateNormal];
    [self.buttonFive setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.buttonFive.titleLabel.font = [UIFont systemFontOfSize:15];
    self.buttonFive.backgroundColor = [UIColor blackColor];
    self.buttonFive.layer.masksToBounds = YES;
    self.buttonFive.layer.cornerRadius = 6;
    [self.buttonFive addTarget:self action:@selector(mainThreadSyncAndMainQueue) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.buttonFive];
    
    self.buttonSix = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonSix.frame = CGRectMake(SCREEN_WIDTH / 2 - 90, 330, 180, 40);
    [self.buttonSix setTitle:@"其他线程调用同步主队列" forState:UIControlStateNormal];
    [self.buttonSix setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.buttonSix.titleLabel.font = [UIFont systemFontOfSize:15];
    self.buttonSix.backgroundColor = [UIColor blackColor];
    self.buttonSix.layer.masksToBounds = YES;
    self.buttonSix.layer.cornerRadius = 6;
    [self.buttonSix addTarget:self action:@selector(otherThreadSyncAndMainQueue) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.buttonSix];
    
    self.buttonSeven = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonSeven.frame = CGRectMake(SCREEN_WIDTH / 2 - 50, 390, 100, 40);
    [self.buttonSeven setTitle:@"异步主队列" forState:UIControlStateNormal];
    [self.buttonSeven setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.buttonSeven.titleLabel.font = [UIFont systemFontOfSize:15];
    self.buttonSeven.backgroundColor = [UIColor blackColor];
    self.buttonSeven.layer.masksToBounds = YES;
    self.buttonSeven.layer.cornerRadius = 6;
    [self.buttonSeven addTarget:self action:@selector(asyncAndMainQueue) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.buttonSeven];
    
    self.buttonEight = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonEight.frame = CGRectMake(10, 390, 100, 40);
    [self.buttonEight setTitle:@"栅栏" forState:UIControlStateNormal];
    [self.buttonEight setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.buttonEight.titleLabel.font = [UIFont systemFontOfSize:15];
    self.buttonEight.backgroundColor = [UIColor blackColor];
    self.buttonEight.layer.masksToBounds = YES;
    self.buttonEight.layer.cornerRadius = 6;
    [self.buttonEight addTarget:self action:@selector(barrier) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.buttonEight];
    
    self.buttonNine = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonNine.frame = CGRectMake(SCREEN_WIDTH - 110, 390, 100, 40);
    [self.buttonNine setTitle:@"notify" forState:UIControlStateNormal];
    [self.buttonNine setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.buttonNine.titleLabel.font = [UIFont systemFontOfSize:15];
    self.buttonNine.backgroundColor = [UIColor blackColor];
    self.buttonNine.layer.masksToBounds = YES;
    self.buttonNine.layer.cornerRadius = 6;
    [self.buttonNine addTarget:self action:@selector(notify) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.buttonNine];
    
    self.buttonTen = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonTen.frame = CGRectMake(10, 450, 100, 40);
    [self.buttonTen setTitle:@"wait" forState:UIControlStateNormal];
    [self.buttonTen setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.buttonTen.titleLabel.font = [UIFont systemFontOfSize:15];
    self.buttonTen.backgroundColor = [UIColor blackColor];
    self.buttonTen.layer.masksToBounds = YES;
    self.buttonTen.layer.cornerRadius = 6;
    [self.buttonTen addTarget:self action:@selector(wait) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.buttonTen];
    
    self.buttonEleven = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonEleven.frame = CGRectMake(SCREEN_WIDTH / 2 - 55, 450, 110, 40);
    [self.buttonEleven setTitle:@"enterAndLeave" forState:UIControlStateNormal];
    [self.buttonEleven setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.buttonEleven.titleLabel.font = [UIFont systemFontOfSize:15];
    self.buttonEleven.backgroundColor = [UIColor blackColor];
    self.buttonEleven.layer.masksToBounds = YES;
    self.buttonEleven.layer.cornerRadius = 6;
    [self.buttonEleven addTarget:self action:@selector(groupEnterAndLeave) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.buttonEleven];
    
    self.buttonTwelve = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonTwelve.frame = CGRectMake(SCREEN_WIDTH - 110, 450, 100, 40);
    [self.buttonTwelve setTitle:@"异步转同步" forState:UIControlStateNormal];
    [self.buttonTwelve setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.buttonTwelve.titleLabel.font = [UIFont systemFontOfSize:15];
    self.buttonTwelve.backgroundColor = [UIColor blackColor];
    self.buttonTwelve.layer.masksToBounds = YES;
    self.buttonTwelve.layer.cornerRadius = 6;
    [self.buttonTwelve addTarget:self action:@selector(semaphoreSync) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.buttonTwelve];
    
    self.buttonThirteen = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonThirteen.frame = CGRectMake(SCREEN_WIDTH / 2 - 55, 510, 110, 40);
    [self.buttonThirteen setTitle:@"线程安全购票" forState:UIControlStateNormal];
    [self.buttonThirteen setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.buttonThirteen.titleLabel.font = [UIFont systemFontOfSize:15];
    self.buttonThirteen.backgroundColor = [UIColor blackColor];
    self.buttonThirteen.layer.masksToBounds = YES;
    self.buttonThirteen.layer.cornerRadius = 6;
    [self.buttonThirteen addTarget:self action:@selector(initTicketsStatus) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.buttonThirteen];
}

/**
 同步串行：
 特点：不会开启新线程，在当前线程执行任务。任务是串行的，执行完一个任务，再执行下一个任务，同步任务需要等待队列的任务执行结束
 */
- (void)syncAndSerial {
    NSLog(@"当前线程：%@", [NSThread currentThread]);
    NSLog(@"begin...");
    //串行队列
    dispatch_queue_t serialQueue = dispatch_queue_create("com.GCDDemo.mac", DISPATCH_QUEUE_SERIAL);
    
    dispatch_sync(serialQueue, ^{
        //追加任务1
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务1：%d->%@", i, [NSThread currentThread]);
        }
    });
    
    dispatch_sync(serialQueue, ^{
        //追加任务2
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务2：%d->%@", i, [NSThread currentThread]);
        }
    });
    
    dispatch_sync(serialQueue, ^{
        //追加任务3
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务3：%d->%@", i, [NSThread currentThread]);
        }
    });
    
    NSLog(@"end...");
}

/**
 同步并发：
 特点：在当前线程中执行任务，不会开启新线程，执行完一个任务，再执行下一个任务，同步任务需要等待队列的任务执行结束。
 */
- (void)syncAndConcurrent {
    NSLog(@"当前线程：%@", [NSThread currentThread]);
    NSLog(@"begin...");
    //并发队列
    dispatch_queue_t concurrentQueue = dispatch_queue_create("com.GCDDemo.mac", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_sync(concurrentQueue, ^{
        //追加任务1
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务1：%d->%@", i, [NSThread currentThread]);
        }
    });
    
    dispatch_sync(concurrentQueue, ^{
        //追加任务2
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务2：%d->%@", i, [NSThread currentThread]);
        }
    });
    
    dispatch_sync(concurrentQueue, ^{
        //追加任务3
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务3：%d->%@", i, [NSThread currentThread]);
        }
    });
    
    NSLog(@"end...");
}

/**
 异步串行：
 特点：会开启新线程，但是因为任务是串行的，执行完一个任务，再执行下一个任务，异步执行不会做任何等待，可以继续执行任务
 */
- (void)asyncAndSerial {
    NSLog(@"当前线程：%@", [NSThread currentThread]);
    NSLog(@"begin...");
    //串行队列
    dispatch_queue_t serialQueue = dispatch_queue_create("com.GCDDemo.mac", DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(serialQueue, ^{
        //追加任务1
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务1：%d->%@", i, [NSThread currentThread]);
        }
    });
    
    dispatch_async(serialQueue, ^{
        //追加任务2
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务2：%d->%@", i, [NSThread currentThread]);
        }
    });
    
    dispatch_async(serialQueue, ^{
        //追加任务3
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务3：%d->%@", i, [NSThread currentThread]);
        }
    });
    
    NSLog(@"end...");
}

/**
 异步并发：
 特点：可以开启多个线程，任务交替（同时）执行，异步执行具备开启新线程的能力。且并发队列可开启多个线程，同时执行多个任务
 */
- (void)asyncAndConcurrent {
    NSLog(@"当前线程：%@", [NSThread currentThread]);
    NSLog(@"begin...");
    //并发队列
    dispatch_queue_t concurrentQueue = dispatch_queue_create("com.GCDDemo.mac", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(concurrentQueue, ^{
        //追加任务1
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务1：%d->%@", i, [NSThread currentThread]);
        }
    });
    
    dispatch_async(concurrentQueue, ^{
        //追加任务2
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务2：%d->%@", i, [NSThread currentThread]);
        }
    });
    
    dispatch_async(concurrentQueue, ^{
        //追加任务3
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务3：%d->%@", i, [NSThread currentThread]);
        }
    });
    
    NSLog(@"end...");
}

/**
 主线程调用 同步主队列(互等造成死锁)
 由于mainThreadSyncAndMainQueue是在主线程中执行的，相当于把mainThreadSyncAndMainQueue任务放到了主线程的队列中，当添加任务1、2、3到主队列中后，由于同步执行会等待当前队列中的任务执行完毕，才会接着执行，所以任务1会等待先执行的mainThreadSyncAndMainQueue执行结束才会执行，而mainThreadSyncAndMainQueue又要等任务1执行完才往下执行，所以造成互等死锁现象，程序无法正常往下执行，造成崩溃
 */
- (void)mainThreadSyncAndMainQueue {
    NSLog(@"当前线程：%@", [NSThread currentThread]);
    NSLog(@"begin...");
    
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    
    dispatch_sync(mainQueue, ^{
        //追加任务1
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务1：%d->%@", i, [NSThread currentThread]);
        }
    });
    
    dispatch_sync(mainQueue, ^{
        //追加任务2
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务2：%d->%@", i, [NSThread currentThread]);
        }
    });
    
    dispatch_sync(mainQueue, ^{
        //追加任务3
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务3：%d->%@", i, [NSThread currentThread]);
        }
    });
    
    NSLog(@"end...");
}

/**
 其他线程调用 同步主队列
 由于这时mainThreadSyncAndMainQueue不在主线程执行了，在执行任务1时，由于主线程中此时没有其他任务正在执行，所以会直接执行任务1，让后一次执行任务2、任务3
 */
- (void)otherThreadSyncAndMainQueue {
    //使用 NSThread 的 detachNewThreadSelector 方法会创建线程，并自动启动线程执行selector 任务
    [NSThread detachNewThreadSelector:@selector(mainThreadSyncAndMainQueue) toTarget:self withObject:nil];
}

/**
 异步主队列
 只在主线程中执行任务，执行完一个任务，再执行下一个任务
 */
- (void)asyncAndMainQueue {
    NSLog(@"当前线程：%@", [NSThread currentThread]);
    NSLog(@"begin...");
    
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    
    dispatch_async(mainQueue, ^{
        //追加任务1
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务1：%d->%@", i, [NSThread currentThread]);
        }
    });
    
    dispatch_async(mainQueue, ^{
        //追加任务2
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务2：%d->%@", i, [NSThread currentThread]);
        }
    });
    
    dispatch_async(mainQueue, ^{
        //追加任务3
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务3：%d->%@", i, [NSThread currentThread]);
        }
    });
    
    NSLog(@"end...");
}

/**
 栅栏:dispatch_barrier_async
 */
- (void)barrier {
    NSLog(@"当前线程：%@", [NSThread currentThread]);
    NSLog(@"begin...");
    
    dispatch_queue_t queue = dispatch_queue_create("com.GCDDemo.mac", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(queue, ^{
        //追加任务1
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务1：%d->%@", i, [NSThread currentThread]);
        }
    });
    
    dispatch_async(queue, ^{
        //追加任务2
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务2：%d->%@", i, [NSThread currentThread]);
        }
    });
    
    dispatch_barrier_async(queue, ^{
        for (int i = 0; i < 2; ++i) {
            [NSThread sleepForTimeInterval:2];              // 模拟耗时操作
            NSLog(@"barrier---%@",[NSThread currentThread]);// 打印当前线程
        }
    });
    
    dispatch_async(queue, ^{
        //追加任务3
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务3：%d->%@", i, [NSThread currentThread]);
        }
    });
    
    dispatch_async(queue, ^{
        //追加任务4
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务4：%d->%@", i, [NSThread currentThread]);
        }
    });
    
    NSLog(@"end...");
}

/**
 dispatch_group_notify
 */
- (void)notify {
    NSLog(@"当前线程：%@", [NSThread currentThread]);
    NSLog(@"begin...");
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //追加任务1
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务1：%d->%@", i, [NSThread currentThread]);
        }
    });
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //追加任务2
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务2：%d->%@", i, [NSThread currentThread]);
        }
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"前面的耗时操作执行完毕");
    });
    
    NSLog(@"end...");
}

- (void)wait {
    NSLog(@"当前线程：%@", [NSThread currentThread]);
    NSLog(@"begin...");
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //追加任务1
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务1：%d->%@", i, [NSThread currentThread]);
        }
    });
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //追加任务2
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务2：%d->%@", i, [NSThread currentThread]);
        }
    });
    
    //等待上面的任务全部完成后，会往下继续执行（会阻塞当前线程）
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    NSLog(@"end...");
}

- (void)groupEnterAndLeave {
    NSLog(@"当前线程：%@", [NSThread currentThread]);
    NSLog(@"begin...");
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        //追加任务1
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务1：%d->%@", i, [NSThread currentThread]);
        }
        dispatch_group_leave(group);
    });
    
    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        //追加任务2
        for (int i=0; i < 2; i++) {
            [NSThread sleepForTimeInterval:1.0];
            NSLog(@"任务2：%d->%@", i, [NSThread currentThread]);
        }
        dispatch_group_leave(group);
    });
    
    dispatch_group_notify(group, queue, ^{
        NSLog(@"前面的耗时操作执行完毕");
    });
    
//    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    NSLog(@"end...");
}

/**
 信号量为0，等待，阻塞线程
 信号量Dispatch Semaphore保持线程同步，将异步执行任务转换为同步执行任务
 */
- (void)semaphoreSync {
    NSLog(@"当前线程：%@", [NSThread currentThread]);
    NSLog(@"begin...");
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //创建一个semaphore，并初始化信号量
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block int number = 0;
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:1.0];
        NSLog(@"%@", [NSThread currentThread]);
        number = 100;
        dispatch_semaphore_signal(semaphore);
    });
    //信号量减1
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    NSLog(@"end...%d", number);
}

/**
 信号量Dispatch Semaphore保证线程按钮和线程同步(为线程加锁)
 */
- (void)initTicketsStatus {
    NSLog(@"当前线程：%@", [NSThread currentThread]);
    NSLog(@"begin...");
    
    self.semaphore = dispatch_semaphore_create(1);
    self.ticketSurplusCount = 50;
    
    dispatch_queue_t queue1 = dispatch_queue_create("com.GCDDemo.mac", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t queue2 = dispatch_queue_create("com.GCDDemo.mac", DISPATCH_QUEUE_SERIAL);
    __weak typeof(self) weakSelf = self;
    dispatch_async(queue1, ^{
        [weakSelf saleTickets];
    });
    
    dispatch_async(queue2, ^{
        [weakSelf saleTickets];
    });
    NSLog(@"end...");
}

- (void)saleTickets {
    while (1) {
        //相当于加锁
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        if (self.ticketSurplusCount > 0) {
            self.ticketSurplusCount--;
            NSLog(@"剩余：%d张票", self.ticketSurplusCount);
        }else {
            NSLog(@"票已卖完");
            //相当于解锁,信号量加1
            dispatch_semaphore_signal(self.semaphore);
            break;
        }
        //相当于解锁,信号量加1
        dispatch_semaphore_signal(self.semaphore);
    }
}

- (void)aaa {
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
