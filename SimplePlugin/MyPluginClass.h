#import <Cocoa/Cocoa.h>
#import "JavaDoc.h"

@interface MyPluginClass : NSObject {	
	JavaDoc *javaDoc;
}

- (void) logMessage:(NSString *)str;
- (NSString *) openDocForClass:(NSString *)aClass;

@end
