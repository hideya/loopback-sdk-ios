//
//  SLRESTAdapterSSLTests.m
//  SLRemoting
//
//  Created by Michael Schoonmaker on 6/3/13.
//  Copyright (c) 2013 StrongLoop. All rights reserved.
//

#import "SLRESTAdapterTests.h"

#import "SLRESTAdapter.h"
#import "SLObject.h"

@interface SLRESTAdapterSSLTests : SLRESTAdapterTests {
    SLRESTAdapter *adapter;
    SLRepository *TestClass;
}

@end

@implementation SLRESTAdapterSSLTests

- (void)setUp {
    [super setUp];
    
    adapter = [SLRESTAdapter adapterWithURL:[NSURL URLWithString:@"https://localhost:3002"] allowsInvalidSSLCertificate:YES];
    TestClass = [SLRepository repositoryWithClassName:@"SimpleClass"];
    TestClass.adapter = adapter;
}

- (void)tearDown {
    [super tearDown];
}

- (void)testGet {
    ASYNC_TEST_START
    [adapter invokeStaticMethod:@"simple.getSecret"
                     parameters:nil
                        success:^(id value) {
                            XCTAssertNotNil(value, @"No value returned.");
                            XCTAssertTrue([@"shhh!" isEqualToString:value[@"data"]], @"Incorrect value returned.");
                            ASYNC_TEST_SIGNAL
                        }
                        failure:ASYNC_TEST_FAILURE_BLOCK];
    ASYNC_TEST_END
}

- (void)testTransform {
    ASYNC_TEST_START
    [adapter invokeStaticMethod:@"simple.transform"
                     parameters:@{ @"str": @"somevalue" }
                        success:^(id value) {
                            XCTAssertNotNil(value, @"No value returned.");
                            XCTAssertTrue([@"transformed: somevalue" isEqualToString:value[@"data"]], @"Incorrect value returned.");
                            ASYNC_TEST_SIGNAL
                        }
                        failure:ASYNC_TEST_FAILURE_BLOCK];
    ASYNC_TEST_END
}

- (void)testTestClassGet {
    ASYNC_TEST_START
    [adapter invokeInstanceMethod:@"SimpleClass.prototype.getName"
            constructorParameters:@{ @"name": @"somename" }
                       parameters:nil
                          success:^(id value) {
                              XCTAssertNotNil(value, @"No value returned.");
                              XCTAssertTrue([@"somename" isEqualToString:value[@"data"]], @"Incorrect value returned.");
                              ASYNC_TEST_SIGNAL
                          }
                          failure:ASYNC_TEST_FAILURE_BLOCK];
    ASYNC_TEST_END
}

- (void)testTestClassTransform {
    ASYNC_TEST_START
    [adapter invokeInstanceMethod:@"SimpleClass.prototype.greet"
            constructorParameters:@{ @"name": @"somename" }
                       parameters:@{ @"other": @"othername" }
                          success:^(id value) {
                              XCTAssertNotNil(value, @"No value returned.");
                              XCTAssertTrue([@"Hi, othername!" isEqualToString:value[@"data"]], @"Incorrect value returned.");
                              ASYNC_TEST_SIGNAL
                          }
                          failure:ASYNC_TEST_FAILURE_BLOCK];
    ASYNC_TEST_END
}

- (void)testRepositoryStatic {
    ASYNC_TEST_START
    [TestClass invokeStaticMethod:@"getFavoritePerson"
                       parameters:nil
                          success:^(id value) {
                              XCTAssertNotNil(value, @"No value returned.");
                              XCTAssertTrue([@"You" isEqualToString:value[@"data"]], @"Incorrect value returned.");
                              ASYNC_TEST_SIGNAL
                          }
                          failure:ASYNC_TEST_FAILURE_BLOCK];
    ASYNC_TEST_END
}

- (void)testRepositoryGet {
    ASYNC_TEST_START
    SLObject *test = [TestClass objectWithParameters:@{ @"name": @"somename" }];
    
    [test invokeMethod:@"getName"
            parameters:nil
               success:^(id value) {
                   XCTAssertNotNil(value, @"No value returned.");
                   XCTAssertTrue([@"somename" isEqualToString:value[@"data"]], @"Incorrect value returned.");
                   ASYNC_TEST_SIGNAL
               }
               failure:ASYNC_TEST_FAILURE_BLOCK];
    ASYNC_TEST_END
}

- (void)testRepositoryTransform {
    ASYNC_TEST_START
    SLObject *test = [TestClass objectWithParameters:@{ @"name": @{ @"somekey": @"somevalue" }}];
    
    [test invokeMethod:@"greet"
            parameters:@{ @"other": @"othername" }
               success:^(id value) {
                   XCTAssertNotNil(value, @"No value returned.");
                   XCTAssertTrue([@"Hi, othername!" isEqualToString:value[@"data"]], @"Incorrect value returned.");
                   ASYNC_TEST_SIGNAL
               }
               failure:ASYNC_TEST_FAILURE_BLOCK];
    ASYNC_TEST_END
}

@end
