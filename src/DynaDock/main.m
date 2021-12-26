//
//  main.m
//  DynaDock
//
//  Created by jon on 2021-12-25.
//

#import <Cocoa/Cocoa.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
    }
    NSURL *appf = [[NSBundle mainBundle] bundleURL];
    NSString *strs = [[appf path] stringByAppendingString:@"/Contents/Resources/data/src/icon.png"];
    while (access([strs UTF8String], F_OK) != 0) {
        sleep(5);
    }
    return NSApplicationMain(argc, argv);
}
