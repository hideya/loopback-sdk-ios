/**
 * @file LBFile.h
 *
 * @author Stephen Hess
 * @copyright (c) 2014 StrongLoop. All rights reserved.
 */

#import "LBModel.h"

@class LBContainer;

/**
 * A local representative of a file instance on the server.
 */
@interface LBFile : LBModel

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) LBContainer *container;

/**
 * Blocks of this type are executed when
 * LBFile:downloadWithSuccess:failure: is successful.
 */
typedef void (^LBFileDownloadSuccessBlock)();
/**
 * Downloads the file from the server.
 *
 * @param success  The block to be executed when the download is successful.
 * @param failure  The block to be executed when the download fails.
 */
- (void)downloadWithFilePath:(NSString *)localPath
                     success:(LBFileDownloadSuccessBlock)success
                     failure:(SLFailureBlock)failure;

- (void)downloadWithOutputStream:(NSOutputStream *)outputStream
                         success:(LBFileDownloadSuccessBlock)success
                         failure:(SLFailureBlock)failure;

typedef void (^LBFileDownloadToDataSuccessBlock)(NSData *data);

- (void)downloadAsDataWithSuccess:(LBFileDownloadToDataSuccessBlock)success
                          failure:(SLFailureBlock)failure;


/**
 * Blocks of this type are executed when
 * LBFile:deleteWithSuccess:failure: is successful.
 */
typedef void (^LBFileDeleteSuccessBlock)();
/**
 * Delete the file from the server.
 *
 * @param success  The block to be executed when the deletion is successful.
 * @param failure  The block to be executed when the deletion fails.
 */
- (void)deleteWithSuccess:(LBFileDeleteSuccessBlock)success
                  failure:(SLFailureBlock)failure;

@end

/**
 * A local representative of the File type on the server.
 */
@interface LBFileRepository : LBModelRepository

+ (instancetype)repository;

@property (nonatomic, strong) LBContainer *container;

typedef void (^LBFileUploadSuccessBlock)(LBFile* file);

- (void)uploadWithFilePath:(NSString *)localPath
                   success:(LBFileUploadSuccessBlock)success
                   failure:(SLFailureBlock)failure;

- (void)uploadWithName:(NSString *)name
                  data:(NSData *)data
           contentType:(NSString *)contentType
               success:(LBFileUploadSuccessBlock)success
               failure:(SLFailureBlock)failure;

- (void)uploadWithName:(NSString *)name
           inputStream:(NSInputStream *)inputStream
           contentType:(NSString *)contentType
                length:(NSInteger)length
               success:(LBFileUploadSuccessBlock)success
               failure:(SLFailureBlock)failure;


/**
 * Blocks of this type are executed when
 * LBFileRepository::getFileWithName:success:failure: is successful.
 */
typedef void (^LBFileGetSuccessBlock)(LBFile* file);
/**
 * Gets the file with the given name.
 *
 * @param  name       The file name.
 * @param  success    The block to be executed when the get is successful.
 * @param  failure    The block to be executed when the get fails.
 */
- (void)getFileWithName:(NSString*)name
                success:(LBFileGetSuccessBlock)success
                failure:(SLFailureBlock)failure;

typedef void (^LBGetAllFilesSuccessBlock)(NSArray* files);
- (void)getAllFilesWithSuccess:(LBGetAllFilesSuccessBlock)success
                       failure:(SLFailureBlock)failure;


@end