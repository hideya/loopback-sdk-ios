/**
 * @file LBFile.m
 *
 * @author Stephen Hess
 * @copyright (c) 2014 StrongLoop. All rights reserved.
 */

#import "LBFile.h"
#import "LBContainer.h"
#import "LBRESTAdapter.h"
#import "SLStreamParam.h"

static NSString *mimeTypeForFileName(NSString *fileName) {
    CFStringRef pathExtension = (__bridge_retained CFStringRef)[fileName pathExtension];
    CFStringRef type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                             pathExtension,
                                                             NULL);
    CFRelease(pathExtension);
    NSString *mimeType =
        (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType);

    return (mimeType != nil) ? mimeType : @"application/octet-stream";
}

@implementation LBFile

- (void)downloadWithOutputStream:(NSOutputStream *)outputStream
                         success:(LBFileDownloadSuccessBlock)success
                         failure:(SLFailureBlock)failure {
    [self invokeMethod:@"download"
            parameters:@{ @"name": self.name, @"container": self.container.name }
          outputStream:outputStream
               success:success
               failure:failure];
}

- (void)downloadWithFilePath:(NSString *)localPath
                     success:(LBFileDownloadSuccessBlock)success
                     failure:(SLFailureBlock)failure {
    NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:localPath
                                                                     append:NO];

    [self downloadWithOutputStream:outputStream
                           success:^(id value) {
                               [outputStream close];
                               success();
                           }
                           failure:^(NSError *err) {
                               [outputStream close];
                               failure(err);
                           }];
}

- (void)downloadAsDataWithSuccess:(LBFileDownloadToDataSuccessBlock)success
                          failure:(SLFailureBlock)failure {
    NSOutputStream *outputStream = [[NSOutputStream alloc] initToMemory];

    [self downloadWithOutputStream:outputStream
                           success:^(id value) {
                               NSData *data = [outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
                               success(data);
                           }
                           failure:^(NSError *err) {
                               [outputStream close];
                               failure(err);
                           }];
}

- (void)deleteWithSuccess:(LBFileDeleteSuccessBlock)success
                  failure:(SLFailureBlock)failure {
    [self invokeMethod:@"delete"
            parameters:@{ @"name": self.name, @"container": self.container.name }
               success:^(id value) {
                   success();
               }
               failure:failure];
}

@end

@implementation LBFileRepository

+ (instancetype)repository {
    LBFileRepository *repository = [self repositoryWithClassName:@"containers"];
    repository.modelClass = [LBFile class];
    return repository;
}

- (SLRESTContract *)contract {
    SLRESTContract *contract = [super contract];

    [contract addItem:[SLRESTContractItem itemWithPattern:[NSString stringWithFormat:@"/%@/:container/files/:name", self.className]
                                                     verb:@"GET"]
            forMethod:[NSString stringWithFormat:@"%@.get", self.className]];
    [contract addItem:[SLRESTContractItem itemWithPattern:[NSString stringWithFormat:@"/%@/:container/files", self.className]
                                                     verb:@"GET"]
            forMethod:[NSString stringWithFormat:@"%@.getAll", self.className]];
    [contract addItem:[SLRESTContractItem itemWithPattern:[NSString stringWithFormat:@"/%@/:container/upload", self.className]
                                                     verb:@"POST"
                                                multipart:YES]
            forMethod:[NSString stringWithFormat:@"%@.upload", self.className]];
    [contract addItem:[SLRESTContractItem itemWithPattern:[NSString stringWithFormat:@"/%@/:container/download/:name", self.className]
                                                     verb:@"GET"]
            forMethod:[NSString stringWithFormat:@"%@.prototype.download", self.className]];
    [contract addItem:[SLRESTContractItem itemWithPattern:[NSString stringWithFormat:@"/%@/:container/files/:name", self.className]
                                                     verb:@"DELETE"]
            forMethod:[NSString stringWithFormat:@"%@.prototype.delete", self.className]];
    
    return contract;
}

- (void)uploadWithFilePath:(NSString*)localPath
                   success:(LBFileGetSuccessBlock)success
                   failure:(SLFailureBlock)failure {

    NSString *name = [localPath lastPathComponent];

    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:localPath
                                                                                error:nil];
    NSInteger length = attributes.fileSize;

    NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:localPath];
    NSString *contentType = mimeTypeForFileName(localPath);

    [self uploadWithName:name
             inputStream:inputStream
             contentType:contentType
                  length:length
                 success:success
                 failure:failure];
}

- (void)uploadWithName:(NSString *)name
                  data:(NSData *)data
           contentType:(NSString *)contentType
               success:(LBFileUploadSuccessBlock)success
               failure:(SLFailureBlock)failure {

    NSInputStream *inputStream = [[NSInputStream alloc] initWithData:data];

    [self uploadWithName:name
             inputStream:inputStream
             contentType:contentType
                  length:data.length
                 success:success
                 failure:failure];
}

- (void)uploadWithName:(NSString *)name
           inputStream:(NSInputStream *)inputStream
           contentType:(NSString *)contentType
                length:(NSInteger)length
               success:(LBFileUploadSuccessBlock)success
               failure:(SLFailureBlock)failure {

    __block SLStreamParam *streamParam = [SLStreamParam streamParamWithInputStream:inputStream
                                                                          fileName:name
                                                                       contentType:contentType
                                                                            length:length];

    [self invokeStaticMethod:@"upload"
                  parameters:@{@"container": self.container.name,
                               @"name": name,
                               @"file": streamParam}
                     success:^(id value) {

                         NSAssert([[value class] isSubclassOfClass:[NSDictionary class]], @"Received non-Dictionary: %@", value);
                         LBFile *file = (LBFile*)[self modelWithDictionary:@{ @"name": name }];
                         file.container = self.container;
                         success(file);
                     }
                     failure:failure];
}

- (void)getFileWithName:(NSString*)name
                success:(LBFileGetSuccessBlock)success
                failure:(SLFailureBlock)failure {
    NSParameterAssert(name);

    [self invokeStaticMethod:@"get"
                  parameters:@{ @"name": name,
                                @"container" : self.container.name }
                     success:^(id value) {
                         NSAssert([[value class] isSubclassOfClass:[NSDictionary class]], @"Received non-Dictionary: %@", value);
                         LBFile *file = (LBFile*)[self modelWithDictionary:@{ @"name": name }];
                         file.container = self.container;
                         success(file);
                     } failure:failure];
}


- (void)getAllFilesWithSuccess:(LBGetAllFilesSuccessBlock)success
                       failure:(SLFailureBlock)failure {

    [self invokeStaticMethod:@"getAll"
                  parameters:@{ @"container": self.container.name }
                     success:^(id value) {
                         NSAssert([[value class] isSubclassOfClass:[NSArray class]], @"Received non-Array: %@", value);
                         NSArray* response = (NSArray*)value;
                         NSMutableArray *files = [NSMutableArray arrayWithCapacity:response.count];
                         for (id respVal in response) {
                             NSAssert([[respVal class] isSubclassOfClass:[NSDictionary class]], @"Received non-Dictionary: %@", respVal);
                             LBFile *file = (LBFile*)[self modelWithDictionary:(NSDictionary*)respVal];
                             [files addObject:file];
                         }
                         success(files);
                     } failure:failure];
}

@end