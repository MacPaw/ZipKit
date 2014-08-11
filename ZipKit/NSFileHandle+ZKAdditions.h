//
//  NSFileHandle+ZKAdditions.h
//  ZipKit
//
//  Created by Karl Moskowski on 01/04/09.
//

#import <Foundation/Foundation.h>

@class RNCryptor;

@interface NSFileHandle (ZKAdditions)

@property (strong) NSData *buffer;
@property (strong) dispatch_semaphore_t readingSemaphore;
@property (retain) RNCryptor *cryptor;

+ (NSFileHandle *) zk_newFileHandleForWritingAtPath:(NSString *)path password:(NSString *)password;
+ (NSFileHandle *) zk_newFileHandleForReadingAtPath:(NSString *)path password:(NSString *)password;

- (NSData *)zk_readDataOfLength:(NSUInteger)length;
- (void)zk_writeData:(NSData *)data;

- (void)zk_closeFile;

@end