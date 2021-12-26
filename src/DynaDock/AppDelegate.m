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


unsigned long loop, page, flip, data[10];
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

    NSString *tmps = [self windDirs:dirNum];
    NSMutableArray *windList = [pages objectAtIndex:1];
    NSString *windStrs = [windList objectAtIndex:1];

    NSLog(@"wind:[%@][%@]", dirNum, tmps);

    zero = ([windStrs length] < 1);
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
    tmps = [NSString stringWithCString:buff encoding:NSASCIIStringEncoding];
    if (zero || (![tmps isEqualTo:dayStr])) {
        [dateList replaceObjectAtIndex:0 withObject:tmps];
        flag = 1;
    }

    bzero(buff, 32);
    strftime(buff, 16, "%m", pntr);
    zero = ([monStr length] < 1);
    tmps = [NSString stringWithCString:buff encoding:NSASCIIStringEncoding];
    if (zero || (![tmps isEqualTo:monStr])) {
        [dateList replaceObjectAtIndex:1 withObject:tmps];
        flag = 1;
    }

    if (flag == 1) {
        page = 0;
        [self timeLoop:nil];
    }
}


- (void)procData:(NSData *)data {
    NSString *dataStr = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding];
    dataStr = [dataStr stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    dataStr = [dataStr stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    dataStr = [dataStr stringByReplacingOccurrencesOfString:@"," withString:@"\n"];

    NSArray *dataList = [dataStr componentsSeparatedByString:@"\n"];
    for (int i = 0; i < [dataList count]; ++i) {
        NSString *lineStr = [dataList objectAtIndex:i];
        if ([lineStr rangeOfString:@"wind_direction"].location != NSNotFound) {
            NSRegularExpression *strRegex = [NSRegularExpression regularExpressionWithPattern:@"wind_direction[^:]*:([0-9]+)" options:NSRegularExpressionCaseInsensitive error:nil];
            NSArray *matchList = [strRegex matchesInString:lineStr options:0 range:NSMakeRange(0, [lineStr length])];
            for (NSTextCheckingResult *matchItem in matchList) {
                NSRange matchRange = [matchItem rangeAtIndex:1];
                NSString *matchStr = [lineStr substringWithRange:matchRange];

                [self procWind:matchStr];
            }
        }
    }
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


- (void)procDock:(NSString *)nssa overFile:(NSString *)nssb {
    NSURL *appf = [[NSBundle mainBundle] bundleURL];

    NSString *strs = [[appf path] stringByAppendingString:@"/Contents/Resources/data/%buff%.png"];
    NSString *stra = [strs stringByReplacingOccurrencesOfString:@"%buff%" withString:nssa];
    NSString *strb = [strs stringByReplacingOccurrencesOfString:@"%buff%" withString:nssb];

    CIImage *imga = [CIImage imageWithContentsOfURL:[NSURL fileURLWithPath:stra]];
    CIImage *imgb = [CIImage imageWithContentsOfURL:[NSURL fileURLWithPath:strb]];
    CIImage *imgf = [imga imageByCompositingOverImage:imgb];

    NSCIImageRep *imgr = [NSCIImageRep imageRepWithCIImage:imgf];
    NSImage *imgo = [[NSImage alloc] initWithSize:imgr.size];
    [imgo addRepresentation:imgr];

    [NSApp setApplicationIconImage:imgo];
}


- (void)getWeb:(NSString *)urlStr {
    NSLog(@"getWeb:[%@]",urlStr);

    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:11];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *erro) {
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
        if ((http.statusCode == 200) && data && ([data length] > 0)) {
            [self procData:data];
        }
    }];

    [task resume];
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


- (int)windLoop:(NSTimer *)timeObj {
    return [self dataLoop:1];
}


- (int)dateLoop:(NSTimer *)timeObj {
    return [self dataLoop:0];
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
            //NSLog(@"loop:[%ld][%ld]",secs,page);
            NSString *nssa = [NSString stringWithCString:bufa encoding:NSASCIIStringEncoding];
            NSString *nssb = [NSString stringWithCString:bufb encoding:NSASCIIStringEncoding];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self procDock:nssa overFile:nssb];
            });
        }

        page = ((page + 1) % plen);
        loop = secs;
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
    loop = 0; page = 0; flip = 0;
    data[0] = dsec; data[1] = dsec;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self.winw orderOut:self];
    [self initProc];
    [self dateLoop:nil];

    [NSTimer scheduledTimerWithTimeInterval:9.0 target:self selector:@selector(windLoop:) userInfo:nil repeats:YES];
    [NSTimer scheduledTimerWithTimeInterval:6.0 target:self selector:@selector(dateLoop:) userInfo:nil repeats:YES];
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
        flip += 1;
    } else if (flip == 1) {
        [self.winw makeKeyAndOrderFront:self];
        flip += 1;
    } else if (flip == 2) {
        system("open -a Calendar");
        flip += 1;
    }

    return NO;
}


@end
