/**
 * @file LBPersistedModel.h
 *
 * @author Michael Schoonmaker
 * @copyright (c) 2013 StrongLoop. All rights reserved.
 */

#import "LBModel.h"

/**
 * A local representative of a single persisted model instance on the server.
 * The key difference from LBModel is that this implements the CRUD operation supports.
 */
@interface LBPersistedModel : LBModel

/** All Models have a numerical `id` field. */
@property (nonatomic, readonly, copy) id _id;

/**
 * Blocks of this type are executed when LBPersistedModel::saveWithSuccess:failure: is
 * successful.
 */
typedef void (^LBPersistedModelSaveSuccessBlock)();
/**
 * Saves the LBPersistedModel to the server.
 *
 * Calls `toDictionary` to determine which fields should be saved.
 *
 * @param success  The block to be executed when the save is successful.
 * @param failure  The block to be executed when the save fails.
 */
- (void)saveWithSuccess:(LBPersistedModelSaveSuccessBlock)success
                failure:(SLFailureBlock)failure;

/**
 * Blocks of this type are executed when LBPersistedModel::destroyWithSuccess:failure: is
 * successful.
 */
typedef void (^LBPersistedModelDestroySuccessBlock)();
/**
 * Destroys the LBPersistedModel from the server.
 *
 * @param success  The block to be executed when the destroy is successful.
 * @param failure  The block to be executed when the destroy fails.
 */
- (void)destroyWithSuccess:(LBPersistedModelDestroySuccessBlock)success
                   failure:(SLFailureBlock)failure;

@end


/**
 * A local representative of a single model type on the server, encapsulating
 * the name of the model type for easy LBPersistedModel creation, discovery, and
 * management.
 */
@interface LBPersistedModelRepository : LBModelRepository

+ (instancetype)repository;

//typedef void (^LBPersistedModelExistsSuccessBlock)(BOOL exists);
//- (void)existsWithId:(id)_id
//             success:(LBPersistedModelExistsSuccessBlock)success
//             failure:(SLFailureBlock)failure;

/**
 * Blocks of this type are executed when
 * LBModelRepository::findById:success:failure: is successful.
 */
typedef void (^LBPersistedModelFindSuccessBlock)(LBPersistedModel *model);
/**
 * Finds and downloads a single instance of this model type on and from the
 * server with the given id.
 *
 * @param _id      The id to search for.
 * @param success  The block to be executed when the destroy is successful.
 * @param failure  The block to be executed when the destroy fails.
 */
- (void)findById:(id)_id
         success:(LBPersistedModelFindSuccessBlock)success
         failure:(SLFailureBlock)failure;

/**
 * Blocks of this type are executed when
 * LBPersistedModelRepository::allWithSuccess:failure: is successful.
 */
typedef void (^LBPersistedModelAllSuccessBlock)(NSArray *models);
/**
 * Finds and downloads all models of this type on and from the server.
 *
 * @param success  The block to be executed when the destroy is successful.
 * @param failure  The block to be executed when the destroy fails.
 */
- (void)allWithSuccess:(LBPersistedModelAllSuccessBlock)success
               failure:(SLFailureBlock)failure;

//typedef void (^LBPersistedModelFindOneSuccessBlock)(LBPersistedModel *model);
//- (void)findOneWithFilter:(NSDictionary *)filter
//                  success:(LBPersistedModelFindOneSuccessBlock)success
//                  failure:(SLFailureBlock)failure;

@end
