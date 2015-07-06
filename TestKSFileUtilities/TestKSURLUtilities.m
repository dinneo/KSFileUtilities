//
//  TestKSURLUtilities.m
//  KSFileUtilities
//
//  Created by Mike on 06/12/2011.
//  Copyright 2011 Karelia Software. All rights reserved.
//


#import <SenTestingKit/SenTestingKit.h>
#import "KSURLUtilities.h"


@interface TestKSURLUtilities : SenTestCase
@end


#pragma mark -


@implementation TestKSURLUtilities

#pragma mark - Test helpers.

#define URL(string) [NSURL URLWithString:string]
#define RELURL(string, base) [NSURL URLWithString:string relativeToURL:base]

- (void)checkURL:(NSURL *)a relativeToURL:(NSURL *)b againstExpectedResult:(NSString *)expectedResult confirmWithRelativeNSURL:(BOOL)testNSURL checkByAppendingToURLToo:(BOOL)testAppending;
{
    // Regular
    NSString *result = [a ks_stringRelativeToURL:b];
    
    STAssertTrue([result isEqualToString:expectedResult],
                 @"\'%@\' relative to \'%@\' should be \'%@\' instead of \'%@\'",
                 a,
                 b,
                 expectedResult,
                 result);
    
    
    // Get NSURL to see if it agrees with the result
    if (testNSURL)
    {
        // Whenever dealing with paths, NSURL always produces a URL with at least some kind of path component:
        //  e.g. http://example.com/ rather than http://example.com
        // This test needs to compensate by making sure the URLs to be tested match that
        NSURL *nsurlsOpinion = [[[NSURL URLWithString:result relativeToURL:b] absoluteURL] standardizedURL];    // gotta do absoluteURL first apparently
        if (![[nsurlsOpinion path] length]) nsurlsOpinion = [nsurlsOpinion ks_hostURL];
        NSURL *urlWithPathAsNeeded = a; if (![[a path] length]) urlWithPathAsNeeded = [a ks_hostURL];
        
        STAssertEqualObjects([nsurlsOpinion absoluteString], [urlWithPathAsNeeded absoluteString],
                             @"(\'%@\' relative to \'%@\')",
                             result,
                             b,
                             [urlWithPathAsNeeded absoluteString],
                             nsurlsOpinion);
    }
    
    
    // A trailing
    if (testAppending)
    {
        NSURL *aTrailing = [NSURL URLWithString:[a.relativeString stringByAppendingString:@"/"] relativeToURL:a.baseURL];
        //NSURL *bTrailing = [NSURL URLWithString:[b.relativeString stringByAppendingString:@"/"] relativeToURL:b.baseURL];
        
        [self checkURL:aTrailing relativeToURL:b againstExpectedResult:[expectedResult stringByAppendingString:@"/"] confirmWithRelativeNSURL:testNSURL checkByAppendingToURLToo:NO];
        
        
        // Percent encoding, but not for root URLs
        NSString *encodedSlash = @"%2F";
        if (![[a relativeString] hasSuffix:encodedSlash] && a.path.length)
        {
            NSURL *aWithCrazyEncoding = [NSURL URLWithString:[a.relativeString stringByAppendingString:encodedSlash] relativeToURL:a.baseURL];
            
            [self checkURL:aWithCrazyEncoding
             relativeToURL:b
     againstExpectedResult:[expectedResult stringByAppendingString:encodedSlash]
  confirmWithRelativeNSURL:testNSURL
  checkByAppendingToURLToo:YES];
        }
    }
}

/*  Performs test pretty much as it says on the tin
 *  URLs are tested as given, but then also with a trailing slash applied to A
 *  Similarly they are also tested by appending escaping sequences to check escaping is working fine
 */
- (void)checkURL:(NSURL *)a relativeToURL:(NSURL *)b againstExpectedResult:(NSString *)expectedResult;
{
    [self checkURL:a relativeToURL:b againstExpectedResult:expectedResult confirmWithRelativeNSURL:YES checkByAppendingToURLToo:![a ks_hasDirectoryPath]];
}

- (void)testURLRelativeToURL
{
    // Impossible to find a relative path
    [self checkURL:URL(@"http://example.com") relativeToURL:URL(@"https://example.com/") againstExpectedResult:@"http://example.com"];
    [self checkURL:URL(@"http://example.com") relativeToURL:URL(@"http://example.org/")  againstExpectedResult:@"http://example.com"];
    [self checkURL:URL(@"http://example.com") relativeToURL:URL(@"")                     againstExpectedResult:@"http://example.com"];
    [self checkURL:URL(@"http://example.com:5000/") relativeToURL:URL(@"http://example.com/") againstExpectedResult:@"http://example.com:5000/"];
    
    
    
    // Same
    [self checkURL:URL(@"http://example.com") relativeToURL:URL(@"http://example.com")  againstExpectedResult:@"."];
    [self checkURL:URL(@"http://example.com") relativeToURL:URL(@"http://example.com/")  againstExpectedResult:@"."];
    [self checkURL:URL(@"http://example.com/foo") relativeToURL:URL(@"http://example.com/foo")  againstExpectedResult:@"foo"];
    
    // somewhat of a special case:
    [self checkURL:URL(@"http://example.com/foo") relativeToURL:URL(@"http://example.com/foo/") againstExpectedResult:@"../foo" confirmWithRelativeNSURL:YES checkByAppendingToURLToo:NO];
    [self checkURL:URL(@"http://example.com/foo/") relativeToURL:URL(@"http://example.com/foo/") againstExpectedResult:@"./" confirmWithRelativeNSURL:YES checkByAppendingToURLToo:NO];
    [self checkURL:URL(@"http://example.com/foo%2F") relativeToURL:URL(@"http://example.com/foo/") againstExpectedResult:@"../foo%2F"];
    
    
    // Scheme and domain should be case-insensitive
    [self checkURL:URL(@"http://eXample.com") relativeToURL:URL(@"httP://ExamPle.com")  againstExpectedResult:@"." confirmWithRelativeNSURL:NO checkByAppendingToURLToo:YES];
    [self checkURL:URL(@"hTtp://eXample.com") relativeToURL:URL(@"httP://ExamPle.com/")  againstExpectedResult:@"." confirmWithRelativeNSURL:NO checkByAppendingToURLToo:YES];
    [self checkURL:URL(@"hTtp://eXample.com/foo") relativeToURL:URL(@"httP://ExamPle.com/foo")  againstExpectedResult:@"foo" confirmWithRelativeNSURL:NO checkByAppendingToURLToo:YES];
    
    
    // Diving in
    [self checkURL:URL(@"http://example.com/foo")     relativeToURL:URL(@"http://example.com")         againstExpectedResult:@"foo"];
    [self checkURL:URL(@"http://example.com/foo/bar") relativeToURL:URL(@"http://example.com")         againstExpectedResult:@"foo/bar"];
    [self checkURL:URL(@"http://example.com/foo/bar") relativeToURL:URL(@"http://example.com/foo")  againstExpectedResult:@"foo/bar"];
    [self checkURL:URL(@"http://example.com/foo/bar") relativeToURL:URL(@"http://example.com/foo/") againstExpectedResult:@"bar"];
    
    
    
    // Walking out
    [self checkURL:URL(@"http://example.com") relativeToURL:URL(@"http://example.com/foo%2F")      againstExpectedResult:@"."];
    [self checkURL:URL(@"http://example.com") relativeToURL:URL(@"http://example.com/foo%2F/")     againstExpectedResult:@".."];
    [self checkURL:URL(@"http://example.com") relativeToURL:URL(@"http://example.com/foo%2F/bar")  againstExpectedResult:@".."];
    [self checkURL:URL(@"http://example.com") relativeToURL:URL(@"http://example.com/foo%2F/bar/") againstExpectedResult:@"../.."];
    
    
    
    // Cross-directory
    [self checkURL:URL(@"http://example.com/foo")     relativeToURL:URL(@"http://example.com/bar")         againstExpectedResult:@"foo"];
    [self checkURL:URL(@"http://example.com/foo")     relativeToURL:URL(@"http://example.com/bar/")        againstExpectedResult:@"../foo"];
    [self checkURL:URL(@"http://example.com/foo/bar") relativeToURL:URL(@"http://example.com/bar")         againstExpectedResult:@"foo/bar"];
    [self checkURL:URL(@"http://example.com/foo/bar") relativeToURL:URL(@"http://example.com/bar/")        againstExpectedResult:@"../foo/bar"];
    [self checkURL:URL(@"http://example.com/foo/bar") relativeToURL:URL(@"http://example.com/bar/foo%2F")  againstExpectedResult:@"../foo/bar"];
    [self checkURL:URL(@"http://example.com/foo/bar") relativeToURL:URL(@"http://example.com/bar/foo%2F/") againstExpectedResult:@"../../foo/bar"];
    
    
    // File URLs
    [self checkURL:URL(@"file:///foo/bar/baz") relativeToURL:URL(@"file:///foo/bar/") againstExpectedResult:@"baz"];
    
    
    // Crashed at one point
    STAssertEqualObjects([URL(@"") ks_stringRelativeToURL:URL(@"http://example.com/foo/")], nil,
                         nil);
}

- (void)testHostSwapping;
{
    STAssertEqualObjects([URL(@"http://example.com") ks_URLWithHost:@"test.net"], URL(@"http://test.net"), nil);
    STAssertEqualObjects([URL(@"http://example.com/") ks_URLWithHost:@"test.net"], URL(@"http://test.net/"), nil);

    STAssertEqualObjects([URL(@"file:///example.png") ks_URLWithHost:@"example.com"], URL(@"file://example.com/example.png"), nil);
    STAssertEqualObjects([URL(@"file:///") ks_URLWithHost:@"example.com"], URL(@"file://example.com/"), nil);
    STAssertEqualObjects([URL(@"test:///example.png#fragment") ks_URLWithHost:@"example.com"], URL(@"test://example.com/example.png#fragment"), nil);
    STAssertEqualObjects([URL(@"test:///#fragment") ks_URLWithHost:@"example.com"], URL(@"test://example.com/#fragment"), nil);

    STAssertEqualObjects([URL(@"test://") ks_URLWithHost:@"example.com"], URL(@"test://example.com"), nil);
    STAssertEqualObjects([URL(@"test://#fragment") ks_URLWithHost:@"example.com"], URL(@"test://example.com#fragment"), nil);
    STAssertEqualObjects([URL(@"test://joe@:1234#fragment") ks_URLWithHost:@"example.com"], URL(@"test://joe@example.com:1234#fragment"), nil);

    // I'm not convinced about this one. The URL test:example.com/ doesn't recognise example.com as the host
    STAssertEqualObjects([URL(@"test:/") ks_URLWithHost:@"example.com"], URL(@"test:example.com/"), nil);
}

- (void)testURLHasDirectoryPath;
{
    STAssertFalse([[NSURL URLWithString:@"http://example.com/foo"] ks_hasDirectoryPath], @"No trailing slash");
    STAssertTrue([[NSURL URLWithString:@"http://example.com/foo/"] ks_hasDirectoryPath], @"Trailing slash");
    
    STAssertFalse([[NSURL URLWithString:@"http://example.com"] ks_hasDirectoryPath], @"No trailing slash");
    STAssertTrue([[NSURL URLWithString:@"http://example.com/"] ks_hasDirectoryPath], @"Trailing slash");
    
    STAssertFalse([[NSURL URLWithString:@"foo" relativeToURL:[NSURL URLWithString:@"http://example.com/"]] ks_hasDirectoryPath], @"No trailing slash");
    STAssertTrue([[NSURL URLWithString:@"foo/" relativeToURL:[NSURL URLWithString:@"http://example.com/"]] ks_hasDirectoryPath], @"Trailing slash");
    
    STAssertFalse([[NSURL URLWithString:@"bar" relativeToURL:[NSURL URLWithString:@"http://example.com/foo/"]] ks_hasDirectoryPath], @"No trailing slash");
    STAssertTrue([[NSURL URLWithString:@"bar/" relativeToURL:[NSURL URLWithString:@"http://example.com/foo"]] ks_hasDirectoryPath], @"Trailing slash");
    
    STAssertFalse([[NSURL URLWithString:@"#anchor" relativeToURL:[NSURL URLWithString:@"http://example.com/foo"]] ks_hasDirectoryPath], @"No trailing slash");
    STAssertTrue([[NSURL URLWithString:@"#anchor" relativeToURL:[NSURL URLWithString:@"http://example.com/foo/"]] ks_hasDirectoryPath], @"Trailing slash");
}

- (void)testIsSubpath;
{
    STAssertTrue([URL(@"http://example.com/foo/bar/baz.html") ks_isSubpathOfURL:URL(@"http://example.com/foo") options:0], nil);
    STAssertTrue([URL(@"http://example.com/foo/bar/baz.html") ks_isSubpathOfURL:URL(@"http://example.com/foo/") options:0], nil);
    STAssertFalse([URL(@"http://example.com/foo/bar/baz.html") ks_isSubpathOfURL:URL(@"http://example.com/fo") options:0], nil);
    STAssertTrue([URL(@"http://example.com/foo/bar/baz.html") ks_isSubpathOfURL:URL(@"http://example.com/") options:0], nil);
    STAssertTrue([URL(@"http://example.com/foo/bar/baz.html") ks_isSubpathOfURL:URL(@"http://example.com") options:0], nil);
    
    // Scheme and host should be case insensitive
    STAssertTrue([URL(@"HTtp://example.com/foo/bar/baz.html") ks_isSubpathOfURL:URL(@"hTtP://example.com/foo/") options:0], nil);
    STAssertTrue([URL(@"http://eXaMPle.COm/foo/bar/baz.html") ks_isSubpathOfURL:URL(@"http://ExamPle.cOm/foo/") options:0], nil);
    
    // Treat items as being subpaths of themselves
    STAssertTrue([URL(@"http://example.com/foo/bar/baz.html") ks_isSubpathOfURL:URL(@"http://example.com/foo/bar/baz.html") options:0], nil);
    STAssertTrue([URL(@"http://example.com/foo/bar/baz.html/") ks_isSubpathOfURL:URL(@"http://example.com/foo/bar/baz.html") options:0], nil);
    STAssertTrue([URL(@"http://example.com/foo/bar/baz.html") ks_isSubpathOfURL:URL(@"http://example.com/foo/bar/baz.html/") options:0], nil);
    STAssertTrue([URL(@"http://example.com/foo/bar/baz.html/") ks_isSubpathOfURL:URL(@"http://example.com/foo/bar/baz.html/") options:0], nil);
    STAssertTrue([URL(@"http://example.com/foo") ks_isSubpathOfURL:URL(@"http://example.com/foo") options:0], nil);
    STAssertTrue([URL(@"http://example.com/foo/") ks_isSubpathOfURL:URL(@"http://example.com/foo") options:0], nil);
    STAssertTrue([URL(@"http://example.com/foo") ks_isSubpathOfURL:URL(@"http://example.com/foo/") options:0], nil);
    STAssertTrue([URL(@"http://example.com/foo/") ks_isSubpathOfURL:URL(@"http://example.com/foo/") options:0], nil);
    STAssertTrue([URL(@"http://example.com") ks_isSubpathOfURL:URL(@"http://example.com") options:0], nil);
    STAssertTrue([URL(@"http://example.com/") ks_isSubpathOfURL:URL(@"http://example.com") options:0], nil);
    STAssertTrue([URL(@"http://example.com") ks_isSubpathOfURL:URL(@"http://example.com/") options:0], nil);
    STAssertTrue([URL(@"http://example.com/") ks_isSubpathOfURL:URL(@"http://example.com/") options:0], nil);
}

#pragma mark Foundation

/*  Test some aspects of Foundation just to make sure they're as we expect
 */

- (void)testIsFileURL;
{
    STAssertTrue([URL(@"file:///example.png") isFileURL], nil);
    STAssertTrue([URL(@"fIlE:///example.png") isFileURL], nil);
}

- (void)testNilURLStrings;
{
    // As far as I can tell, the behaviour of +URLWithString: changed in OS X 10.7
#if (defined MAC_OS_X_VERSION_10_7 && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_7)
    STAssertNoThrow([NSURL URLWithString:nil], nil);
    STAssertNoThrow([NSURL URLWithString:nil relativeToURL:nil], nil);
    STAssertNoThrow([NSURL URLWithString:nil relativeToURL:URL(@"http://example.com/")], nil);
#else
    STAssertThrows([NSURL URLWithString:nil], nil);
    STAssertThrows([NSURL URLWithString:nil relativeToURL:nil], nil);
    STAssertThrows([NSURL URLWithString:nil relativeToURL:URL(@"http://example.com/")], nil);
#endif
    
    // Other methods appear to still behave as they always have
    STAssertThrows([[NSURL alloc] initWithString:nil], nil);
    STAssertThrows([[NSURL alloc] initWithString:nil relativeToURL:nil], nil);
    STAssertThrows([NSURL fileURLWithPath:nil], nil);
    STAssertThrows([[NSURL alloc] initFileURLWithPath:nil], nil);
}

- (void)testDeletingLastPathComponent;
{
    STAssertEqualObjects([URL(@"http://example.com/foo/bar") URLByDeletingLastPathComponent], URL(@"http://example.com/foo/"), nil);
    STAssertEqualObjects([URL(@"http://example.com/foo/bar/") URLByDeletingLastPathComponent], URL(@"http://example.com/foo/"), nil);
    
    // But as soon as we introduce another slash, NSURL cocks it up, or maybe just hedges its bets
    STAssertEqualObjects([URL(@"http://example.com/foo/bar//") URLByDeletingLastPathComponent], URL(@"http://example.com/foo/bar//../"), nil);
    
    // The CF-level API behaves the same
    STAssertEqualObjects((NSURL *)CFURLCreateCopyDeletingLastPathComponent(NULL, (CFURLRef)URL(@"http://example.com/foo/bar//")), URL(@"http://example.com/foo/bar//../"), nil);
    
    
    
    // The behaviour makes some sense when faced with a root URL
    STAssertEqualObjects([URL(@"http://example.com/") URLByDeletingLastPathComponent], URL(@"http://example.com/../"), nil);
    STAssertEqualObjects([URL(@"http://example.com//") URLByDeletingLastPathComponent], URL(@"http://example.com//../"), nil);
}

- (void)testStandardizedURL;
{
    STAssertEqualObjects([URL(@"http://example.com/foo/../bar") standardizedURL], URL(@"http://example.com/bar"), nil);
    STAssertEqualObjects([URL(@"http://example.com/foo/../bar/") standardizedURL], URL(@"http://example.com/bar/"), nil);
    
    // Throw in an extra slash though and the system can get quite confused. Some make sense:
    STAssertEqualObjects([URL(@"http://example.com/foo/..//bar") standardizedURL], URL(@"http://example.com//bar"), nil);
    STAssertEqualObjects([URL(@"http://example.com/foo/..//bar/") standardizedURL], URL(@"http://example.com//bar/"), nil);
    
    // But once you have the magic combo of two slashes *before* .. the result seems weird
    STAssertEqualObjects([URL(@"http://example.com/foo//../bar") standardizedURL], URL(@"http://example.com/foo/bar"), nil);
}

- (void)testParentDirectory;
{
    // Reassure myself NSURLParentDirectoryURLKey fails if the URL doesn't exist, unlike -URLByDeletingLastPathComponent
    NSURL *home = [NSURL fileURLWithPath:NSHomeDirectory() isDirectory:YES];
    NSURL *test = [home URLByAppendingPathComponent:@"test-file-with-unlikely-filename-0123456789"];
    
    NSURL *parent;
    STAssertFalse([test getResourceValue:&parent forKey:NSURLParentDirectoryURLKey error:NULL], nil);
}

- (void)testMakingDirectoryURL;
{
    // URLByAppendingPathComponent:@"" only appends a trailing slash if there isn't one already (as far as I can tell)
    STAssertEqualObjects([URL(@"http://example.com/test") URLByAppendingPathComponent:@""], URL(@"http://example.com/test/"), nil);
    STAssertEqualObjects([URL(@"http://example.com/test/") URLByAppendingPathComponent:@""], URL(@"http://example.com/test/"), nil);
    STAssertEqualObjects([URL(@"http://example.com/test//") URLByAppendingPathComponent:@""], URL(@"http://example.com/test//"), nil);
    
    // It's even nice enough to handle query etc.
    STAssertEqualObjects([URL(@"http://example.com/test?foo=bar") URLByAppendingPathComponent:@""], URL(@"http://example.com/test/?foo=bar"), nil);
    STAssertEqualObjects([URL(@"http://example.com/test/?foo=bar") URLByAppendingPathComponent:@""], URL(@"http://example.com/test/?foo=bar"), nil);
    
    // Handles host URLs too
    STAssertEqualObjects([URL(@"http://example.com/") URLByAppendingPathComponent:@""], URL(@"http://example.com/"), nil);
    STAssertEqualObjects([URL(@"http://example.com") URLByAppendingPathComponent:@""], URL(@"http://example.com/"), nil);
    STAssertEqualObjects([URL(@"http://example.com?foo=bar") URLByAppendingPathComponent:@""], URL(@"http://example.com/?foo=bar"), nil);
    STAssertEqualObjects([URL(@"http://example.com/?foo=bar") URLByAppendingPathComponent:@""], URL(@"http://example.com/?foo=bar"), nil);
}

@end
