//
//  ZKEncryptorStream.m
//  ZipKit
//
//  Created by tanlan on 07.08.14.
//  Copyright (c) 2014 Karl Moskowski. All rights reserved.
//

#import "ZKCryptoFileHandler.h"
#import <RNCryptor/RNEncryptor.h>
#import <RNCryptor/RNDecryptor.h>

@interface ZKCryptoFileHandler ()

@property (strong) RNCryptor *cryptor;
@property (strong) NSData *buffer;
@property (strong) dispatch_semaphore_t readingSemaphore;

@end

@implementation ZKCryptoFileHandler

+ (id)fileHandleForReadingAtPath:(NSString *)path password:(NSString *)password
{
    ZKCryptoFileHandler *newEncryptFileHandler = [super fileHandleForReadingAtPath:path];
    
    if (newEncryptFileHandler != nil)
    {
        newEncryptFileHandler.cryptor = [[RNEncryptor alloc] initWithSettings:kRNCryptorAES256Settings
                                                                     password:password
                                                                      handler:^(RNCryptor *cryptor, NSData *data)
                                         {
                                             if (data != nil && data.length > 0)
                                             {
                                                 newEncryptFileHandler.buffer = [NSData dataWithData:data];
                                             }

                                             if (newEncryptFileHandler.readingSemaphore != nil)
                                             {
                                                 dispatch_semaphore_signal(newEncryptFileHandler.readingSemaphore);
                                             }
                                         }];
    }
    
    return newEncryptFileHandler;
}

+ (id)fileHandleForWritingAtPath:(NSString *)path password:(NSString *)password
{
    ZKCryptoFileHandler *newDecryptFileHandler = [super fileHandleForWritingAtPath:path];
    
    if (newDecryptFileHandler != nil)
    {
        newDecryptFileHandler.cryptor = [[RNDecryptor alloc] initWithPassword:password
                                                                      handler:^(RNCryptor *cryptor, NSData *data)
                                         {
                                             if (data != nil && data.length > 0)
                                             {
                                                 [newDecryptFileHandler writeData:data];
                                             }
                                             
                                             if (newDecryptFileHandler.readingSemaphore != nil)
                                             {
                                                 dispatch_semaphore_signal(newDecryptFileHandler.readingSemaphore);
                                             }
                                         }];
    }
    
    return newDecryptFileHandler;
}

- (NSData *)readDataOfLength:(NSUInteger)length
{
    NSData *readData = [super readDataOfLength:length];
    
    [self.cryptor addData:readData];
    
    dispatch_semaphore_wait(self.readingSemaphore, DISPATCH_TIME_FOREVER);
    
    return self.buffer;
}

- (void)writeData:(NSData *)data
{
    [self.cryptor addData:data];
    dispatch_semaphore_wait(self.readingSemaphore, DISPATCH_TIME_FOREVER);
}

@end
