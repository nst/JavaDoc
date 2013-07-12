//
//  JavaDoc.h
//  SimplePlugin
//
//  Created by Nicolas Seriot on 10.05.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface JavaDoc : NSObject {
	Boolean isJavaDocInstalled;
	NSMetadataQuery *query;
	NSMutableDictionary *dict;
	NSString *browser;
	NSString *prefsPath;
	NSArray *searchPaths;

	BOOL parsingFinished;	
}

- (void) initialize;
- (BOOL) isJavaDocInstalled;
- (BOOL) parsingIsFinished;
- (void) fillDictionary;
- (void) addClasses:(NSString *)filePath;

- (NSArray *) filePathForClass:(NSString *)aClass;
- (NSString *) browserBundleId;

- (void) logMessage:(NSString *)str;
- (BOOL) openDocForClass:(NSString *)aClass;

@end
