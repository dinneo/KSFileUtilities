//
//  TestKSPathUtilities.m
//  KSFileUtilities
//
//  Created by Abizer Nasir on 22/05/2011.
//

#import <SenTestingKit/SenTestingKit.h>
#import "KSPathUtilities.h"


@interface TestKSPathUtilities : SenTestCase {
@private
    
}

- (void)testPath:(NSString *)path relativeToDirectory:(NSString *)dirPath expectedResult:(NSString *)expectedResult;
@end


@implementation TestKSPathUtilities

#pragma mark - Tests

- (void)testPath:(NSString *)path relativeToDirectory:(NSString *)dirPath expectedResult:(NSString *)expectedResult;
{
    NSString *result = [path ks_pathRelativeToDirectory:dirPath];
    
    STAssertTrue([result isEqualToString:expectedResult],
                 @"\'%@\' relative to \'%@\' should be \'%@\' instead of \'%@\'",
                 path,
                 dirPath,
                 expectedResult,
                 result);
}

- (void)testPathRelativeToDirectory {
    // Test cases for ks_pathRelativeToDirectory
    
    
    /*  No traversal needed
     */
    [self testPath:@"/" relativeToDirectory:@"/" expectedResult:@"."];
    [self testPath:@"/foo" relativeToDirectory:@"/foo" expectedResult:@"."];
    [self testPath:@"/foo/bar" relativeToDirectory:@"/foo/bar" expectedResult:@"."];
    
    
    
    /*  No traversal needed, trailing slashes
     */
    [self testPath:@"//" relativeToDirectory:@"//" expectedResult:@"."];
    [self testPath:@"//" relativeToDirectory:@"/" expectedResult:@"./"];
    [self testPath:@"/" relativeToDirectory:@"//" expectedResult:@"."];
    [self testPath:@"/foo/" relativeToDirectory:@"/foo/" expectedResult:@"."];
    [self testPath:@"/foo/" relativeToDirectory:@"/foo" expectedResult:@"./"];
    [self testPath:@"/foo" relativeToDirectory:@"/foo/" expectedResult:@"."];
    [self testPath:@"/foo/bar/" relativeToDirectory:@"/foo/bar/" expectedResult:@"."];
    [self testPath:@"/foo/bar/" relativeToDirectory:@"/foo/bar" expectedResult:@"./"];
    [self testPath:@"/foo/bar" relativeToDirectory:@"/foo/bar/" expectedResult:@"."];
    
        
    /*  No traversal needed, relative paths
     */
    [self testPath:@"foo" relativeToDirectory:@"foo" expectedResult:@"."];
    [self testPath:@"foo/bar" relativeToDirectory:@"foo/bar" expectedResult:@"."];
    
    
    /*  Traversing from root
     */
    [self testPath:@"/foo" relativeToDirectory:@"/" expectedResult:@"foo"];
    [self testPath:@"/foo/bar" relativeToDirectory:@"/" expectedResult:@"foo/bar"];
    [self testPath:@"/foo/" relativeToDirectory:@"/" expectedResult:@"foo/"];
    [self testPath:@"/foo/bar/" relativeToDirectory:@"/" expectedResult:@"foo/bar/"];
    
    
    
    /*  Traversing from unusual root
     */
    [self testPath:@"/foo" relativeToDirectory:@"//" expectedResult:@"foo"];
    [self testPath:@"/foo/bar" relativeToDirectory:@"//" expectedResult:@"foo/bar"];
    
    
    
    /*  Traversing back to root
     */
    [self testPath:@"/" relativeToDirectory:@"/foo" expectedResult:@".."];
    [self testPath:@"/" relativeToDirectory:@"/foo/bar" expectedResult:@"../.."];
    [self testPath:@"/" relativeToDirectory:@"/foo/" expectedResult:@".."];
    [self testPath:@"/" relativeToDirectory:@"/foo/bar/" expectedResult:@"../.."];
    
    
    
    /*  Traversing from parent folder
     */
    [self testPath:@"/foo/bar" relativeToDirectory:@"/foo" expectedResult:@"bar"];
    [self testPath:@"/foo/bar" relativeToDirectory:@"/foo/" expectedResult:@"bar"];
    [self testPath:@"/foo/bar/" relativeToDirectory:@"/foo" expectedResult:@"bar/"];
    
    
    
    /*  Traversing to parent folder
     */
    [self testPath:@"/foo" relativeToDirectory:@"/foo/bar" expectedResult:@".."];
    [self testPath:@"/foo" relativeToDirectory:@"/foo/bar/" expectedResult:@".."];
    [self testPath:@"/foo/" relativeToDirectory:@"/foo/bar" expectedResult:@".."]; // TODO: It would probably be nicer to return @"../" although this is valid
    
    
    /*  Only dir in common is root
     */
    [self testPath:@"/foo" relativeToDirectory:@"/baz" expectedResult:@"../foo"];
    [self testPath:@"/foo/" relativeToDirectory:@"/baz" expectedResult:@"../foo/"];
    [self testPath:@"/foo/bar" relativeToDirectory:@"/baz" expectedResult:@"../foo/bar"];
    [self testPath:@"/foo/bar/" relativeToDirectory:@"/baz" expectedResult:@"../foo/bar/"];
    [self testPath:@"/baz" relativeToDirectory:@"/foo/bar" expectedResult:@"../../baz"];
    
    
    /*  Foo dir is in common
     */
    [self testPath:@"/foo/bar" relativeToDirectory:@"/foo/baz" expectedResult:@"../bar"];
}

@end
