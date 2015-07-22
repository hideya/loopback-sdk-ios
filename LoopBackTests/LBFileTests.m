//
//  LBFileTests.m
//  LoopBack
//
//  Created by Stephen Hess on 2/7/14.
//  Copyright (c) 2014 StrongLoop. All rights reserved.
//

#import "LBFileTests.h"

#import "LBFile.h"
#import "LBContainer.h"
#import "LBRESTAdapter.h"

@interface LBFileTests ()

@property (nonatomic) LBFileRepository *repository;
@property (nonatomic) LBContainerRepository *containerRepo;

@end

@implementation LBFileTests

/**
 * Create the default test suite to control the order of test methods
 */
+ (id)defaultTestSuite {
    XCTestSuite *suite = [XCTestSuite testSuiteWithName:@"TestSuite for LBFile."];
    [suite addTest:[self testCaseWithSelector:@selector(testGetFile)]];
    [suite addTest:[self testCaseWithSelector:@selector(testGetAllFiles)]];
    [suite addTest:[self testCaseWithSelector:@selector(testUploadFromStream)]];
    [suite addTest:[self testCaseWithSelector:@selector(testUploadFromData)]];
    [suite addTest:[self testCaseWithSelector:@selector(testUploadAndDelete)]];
    [suite addTest:[self testCaseWithSelector:@selector(testDownload)]];
    return suite;
}


- (void)setUp {
    [super setUp];

    LBRESTAdapter *adapter = [LBRESTAdapter adapterWithURL:[NSURL URLWithString:@"http://localhost:3000"]];
    self.repository = (LBFileRepository*)[adapter repositoryWithClass:[LBFileRepository class]];

    LBRESTAdapter *adapterForContainer = [LBRESTAdapter adapterWithURL:[NSURL URLWithString:@"http://localhost:3000"]];
    self.containerRepo = (LBContainerRepository*)[adapterForContainer repositoryWithClass:[LBContainerRepository class]];

    ASYNC_TEST_START
    [self.containerRepo getContainerWithName:@"container1" success:^(LBContainer *container) {
        XCTAssertNotNil(container, @"Container not found.");
        XCTAssertEqualObjects(container.name, @"container1", @"Invalid name");
        self.repository.container = container;
        ASYNC_TEST_SIGNAL
    } failure:ASYNC_TEST_FAILURE_BLOCK];
    ASYNC_TEST_END
}

- (void)tearDown {
    [super tearDown];
}

- (void)testGetFile {
    ASYNC_TEST_START
    [self.repository getFileWithName:@"f1.txt" success:^(LBFile *file) {
        XCTAssertNotNil(file, @"File not found.");
        XCTAssertEqualObjects(file.name, @"f1.txt", @"Invalid name");
        ASYNC_TEST_SIGNAL
    } failure:ASYNC_TEST_FAILURE_BLOCK];
    ASYNC_TEST_END
}

- (void)testGetAllFiles {
    ASYNC_TEST_START
    [self.repository getAllFilesWithSuccess:^(NSArray *files) {
        XCTAssertNotNil(files, @"No file returned.");
        XCTAssertTrue(files.count >= 2, @"Invalid # of files returned: %lu", (unsigned long)files.count);
        XCTAssertTrue([[files[0] class] isSubclassOfClass:[LBFile class]], @"Invalid class.");
        XCTAssertEqualObjects(files[0][@"name"], @"f1.txt", @"Invalid name");
        XCTAssertEqualObjects(files[1][@"name"], @"f2.txt", @"Invalid name");
        ASYNC_TEST_SIGNAL
    } failure:ASYNC_TEST_FAILURE_BLOCK];
    ASYNC_TEST_END
}

- (void)testUploadFromStream {
    NSString *name = @"uploadTest.txt";
    NSString *contents = @"Testing upload from an NSInputStream";
    NSInputStream* inputStream =
    [NSInputStream inputStreamWithData:[contents dataUsingEncoding:NSUTF8StringEncoding]];
    NSUInteger bytes = [contents lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

    ASYNC_TEST_START
    [self.repository uploadWithName:name
                        inputStream:inputStream
                        contentType:@"text/plain"
                             length:bytes
                            success:^(LBFile *file) {
                                XCTAssertNotNil(file, @"File not found.");
                                XCTAssertEqualObjects(file.name, name, @"Invalid name");
                                ASYNC_TEST_SIGNAL
                            } failure:ASYNC_TEST_FAILURE_BLOCK];
    ASYNC_TEST_END
}

- (void)testUploadFromData {
    NSString *name = @"uploadTest.txt";
    NSString *contents = @"Testing upload from an NSData";
    NSData *data = [contents dataUsingEncoding:NSUTF8StringEncoding];

    ASYNC_TEST_START
    [self.repository uploadWithName:name
                               data:data
                        contentType:@"text/plain"
                            success:^(LBFile *file) {
                                XCTAssertNotNil(file, @"File not found.");
                                XCTAssertEqualObjects(file.name, name, @"Invalid name");
                                ASYNC_TEST_SIGNAL
                            } failure:ASYNC_TEST_FAILURE_BLOCK];
    ASYNC_TEST_END
}

- (void)testUploadAndDelete {
    NSString *fileName = @"uploadTest.txt";
    NSString *tmpDir = NSTemporaryDirectory();
    NSString *fullPath = [tmpDir stringByAppendingPathComponent:fileName];

    // Remove it if it currently exists...
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:fullPath]) {
        [fileManager removeItemAtPath:fullPath error:nil];
    }

    NSString *contents = @"Testing upload from a local file";
    [contents writeToFile:fullPath atomically:YES encoding:NSUTF8StringEncoding error:nil];

    ASYNC_TEST_START
    [self.repository uploadWithFilePath:fullPath
                                success:^(LBFile *file) {
        XCTAssertNotNil(file, @"File not found.");
        XCTAssertEqualObjects(file.name, fileName, @"Invalid name");

        [file deleteWithSuccess:^(void) {
            
            [self.repository getFileWithName:fileName success:^(LBFile *file) {
                XCTFail(@"File found after deletion");
            } failure:^(NSError *err) {
                ASYNC_TEST_SIGNAL
            }];

        } failure:ASYNC_TEST_FAILURE_BLOCK];

    } failure:ASYNC_TEST_FAILURE_BLOCK];
    ASYNC_TEST_END
}

- (void)testDownload {
    NSString *fileName = @"f1.txt";
    NSString *tmpDir = NSTemporaryDirectory();
    NSString *fullPath = [tmpDir stringByAppendingPathComponent:fileName];

    // Remove it if it currently exists locally...
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:fullPath]) {
        [fileManager removeItemAtPath:fullPath error:nil];
    }

    ASYNC_TEST_START
    [self.repository getFileWithName:fileName success:^(LBFile *file) {
        XCTAssertNotNil(file, @"File not found.");
        XCTAssertEqualObjects(file.name, fileName, @"Invalid name");

        [file downloadWithFilePath:fullPath
                           success:^(void) {
            XCTAssertTrue([fileManager fileExistsAtPath:fullPath], @"File missing.");
            NSString *fileContents = [NSString stringWithContentsOfFile:fullPath
                                                               encoding:NSUTF8StringEncoding
                                                                  error:nil];
            XCTAssertEqualObjects(fileContents, @"f1.txt in container1", @"File corrupted");

            ASYNC_TEST_SIGNAL
        } failure:ASYNC_TEST_FAILURE_BLOCK];
    } failure:ASYNC_TEST_FAILURE_BLOCK];
    ASYNC_TEST_END
}

@end
