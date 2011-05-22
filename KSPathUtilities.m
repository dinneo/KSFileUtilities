//
//  KSPathUtilities.m
//
//  Copyright (c) 2005-2011, Dan Wood, Mike Abdullah and Karelia Software
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//      * Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//      * Redistributions in binary form must reproduce the above copyright
//        notice, this list of conditions and the following disclaimer in the
//        documentation and/or other materials provided with the distribution.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL DAN WOOD, MIKE ABDULLAH OR KARELIA SOFTWARE BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "KSPathUtilities.h"


@implementation NSString (KSPathUtilities)

- (BOOL)ks_isEqualToPath:(NSString *)aPath;
{
    NSString *myPath = [self stringByStandardizingPath];
    aPath = [aPath stringByStandardizingPath];
    
    BOOL result = ([myPath caseInsensitiveCompare:aPath] == NSOrderedSame);
    return result;
}

- (NSString *)ks_stringWithPathSuffix:(NSString *)aString;
{
    NSString *result = self;
    
    NSString *extension = [self pathExtension];
    if ([extension length])
    {
        result = [[[self
                    stringByDeletingPathExtension]
                   stringByAppendingString:aString]
                  stringByAppendingPathExtension:extension];
    }
    else
    {
        result = [self stringByAppendingString:aString];
    }
    
    return result;
}

- (NSString *)ks_pathRelativeToDirectory:(NSString *)dirPath
{
    if ([dirPath isAbsolutePath])
    {
        if (![self isAbsolutePath]) return self;    // job's already done for us!
    }
    else
    {
        // An absolute path relative to a relative path is always going to be self
        if ([self isAbsolutePath]) return self;
        
        // But comparing two relative paths is a bit of an edge case. Internally, pretend they're absolute
        return [[@"/" stringByAppendingString:self] ks_pathRelativeToDirectory:[@"/" stringByAppendingString:dirPath]];
    }
    
    
    // Easy way out
    if ([self isEqualToString:dirPath]) return @".";
    
    
    
    
    // Our internal workings currently expect trailing slashes, so let's supply that for them
    //if (![dirPath hasSuffix:@"/"]) dirPath = [dirPath stringByAppendingString:@"/"];
    //if (![self hasSuffix:@"/"]) self = [self stringByAppendingString:@"/"];
    
    
	NSString *commonDir = [self commonPrefixWithString:dirPath options:NSLiteralSearch];
	if ([commonDir isEqualToString:@""]) return self;
	
	
    // What the paths have in common could be two similar folder names
    // e.g. /foo/barnicle and /foo/bart/baz
    // If so, wind back to the nearest slash
    if (![commonDir hasSuffix:@"/"])
    {
        if ([self length] > [commonDir length] &&
        [self characterAtIndex:[commonDir length]] != '/')
        {
            NSUInteger separatorLocation = [commonDir rangeOfString:@"/" options:NSBackwardsSearch].location;
            if (separatorLocation == NSNotFound) separatorLocation = 0;
            commonDir = [commonDir substringToIndex:separatorLocation];
        }
        else if ([dirPath length] > [commonDir length] &&
                 [dirPath characterAtIndex:[commonDir length]] != '/')
        {
            NSUInteger separatorLocation = [commonDir rangeOfString:@"/" options:NSBackwardsSearch].location;
            if (separatorLocation == NSNotFound) separatorLocation = 0;
            commonDir = [commonDir substringToIndex:separatorLocation];
        }
    }
    
    
    NSMutableString *result = [NSMutableString stringWithCapacity:
                        [self length] + [dirPath length] - 2*[commonDir length]];
    
    
    // How do you get from the directory path, to commonDir?
    NSString *otherDifferingPath = [dirPath substringFromIndex:[commonDir length]];
	NSArray *hopsUpArray = [otherDifferingPath componentsSeparatedByString:@"/"];
    
	for (NSString *aComponent in hopsUpArray)
    {
        if ([aComponent length] && ![aComponent isEqualToString:@"."])
        {
            NSAssert(![aComponent isEqualToString:@".."], @".. unsupported");  
            if ([result length]) [result appendString:@"/"];
            [result appendString:@".."];
        }
    }
    
    
    // And then navigating from commonDir, to self, is mostly a simple append
	NSString *pathRelativeToCommonDir = [self substringFromIndex:[commonDir length]];
    
    // But ignore leading slash(es) since they cause relative path to be reported as absolute
    while ([pathRelativeToCommonDir hasPrefix:@"/"])
    {
        pathRelativeToCommonDir = [pathRelativeToCommonDir substringFromIndex:1];
    }
    
    if ([pathRelativeToCommonDir length])
    {
        if ([result length]) [result appendString:@"/"];
        [result appendString:pathRelativeToCommonDir];
    }
	
    
    // Final tidy-up?
	if ([result isEqualToString:@""])	
	{
		if ([self hasSuffix:@"/"])
		{
			[result appendString:@"./"];	// if our relative link is to the top, then replace with ./
		}
		else	// link to yourself; give us just the file name
		{
			[result appendString:[self lastPathComponent]];
		}
	}
	
	return result;
}


/*  We can somewhat cheat by giving each path a trailing slash and then do simple string comparison.
 That way we ensure that we don't have something like ABCDEFGH being considered a subpath of ABCD
 But ABCD/EFGH will be.
 */
- (BOOL)ks_isSubpathOfPath:(NSString *)aPath
{
    NSParameterAssert(aPath);  // karelia case #115844
    
    
	NSString *adjustedMePath = self;
	if (![adjustedMePath isEqualToString:@"/"])
	{
		adjustedMePath = [adjustedMePath stringByAppendingString:@"/"];
	}
	
	NSString *adjustedOtherPath = aPath;
	if (![adjustedOtherPath isEqualToString:@"/"])
	{
		adjustedOtherPath = [adjustedOtherPath stringByAppendingString:@"/"];
	}
    
    // Used to -hasPrefix:, but really need to do it case insensitively
    NSRange result = [adjustedMePath rangeOfString:adjustedOtherPath
                                           options:(NSAnchoredSearch | NSCaseInsensitiveSearch)];
    
    return (result.location == 0);
}


/*  Trailing slashes are insignificant under the POSIX standard. If the receiver has a trailing
 *  slash, a new string is returned with the slash removed.
 */
- (NSString *)ks_standardizedPOSIXPath
{
    if ([self length] > 1 && [self hasSuffix:@"/"]) // Stops @"/" being altered
    {
        return [self substringToIndex:([self length] - 1)];
    }
    else
    {
        return self;
    }
}

/*  You should generally use this method when comparing two paths for equality. Unlike -isEqualToString:
 *  it treats any trailing slash as insignificant. NO reference to the local filesystem is used.
 */
- (BOOL)ks_isEqualToPOSIXPath:(NSString *)otherPath
{
    BOOL result = [[self ks_standardizedPOSIXPath] isEqualToString:[otherPath ks_standardizedPOSIXPath]];
    return result;
}

@end
