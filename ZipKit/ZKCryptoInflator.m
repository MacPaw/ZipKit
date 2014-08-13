//
//  ZKCryptoInflator.m
//  ZipKit
//
//  Created by tanlan on 13.08.14.
//  Copyright (c) 2014 Karl Moskowski. All rights reserved.
//

#import "ZKCryptoInflator.h"
#import <RNCryptor/RNDecryptor.h>
#import "NSFileHandle+ZKAdditions.h"
#import "GMAppleDouble+ZKAdditions.h"

@interface ZKCryptoInflator ()

@property (assign) BOOL isFork;
@property (retain) RNDecryptor *decryptor;
@property (retain) NSFileHandle *fileHandle;

@property (retain) NSMutableData *forkBuffer;
@property (retain) dispatch_semaphore_t semaphore;
@property (retain) NSString *path;

@end

@implementation ZKCryptoInflator

- (id)initWithPath:(NSString *)path password:(NSString *)password isFork:(BOOL)isFork
{
    self = [super init];
    
    if (self != nil)
    {
        _isFork = isFork;
        _path = [NSString stringWithString:path];
        
        if (_isFork)
        {
            _forkBuffer = [[NSMutableData alloc] init];
            _decryptor = [[RNDecryptor alloc] initWithPassword:password
                                                       handler:^(RNCryptor *cryptor, NSData *data)
            {
                if (data != nil && data.length)
                {
                    [_forkBuffer appendData:data];
                }

                if (self.semaphore != nil)
                {
                   dispatch_semaphore_signal(self.semaphore);
                }
            }];
        }
        else
        {
            _fileHandle = [NSFileHandle zk_newFileHandleForWritingAtPath:_path password:password];
        }
    }
    
    return self;
}

#pragma mark -

- (void)writeData:(NSData *)data
{
    if (data != nil && data.length > 0)
    {
        if (self.isFork)
        {
            if (!self.decryptor.isFinished)
            {
                self.semaphore = dispatch_semaphore_create(0);
                [self.decryptor addData:data];
                dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
            }
        }
        else
        {
            [self.fileHandle zk_writeData:data];
        }
    }
}

- (void)finalize
{
    if (self.isFork)
    {
        if (!self.decryptor.isFinished)
        {
            self.semaphore = dispatch_semaphore_create(0);
            [self.decryptor finish];
            dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
            [GMAppleDouble zk_restoreAppleDoubleData:self.forkBuffer toPath:self.path];
        }
    }
    else
    {
        [self.fileHandle zk_closeFile];
    }
}

@end
