//
//  ZKCryptoInflator.h
//  ZipKit
//
//  Created by tanlan on 13.08.14.
//  Copyright (c) 2014 Karl Moskowski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZKCryptoInflator : NSObject

- (id)initWithPath:(NSString *)path password:(NSString *)password isFork:(BOOL)isFork;

- (void)writeData:(NSData *)data;
- (void)finalize;

@end
