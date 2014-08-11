//
//  NSFileHandle+ZKAdditions.m
//  ZipKit
//
//  Created by Karl Moskowski on 01/04/09.
//

#import "NSFileHandle+ZKAdditions.h"

#import <RNCryptor/RNEncryptor.h>
#import <RNCryptor/RNDecryptor.h>

#import "objc/runtime.h"

static void *NSFileHandleBufferKey;
static void *NSFileHandleCryptorKey;
static void *NSFileHandleReadingSemaphoreKey;

@implementation NSFileHandle (ZKAdditions)

#pragma mark - Accessors

- (NSData *)buffer
{
    NSData *_buffer = objc_getAssociatedObject(self, &NSFileHandleBufferKey);
    return _buffer;
}

- (void)setBuffer:(NSData *)buffer
{
    objc_setAssociatedObject(self, &NSFileHandleBufferKey, buffer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (RNCryptor *)cryptor
{
    RNCryptor *_cryptor = objc_getAssociatedObject(self, &NSFileHandleCryptorKey);
    return _cryptor;
}

- (void)setCryptor:(RNCryptor *)cryptor
{
    objc_setAssociatedObject(self, &NSFileHandleCryptorKey, cryptor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (dispatch_semaphore_t)readingSemaphore
{
    dispatch_semaphore_t _readingSemaphore = objc_getAssociatedObject(self, &NSFileHandleReadingSemaphoreKey);
    return _readingSemaphore;
}

- (void)setReadingSemaphore:(dispatch_semaphore_t)readingSemaphore
{
    objc_setAssociatedObject(self, &NSFileHandleReadingSemaphoreKey, readingSemaphore, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -

+ (NSFileHandle *)zk_newFileHandleForWritingAtPath:(NSString *)path password:(NSString *)password
{
	NSFileManager *fm = [NSFileManager new];
	if (![fm fileExistsAtPath:path]) {
		[fm createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
		[fm createFileAtPath:path contents:nil attributes:nil];
	}
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
    
    if (password != nil)
    {
        fileHandle.cryptor = [[RNDecryptor alloc] initWithPassword:password
                                                           handler:^(RNCryptor *cryptor, NSData *data)
        {
            if (data != nil && data.length > 0)
            {
                [fileHandle writeData:data];
            }

            if (fileHandle.readingSemaphore != nil)
            {
                dispatch_semaphore_signal(fileHandle.readingSemaphore);
            }
        }];
    }
    
    return fileHandle;
}

+ (NSFileHandle *)zk_newFileHandleForReadingAtPath:(NSString *)path password:(NSString *)password
{
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    
    if (password != nil)
    {
        fileHandle.cryptor = [[RNEncryptor alloc] initWithSettings:kRNCryptorAES256Settings
                                                          password:password
                                                           handler:^(RNCryptor *cryptor, NSData *data)
                              {
                                  if (data != nil && data.length > 0)
                                  {
                                      fileHandle.buffer = [NSData dataWithData:data];
                                  }
                                  
                                  if (fileHandle.readingSemaphore != nil)
                                  {
                                      dispatch_semaphore_signal(fileHandle.readingSemaphore);
                                  }
                              }];
    }
    
    return fileHandle;
}

- (NSData *)zk_readDataOfLength:(NSUInteger)length
{
    NSData *readData = [self readDataOfLength:length];
   
    self.readingSemaphore = dispatch_semaphore_create(0);
    
    if (readData.length != 0)
    {
        [self.cryptor addData:readData];
    }
    else if (!self.cryptor.isFinished)
    {
        [self.cryptor finish];
    }
    else
    {
        return nil;
    }
    
    dispatch_semaphore_wait(self.readingSemaphore, DISPATCH_TIME_FOREVER);
    return self.buffer;;
}

- (void)zk_writeData:(NSData *)data
{
    self.readingSemaphore = dispatch_semaphore_create(0);
    [self.cryptor addData:data];
    dispatch_semaphore_wait(self.readingSemaphore, DISPATCH_TIME_FOREVER);
}

- (void)zk_closeFile
{
    self.readingSemaphore = dispatch_semaphore_create(0);
    [self.cryptor finish];
    dispatch_semaphore_wait(self.readingSemaphore, DISPATCH_TIME_FOREVER);
    
    [self closeFile];
}

@end