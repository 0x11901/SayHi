%config(generator=internal)

    // You don't need to #include <substrate.h>, it will be done automatically, as will
    // the generation of a class list and an automatic constructor.


#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

    %hook ViewController


    // Hooking an instance method with an argument.
    - (void)sayHi:(id)argument {
            NSAlert *r15 = [[NSAlert alloc] init];
                [r15 setMessageText:@"hello world!"];
                    [r15 setAlertStyle:0x1];
                        [r15 runModal];
    }



// Always make sure you clean up after yourself; Not doing so could have grave consequences!
%end

%ctor {
        NSLog(@"!!!!!!inject success!!!!!!!");
}
