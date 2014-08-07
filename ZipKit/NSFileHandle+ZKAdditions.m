//
//  NSFileHandle+ZKAdditions.m
//  ZipKit
//
//  Created by Karl Moskowski on 01/04/09.
//

#import "NSFileHandle+ZKAdditions.h"
#import "ZKCryptoFileHandler.h"

@implementation NSFileHandle (ZKAdditions)

+ (NSFileHandle *) zk_newFileHandleForWritingAtPath:(NSString *)path password:(NSString *)password
{
	NSFileManager *fm = [NSFileManager new];
	if (![fm fileExistsAtPath:path]) {
		[fm createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
		[fm createFileAtPath:path contents:nil attributes:nil];
	}
	NSFileHandle *fileHandle = password == nil ? [NSFileHandle fileHandleForWritingAtPath:path] :
                                                 [ZKCryptoFileHandler fileHandleForWritingAtPath:path password:password];
	return fileHandle;
}

+ (NSFileHandle *) zk_newFileHandleForReadingAtPath:(NSString *)path password:(NSString *)password
{
    NSFileHandle *fileHandle = password == nil ? [NSFileHandle fileHandleForReadingAtPath:path] :
                                                 [ZKCryptoFileHandler fileHandleForReadingAtPath:path password:password];
    
    return fileHandle;
}

@end