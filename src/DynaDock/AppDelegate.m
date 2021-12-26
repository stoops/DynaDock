//
//  AppDelegate.m
//  DynaDock
//
//  Created by jon on 2021-12-25.
//

#import "AppDelegate.h"

#import <CoreImage/CoreImage.h>

@interface AppDelegate ()

@property (strong) IBOutlet NSWindow *winw;
@property (strong) IBOutlet NSTextField *wtxt;
@property (strong) IBOutlet NSPopUpButton *wpop;

@end

@implementation AppDelegate


#define SHOWS 0


int flip;
unsigned long loop, page, data[10];
unsigned long lsec, lopt, dsec;
NSMutableArray *pages;


- (NSString *)windDirs:(NSString *)windStr {
    int z = 8, e = 0, n = 340;
    int d = (360 / z);
    int m = ((n + d) - 360);
    NSInteger windNum = [windStr intValue];
    NSArray *l = @[@"ss", @"sw", @"ww", @"nw", @"nn", @"ne", @"ee", @"se"];
    for (int x = 0; x < z; ++x) {
        if (x == 0) {
            if ((n <= windNum) || (windNum < (m + e))) { return [l objectAtIndex:x]; }
        } else {
            if ((m <= windNum) && (windNum < (m + e))) { return [l objectAtIndex:x]; }
        }
        m += e; e = d;
    }
    return @"zz";
}


- (void)procWind:(NSString *)dirNum {
    int zero, flag = 0;
    NSString *tmps;
    NSMutableArray *windList = [pages objectAtIndex:1];
    NSString *windStrs = [windList objectAtIndex:1];

    zero = ([windStrs length] < 1);
    tmps = [self windDirs:dirNum];
    NSLog(@"wind:[%@][%@]",dirNum,tmps);
    if (zero || (![tmps isEqualTo:windStrs])) {
        [windList replaceObjectAtIndex:1 withObject:tmps];
        flag = 1;
    }

    if ((!zero) && (flag == 1)) {
        page = 1;
        [self timeLoop:nil];
    }
}


- (void)procDate {
    int zero, flag = 0;
    char buff[96];
    time_t secs = time(NULL);
    struct tm *pntr = localtime(&secs);
    NSString *tmps;
    NSMutableArray *dateList = [pages objectAtIndex:0];
    NSString *dayStr = [dateList objectAtIndex:0];
    NSString *monStr = [dateList objectAtIndex:1];

    bzero(buff, 32);
    strftime(buff, 16, "%d", pntr);
    zero = ([dayStr length] < 1);
    tmps = [[NSString alloc] initWithUTF8String:buff];
    if (zero || (![tmps isEqualTo:dayStr])) {
        [dateList replaceObjectAtIndex:0 withObject:tmps];
        flag = 1;
    }

    bzero(buff, 32);
    strftime(buff, 16, "%m", pntr);
    zero = ([monStr length] < 1);
    tmps = [[NSString alloc] initWithUTF8String:buff];
    if (zero || (![tmps isEqualTo:monStr])) {
        [dateList replaceObjectAtIndex:1 withObject:tmps];
        flag = 1;
    }

    if (flag == 1) {
        page = 0;
        [self timeLoop:nil];
    }
}


- (void)getWeb:(NSString *)urlStr {
    NSURLSession *urlSes = [NSURLSession sharedSession];
    NSMutableURLRequest *urlReq = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlStr]];

    NSLog(@"getWeb:[%@]",urlStr);
    [urlReq setHTTPMethod:@"GET"];

    NSURLSessionDataTask *dataTask = [urlSes dataTaskWithRequest:urlReq completionHandler:^(NSData *data, NSURLResponse *resp, NSError *erro)
    {
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)resp;
        if (httpResp.statusCode == 200)
        {
            NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            dataStr = [dataStr stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            dataStr = [dataStr stringByReplacingOccurrencesOfString:@"<" withString:@"\n<"];
            NSArray *dataList = [dataStr componentsSeparatedByString:@"\n"];
            for (int i = 0; i < [dataList count]; ++i) {
                NSString *strItem = [dataList objectAtIndex:i];
                if ([strItem rangeOfString:@"name=\"wind-direction\""].location != NSNotFound) {
                    //NSLog(@"lineItem:[%d][%@]",i,strItem);
                    NSRegularExpression *strRegex = [NSRegularExpression regularExpressionWithPattern:@"transform:rotate.([0-9]+)" options:NSRegularExpressionCaseInsensitive error:nil];
                    NSArray *matchList = [strRegex matchesInString:strItem options:0 range:NSMakeRange(0, [strItem length])];
                    for (NSTextCheckingResult *matchItem in matchList) {
                        NSRange matchRange = [matchItem rangeAtIndex:1];
                        NSString *matchStr = [strItem substringWithRange:matchRange];
                        [self procWind:matchStr];
                    }
                }
            }
        }
    }];

    [dataTask resume];
}


- (int)dataLoop:(int)mode {
    time_t secs = time(NULL);
    NSMutableArray *windList = [pages objectAtIndex:1];
    NSString *windLink = [windList objectAtIndex:0];

    if (SHOWS != 0) { return 1; }
    if (mode == 0) {
        [self procDate];
    }

    if (dsec < 1) { return 1; }
    if ((secs - data[mode]) > dsec) {
        if (mode == 1) {
            if ([windLink length] > 0) {
                [self getWeb:windLink];
            }
        }

        data[mode] = secs;
    }

    return 0;
}


- (int)dataDate:(NSTimer *)timeObj {
    [self dataLoop:0];
    return 0;
}


- (int)dataWind:(NSTimer *)timeObj {
    [self dataLoop:1];
    return 0;
}


- (int)procPref:(int)mode {
    int outp = 0;
    long snum;
    NSString *strs;
    NSUserDefaults *pref = [NSUserDefaults standardUserDefaults];
    NSMutableArray *windList = [pages objectAtIndex:1];
    NSString *windLink = [windList objectAtIndex:0];

    if (SHOWS != 0) { return 1; }

    if (mode == 0) {
        strs = [pref stringForKey:@"refresh"];
        if ([strs length] > 0) {
            NSLog(@"initPref:[%@]",strs);
            lopt = [strs intValue];
            [self.wpop selectItemAtIndex:lopt];
            lsec = [[self.wpop titleOfSelectedItem] intValue];
        }

        strs = [pref stringForKey:@"weather"];
        if ([strs length] > 0) {
            NSLog(@"initPref:[%@]",strs);
            [self.wtxt setStringValue:strs];
            [windList replaceObjectAtIndex:0 withObject:strs];
        }
    }

    if (mode == 1) {
        snum = [self.wpop indexOfSelectedItem];
        if (snum != lopt) {
            NSLog(@"savePref:[%ld]->[%ld]",lopt,snum);
            lopt = snum;
            lsec = [[self.wpop titleOfSelectedItem] intValue];
            strs = [NSString stringWithFormat:@"%ld",snum];
            [pref setObject:strs forKey:@"refresh"];
            outp = 1;
        }

        strs = [self.wtxt stringValue];
        if (([strs length] > 0) && (([windLink length] < 1) || (![windLink isEqualToString:strs]))) {
            NSLog(@"savePref:[%@]->[%@]",windLink,strs);
            data[0] = dsec; data[1] = dsec;
            [windList replaceObjectAtIndex:0 withObject:strs];
            [windList replaceObjectAtIndex:1 withObject:@""];
            [pref setObject:strs forKey:@"weather"];
            outp = 1;
        }
    }

    if (outp != 0) {
        [pref synchronize];
    }

    return 0;
}


- (int)timeLoop:(NSTimer *)timeObj {
    char bufa[96], bufb[96];
    time_t secs = time(NULL);
    unsigned long plen = [pages count];
    NSMutableArray *dateList = [pages objectAtIndex:0];
    NSMutableArray *windList = [pages objectAtIndex:1];

    flip = 0;
    if (timeObj != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self procPref:1];
        });
    }

    if ((timeObj != nil) && (lsec < 1)) { return 1; }
    if ((timeObj == nil) || ((secs - loop) > lsec)) {
        // C
        bzero(bufa, 90); bzero(bufb, 90);

        if (page == 0) {
            NSString *dayn = [dateList objectAtIndex:0];
            NSString *monn = [dateList objectAtIndex:1];
            if ([dayn length] > 0) {
                snprintf(bufa, 32, "cal/cd_%s", [dayn UTF8String]);
                snprintf(bufb, 32, "cal/cm_%s", [monn UTF8String]);
            }
        }

        if (page == 1) {
            NSString *wdir = [windList objectAtIndex:1];
            if ([wdir length] > 0) {
                snprintf(bufa, 32, "wind/%s", [wdir UTF8String]);
                snprintf(bufb, 32, "wind/wind");
            }
        }

        if (bufa[0] != 0) {
            // X
            NSString *nssa = [[NSString alloc] initWithCString:bufa encoding:NSASCIIStringEncoding];
            NSString *nssb = [[NSString alloc] initWithCString:bufb encoding:NSASCIIStringEncoding];
            // OBJC
            NSURL *appf = [[NSBundle mainBundle] bundleURL];
            NSString *strs = [[appf path] stringByAppendingString:@"/Contents/Resources/data/%buff%.png"];
            NSString *stra = [strs stringByReplacingOccurrencesOfString:@"%buff%" withString:nssa];
            NSString *strb = [strs stringByReplacingOccurrencesOfString:@"%buff%" withString:nssb];
            CIImage *imga = [[CIImage alloc] initWithContentsOfURL:[NSURL fileURLWithPath:stra]];
            CIImage *imgb = [[CIImage alloc] initWithContentsOfURL:[NSURL fileURLWithPath:strb]];
            CIImage *imgf = [imga imageByCompositingOverImage:imgb];
            NSCIImageRep *imgr = [NSCIImageRep imageRepWithCIImage:imgf];
            NSImage *imgo = [[NSImage alloc] initWithSize:imgr.size];
            [imgo addRepresentation:imgr];
            // UI
            //NSLog(@"loop:[%ld][%ld]",secs,page);
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSApp setApplicationIconImage:imgo];
            });
        }

        page = ((page + 1) % plen);

        if (timeObj != nil) {
            loop = secs;
        }
    }

    return 0;
}


- (void)initProc {
    // INI
    NSMutableArray *dateList = [NSMutableArray arrayWithCapacity:2];
    NSMutableArray *windList = [NSMutableArray arrayWithCapacity:2];
    pages = [NSMutableArray arrayWithCapacity:2];
    [dateList addObject:@""]; [dateList addObject:@""];
    [windList addObject:@""]; [windList addObject:@""];
    [pages addObject:dateList]; [pages addObject:windList];
    // VAR
    lsec = 15; lopt = 1; dsec = 900;
    // FUN
    [self procPref:0];
    // END
    loop = lsec; page = 0;
    data[0] = dsec; data[1] = dsec;
    flip = 0;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [self.winw orderOut:self];
    [self initProc];
    [self dataDate:nil];
    [NSTimer scheduledTimerWithTimeInterval:9.0 target:self selector:@selector(dataWind:) userInfo:nil repeats:YES];
    [NSTimer scheduledTimerWithTimeInterval:6.0 target:self selector:@selector(dataDate:) userInfo:nil repeats:YES];
    [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(timeLoop:) userInfo:nil repeats:YES];
    if (SHOWS != 0) {
        NSMutableArray *dateList = [pages objectAtIndex:0];
        NSMutableArray *windList = [pages objectAtIndex:1];
        [dateList replaceObjectAtIndex:0 withObject:@"01"];
        [dateList replaceObjectAtIndex:1 withObject:@"01"];
        [windList replaceObjectAtIndex:1 withObject:@"ne"];
    }
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}


- (BOOL)applicationShouldHandleReopen:(NSApplication *)app hasVisibleWindows:(BOOL)flag {
    if (flip == 0) {
        [self timeLoop:nil];
        flip = 1;
    } else {
        [self.winw makeKeyAndOrderFront:self];
        //flip = 0;
    }
    return NO;
}


@end
