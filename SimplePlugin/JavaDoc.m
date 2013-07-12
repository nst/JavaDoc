//
//  JavaDoc.m
//  SimplePlugin
//
//  Created by Nicolas Seriot on 10.05.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "JavaDoc.h"

#define DEBUG 0

@implementation JavaDoc

- (void) setUpPrefs {
	// install file to remove quarantine on html files
	NSString *fromPath = [@"~/Library/Widgets/JavaDoc.wdgt/SimplePlugin.widgetplugin/Contents/Resources/com.apple.DownloadAssessment.plist" stringByExpandingTildeInPath];
	NSString *toPath = [@"~/Library/Preferences/com.apple.DownloadAssessment.plist" stringByExpandingTildeInPath];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir = NO;
	
	if(![fm fileExistsAtPath:toPath isDirectory:&isDir]) {
		[fm copyPath:fromPath toPath:toPath handler:nil];
	}
	
    // TODO use NSUserDefaults to manage preferences

	// config file path
	prefsPath = @"~/Library/Preferences/ch.seriot.widget.JavaDoc.plist";
    
    // set up the prefs
	NSMutableDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:[prefsPath stringByExpandingTildeInPath]];
	
	NSString *leo142 = @"/Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.Java15APIReference.docset/Contents/Resources/Documents/documentation/Java/Reference/1.4.2/doc/api/";
	NSString *leo150 = @"/Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.Java15APIReference.docset/Contents/Resources/Documents/documentation/Java/Reference/1.5.0/doc/api/";
	NSString *leo150bis = @"/Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.J2SE50APIReference.docset/Contents/Resources/Documents/documentation/Java/Reference/1.5.0/doc/api/";

	NSMutableArray *op = [[prefs valueForKey:@"searchPaths"] mutableCopy];
	NSString *preferedBrowser = [prefs valueForKey:@"browser"];
	
	BOOL updatePrefs = NO;
	
	if(![op containsObject:leo142]) {
		[op addObject:leo142];
		updatePrefs = YES;
	}
	if(![op containsObject:leo150]) {
		[op addObject:leo150];
		updatePrefs = YES;
	}
	if(![op containsObject:leo150bis]) {
		[op addObject:leo150bis];
		updatePrefs = YES;
	}
	
	if(updatePrefs) {
		[prefs setObject:op forKey:@"searchPaths"];
		if(preferedBrowser) {
			[prefs setObject:preferedBrowser forKey:@"browser"];
		} else {
			[prefs setObject:@"com.apple.safari" forKey:@"browser"];
		}
		[prefs writeToFile:[prefsPath stringByExpandingTildeInPath] atomically: TRUE];
	}
	
	[op release];
	
	// create the prefs if they do not exist yet
    if (prefs == nil)  {		
		NSArray *originalPaths = [NSArray arrayWithObjects:
			@"/System/Library/Frameworks/JavaVM.framework/Versions/1.6.0/Resources/Documentation/Reference/doc/api/",
			@"/System/Library/Frameworks/JavaVM.framework/Versions/1.5.0/Resources/Documentation/Reference/doc/api/",
			@"/System/Library/Frameworks/JavaVM.framework/Versions/1.4.2/Resources/Documentation/Reference/doc/api/",
			leo142, leo150, leo150bis, nil];
		
		prefs = [[NSMutableDictionary alloc] init];
		[prefs setObject:originalPaths forKey:@"searchPaths"];
        [prefs setObject:@"com.apple.safari" forKey:@"browser"];
		[prefs writeToFile:[prefsPath stringByExpandingTildeInPath] atomically: TRUE];
    }
    
    // update the prefs is we have an old version
    BOOL old_version = ([prefs objectForKey:@"browser"] == nil);
    if (old_version) {
        [self logMessage:@"old version"];
		
		[prefs setObject:@"com.apple.safari" forKey:@"browser"];
		[prefs writeToFile:[prefsPath stringByExpandingTildeInPath] atomically: TRUE];
    }
    
	// now that we have set up preferences, set the local variables
	NSArray *prefsPaths = [prefs objectForKey:@"searchPaths"];
	NSMutableArray *tiledExpandedSearchPaths = [NSMutableArray array];
	int i;
	for(i = 0; i < [prefsPaths count]; i++){
		[tiledExpandedSearchPaths addObject:[[prefsPaths objectAtIndex:i] stringByExpandingTildeInPath]];
	}
	
	[self logMessage:[NSString stringWithFormat:@"---------------------- %@", tiledExpandedSearchPaths]];
	
	searchPaths = [tiledExpandedSearchPaths retain];
    browser = [[prefs objectForKey:@"browser"] retain];
	
	[self logMessage:[NSString stringWithFormat:@"read searchPaths : %@", [searchPaths description]]];
	[self logMessage:[NSString stringWithFormat:@"read browser : %@", browser]];
}

// called at first instanciation
- (void) initialize {
	[self logMessage:@"*** initialize"];
	
	[self setUpPrefs];
	
	parsingFinished = NO;
	
	// set up the spotlight query
	query = [[NSMetadataQuery alloc] init];
	
	// To watch results send by the query, add an observer to the NSNotificationCenter
	NSNotificationCenter *nf = [NSNotificationCenter defaultCenter];
	[nf addObserver:self selector:@selector(queryNote:) name:nil object:query];
	
	// We want the items in the query to automatically be sorted by the file system name; this way, we don't have to do any special sorting
	[query setSortDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:(id)kMDItemFSName ascending:YES] autorelease]]];
	
	[query setDelegate:self];
	
	// dict[class name] = [[list]]     avec     list : [package name, full path]
	dict = [[NSMutableDictionary alloc] init];
	
    [browser retain];
}

- (BOOL) isJavaDocInstalled {
	
	int i;
	for (i = 0; i < [searchPaths count]; i++) {
		BOOL isDirectory = NO;
		BOOL pathExists = NO;
		NSString *path = [[searchPaths objectAtIndex:i] stringByExpandingTildeInPath];
		pathExists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];

		if(pathExists && isDirectory){
			//NSLog(@"--- isJavaDocInstalled return YES");
			return YES;
		}
	}
	//NSLog(@"--- isJavaDocInstalled return NO");
	return NO;
}

- (BOOL) parsingIsFinished {
	BOOL returnValue = parsingFinished;
	
	if (returnValue) {
		[self logMessage:@"-- pf OUI"];
	} else {
		[self logMessage:@"-- pf NON"];
	}
	
	return returnValue;
}

- (void) fillDictionary {
	// lister tous les fichiers
	NSString *predicateFormat;
	NSPredicate *predicateToRun;
	
	predicateFormat = @"kMDItemFSName == 'package-frame.html'";
	predicateToRun = [NSPredicate predicateWithFormat:predicateFormat];
	
	NSArray *attributes = [NSArray arrayWithObjects:@"kMDItemPath", @"kMDItemFSName", @"kMDItemFSIsReadable", nil];
	
	[query setSearchScopes:searchPaths];
	[query setValueListAttributes:attributes];
	[query setPredicate:predicateToRun];
	[query startQuery];
}

- (void) fillingUpFinishedHandler {
	[query disableUpdates];
	
	unsigned resultCount = [query resultCount];
	// NSLog(@"result count : %d", resultCount);
	
	int i;		
	for(i = 0; i < resultCount; i++) { // iterate for performance reasons
        //NSLog(@"%@", [[query resultAtIndex:i] valueForKeyPath:@"kMDItemPath"] );
		NSString *filePath = [[query resultAtIndex:i] valueForKeyPath:@"kMDItemPath"];
		//NSLog(filePath);
		[self addClasses:filePath];
	}
	
	parsingFinished = YES;
	[self logMessage:@"parsingFinished %d"];
	
}

- (void)queryNote:(NSNotification *)note {
    // The NSMetadataQuery will send back a note when updates are happening. By looking at the [note name], we can tell what is happening
    if ([[note name] isEqualToString:NSMetadataQueryDidStartGatheringNotification]) {
        // The query has just started!
        [self logMessage:@"Started gathering"];
    } else if ([[note name] isEqualToString:NSMetadataQueryDidFinishGatheringNotification]) {
        // At this point, the query will be done. You may recieve an update later on.
        [self logMessage:@"Finished gathering"];
		
		[self fillingUpFinishedHandler];
		
    } else if ([[note name] isEqualToString:NSMetadataQueryGatheringProgressNotification]) {
        // The query is still gatherint results...
        [self logMessage:@"Progressing..."];
    } else if ([[note name] isEqualToString:NSMetadataQueryDidUpdateNotification]) {
        // An update will happen when Spotlight notices that a file as added, removed, or modified that affected the search results.
        [self logMessage:@"An update happened."];
    }
	
}


- (void)addClasses:(NSString *)filePath {
	
	NSString *packageName = nil;
	
	NSArray *lines;
	
    lines = [[NSString stringWithContentsOfFile:filePath] 
                       componentsSeparatedByString:@"\n"];
	
	NSMutableArray *matchingLines = [[NSMutableArray alloc] init];
	
	NSEnumerator *e = [lines objectEnumerator];
	
	NSString *line;
	NSScanner *scanner;
	
	while((packageName == nil) && (line = [e nextObject])) {
		//NSLog(@"mmmmm -- %@", line);
		if([line hasPrefix:@"<A HREF"]) {
			// la première ligne : le nom du paquetage
			//NSLog(@"... %@", line);
			
			scanner = [NSScanner scannerWithString:line];
			[scanner scanUpToString:@"classFrame" intoString:nil];
			[scanner scanString:@"classFrame\">" intoString:nil];
			[scanner scanUpToString:@"</A>" intoString:&packageName];
		}
    }
	
	//NSLog(@"--- package --- %@", packageName);
	
	//id nothing = [e nextObject]; 
	
	while(line = [e nextObject]) {
		if([line hasPrefix:@"<A HREF"]) {
			//[matchingLines addObject:line];
			//NSLog(@"xxx %@", line);
			
			[scanner initWithString:line];
			NSString *className;
			[scanner scanUpToString:@"\"" intoString:nil];
			[scanner scanString:@"\"" intoString:nil];
			[scanner scanUpToString:@".html" intoString:&className];
			//NSLog(className);
			
			//NEW
			NSString *dirPath = [filePath stringByDeletingLastPathComponent];
			NSString *fullPath = [[dirPath stringByAppendingPathComponent:className] stringByAppendingString:@".html"];
			
			NSString *lowClassName = [className lowercaseString];
			
			BOOL classExists = ([dict objectForKey:lowClassName] != nil);
			
			// si the entry does not exist, create it, else add it
			if(!classExists) {
				NSMutableArray *dataToAdd;
				dataToAdd = [NSMutableArray arrayWithObjects:packageName, fullPath, nil];
				[dict setObject:dataToAdd forKey:lowClassName];	
			} else {
				int count = [[dict objectForKey:lowClassName] count];
				[[dict objectForKey:lowClassName] insertObject:packageName atIndex:(count/2)];
				[[dict objectForKey:lowClassName] addObject:fullPath];
			}
		}
    }
}


- (NSArray *) filePathForClass:(NSString *)aClass {
	NSString *lowerClass = [aClass lowercaseString];
	
	NSArray *fullArray = [dict objectForKey:lowerClass];
	
	NSRange range;
	
	range.length = [fullArray count] / 2;
	range.location = [fullArray count] / 2;
	
	return [fullArray subarrayWithRange:range];
}


- (NSString *) browserBundleId {
    return [[browser retain] autorelease];
}

- (BOOL) openDocForClass:(NSString *)aClass {
	NSString *filePath;
	filePath = [[self filePathForClass:aClass] objectAtIndex:0];
	//NSLog(@"------ %@ -----  %@", aClass, filePath);
	
	//[[NSWorkspace sharedWorkspace] openFile:filePath];
    
    NSArray *urls = [NSArray arrayWithObject:[NSURL fileURLWithPath:filePath]];
    
    [[NSWorkspace sharedWorkspace] openURLs:urls
                    withAppBundleIdentifier:browser
                                    options:NSWorkspaceLaunchAndHideOthers
             additionalEventParamDescriptor:nil
                          launchIdentifiers:NULL];
    
    return filePath != nil;
}

- (void) dealloc {
	[query release];
    [dict release];
	[prefsPath release];	
	[searchPaths release];
    [super dealloc];
}

// logMessage
//
// Sends the message passed in from JavaScript to the console.
- (void) logMessage:(NSString *)str {
	if(DEBUG) {
		NSLog(@"logMessage -- %@", str);
	}
}

@end
