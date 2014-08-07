//
//  ZKEncryptorStream.h
//  ZipKit
//
//  Created by tanlan on 07.08.14.
//  Copyright (c) 2014 Karl Moskowski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZKCryptoFileHandler : NSFileHandle

+ (id)fileHandleForReadingAtPath:(NSString *)path password:(NSString *)password;
+ (id)fileHandleForWritingAtPath:(NSString *)path password:(NSString *)password;

@end
