/* How to Hook with Logos
Hooks are written with syntax similar to that of an Objective-C @implementation.
You don't need to #include <substrate.h>, it will be done automatically, as will
the generation of a class list and an automatic constructor.

%hook ClassName

// Hooking a class method
+ (id)sharedInstance {
	return %orig;
}

// Hooking an instance method with an argument.
- (void)messageName:(int)argument {
	%log; // Write a message about this call, including its class, name and arguments, to the system log.

	%orig; // Call through to the original function with its original arguments.
	%orig(nil); // Call through to the original function with a custom argument.

	// If you use %orig(), you MUST supply all arguments (except for self and _cmd, the automatically generated ones.)
}

// Hooking an instance method with no arguments.
- (id)noArguments {
	%log;
	id awesome = %orig;
	[awesome doSomethingElse];

	return awesome;
}

// Always make sure you clean up after yourself; Not doing so could have grave consequences!
%end
*/


%config(generator = internal)

#import <Foundation/Foundation.h>
#include <substrate.h>

%hook DownLoadTask

- (BOOL)checkHaveRightToDownload:(int)argument {
	return YES;
}

%end

unsigned int (*old_GetFlexBOOL)(int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8);
unsigned int  new_GetFlexBOOL(int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8)
{
  return 1;
}

%ctor {
    NSLog(@"!!!!!!inject success!!!!!!!");

    void * Symbol = MSFindSymbol(MSGetImageByName("/Applications/QQMusic.app/Contents/MacOS/QQMusic"), "_GetFlexBOOL");
    MSHookFunction(Symbol, &new_GetFlexBOOL, (void *)&old_GetFlexBOOL);
}