#import "MyPluginClass.h"
#import <WebKit/WebKit.h>

#define DEBUG 0

@implementation MyPluginClass

#pragma mark WidgetPlugin protocol

// Called the first time the widget plugin is loaded
-(id)initWithWebView:(WebView*)w {
	[self logMessage:@"Entering -initWithWebView"];

	self = [super init];
	
	javaDoc = [[JavaDoc alloc] init];
	[javaDoc initialize];
	
	if([javaDoc isJavaDocInstalled]) {
		[self logMessage:@"JavaDoc installed"];		
		[javaDoc fillDictionary];
	} else {
		[self logMessage:@"JavaDoc not installed"];
	}
	
	[self logMessage:@"javaDoc object has been initialized"];
	
	return self;
}

-(void)dealloc {
	[super dealloc];
}

#pragma mark WebScripting protocol

// This method gives you the object that you use to bridge between the
// Obj-C world and the JavaScript world.  Use setValue:forKey: to give
// the object the name it's refered to in the JavaScript side.
-(void)windowScriptObjectAvailable:(WebScriptObject*)wso {
	[self logMessage:@"windowScriptObjectAvailable"];
	[wso setValue:self forKey:@"JavaDocPlugin"];
}

// This method lets you offer friendly names for methods that normally get mangled when bridged into JavaScript.
+(NSString*)webScriptNameForSelector:(SEL)aSel {
	NSString *retval = nil;
	
	if (aSel == @selector(getFortune)) {
		retval = @"getFortune";
	} else if (aSel == @selector(parsingIsFinished)) {
		retval = @"parsingIsFinished";
	} else if (aSel == @selector(javaDocIsInstalled)) {
		retval = @"javaDocIsInstalled";
	} else if (aSel == @selector(logMessage:)) {
		retval = @"logMessage";
	} else if (aSel == @selector(openDocForClass:)) {
		retval = @"openDocForClass";
	} else if (aSel == @selector(filePath:)) {
		retval = @"filePath";
	} else if (aSel == @selector(browserBundleId)) {
		retval = @"browserName";
	} else {
		//NSLog(@"\tunknown selector");
	}
	
	return retval;
}

// This method lets you filter which methods in your plugin are accessible to the JavaScript side.
+(BOOL)isSelectorExcludedFromWebScript:(SEL)aSel {	
	if (aSel == @selector(getFortune) ||
		aSel == @selector(logMessage:) ||
		aSel == @selector(filePath:) ||
		aSel == @selector(browserBundleId) ||
        aSel == @selector(openDocForClass:) ||
		aSel == @selector(parsingIsFinished) ||
		aSel == @selector(javaDocIsInstalled)) {
		return NO;
	}
	return YES;
}

// Prevents direct key access from JavaScript.
+(BOOL)isKeyExcludedFromWebScript:(const char*)k {
	return YES;
}

- (NSString *) browserBundleId {
	return [[[javaDoc browserBundleId] retain] autorelease];
}

- (NSString *) openDocForClass:(NSString *)aClass {
	BOOL success = [javaDoc openDocForClass:aClass];
    return success ? @"YES" : @"NO";
}

- (NSString *) javaDocIsInstalled {
	return ([javaDoc isJavaDocInstalled]) ? @"YES" : @"NO";
}

- (NSString *) parsingIsFinished {
	return ([javaDoc parsingIsFinished]) ? @"YES" : @"NO";
}

// Sends the message passed in from JavaScript to the console.
- (void) logMessage:(NSString *)str {
	if(DEBUG) {
		NSLog(@"logMessage -- %@", str);
	}
}

@end
