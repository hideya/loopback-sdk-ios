/**
 * @file LBPersistedModel.m
 *
 * @author Michael Schoonmaker
 * @copyright (c) 2013 StrongLoop. All rights reserved.
 */

#import "LBPersistedModel.h"

#import <objc/runtime.h>

#define NSSelectorForSetter(key) NSSelectorFromString([NSString stringWithFormat:@"set%@:", [key stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[key substringToIndex:1] capitalizedString]]])


@interface LBPersistedModel() {
    id __id;
}

- (void)setId:(id)_id;

@end

@implementation LBPersistedModel

- (void)setId:(id)_id {
    __id = _id;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = (NSMutableDictionary *)[super toDictionary];
    [dict removeObjectForKey:@"_id"];
    [dict setValue:__id forKey:@"id"];

    return dict;
}

- (void)saveWithSuccess:(LBPersistedModelSaveSuccessBlock)success
                failure:(SLFailureBlock)failure {
    [self invokeMethod:self._id ? @"save" : @"create"
            parameters:[self toDictionary]
               success:^(id value) {
                   __id = [[value valueForKey:@"id"] copy];
                   success();
               }
               failure:failure];
}

- (void)destroyWithSuccess:(LBPersistedModelDestroySuccessBlock)success
                   failure:(SLFailureBlock)failure {
    [self invokeMethod:@"remove"
            parameters:[self toDictionary]
               success:^(id value) {
                   success();
               }
               failure:failure];
}

@end

@implementation LBPersistedModelRepository

+ (instancetype)repository {
    LBPersistedModelRepository *repository = [self repositoryWithClassName:@"persistentmodels"];
    repository.modelClass = [LBPersistedModel class];
    return repository;
}

- (SLRESTContract *)contract {
    SLRESTContract *contract = [super contract];

    [contract addItem:[SLRESTContractItem itemWithPattern:[NSString stringWithFormat:@"/%@", self.className] verb:@"POST"]
            forMethod:[NSString stringWithFormat:@"%@.prototype.create", self.className]];
    [contract addItem:[SLRESTContractItem itemWithPattern:[NSString stringWithFormat:@"/%@/:id", self.className] verb:@"PUT"]
            forMethod:[NSString stringWithFormat:@"%@.prototype.save", self.className]];
    [contract addItem:[SLRESTContractItem itemWithPattern:[NSString stringWithFormat:@"/%@/:id", self.className] verb:@"DELETE"]
            forMethod:[NSString stringWithFormat:@"%@.prototype.remove", self.className]];

    [contract addItem:[SLRESTContractItem itemWithPattern:[NSString stringWithFormat:@"/%@/:id", self.className] verb:@"GET"]
            forMethod:[NSString stringWithFormat:@"%@.findById", self.className]];
    [contract addItem:[SLRESTContractItem itemWithPattern:[NSString stringWithFormat:@"/%@", self.className] verb:@"GET"]
            forMethod:[NSString stringWithFormat:@"%@.all", self.className]];

    return contract;
}

- (void)findById:(id)_id
         success:(LBPersistedModelFindSuccessBlock)success
         failure:(SLFailureBlock)failure {
    NSParameterAssert(_id);
    [self invokeStaticMethod:@"findById"
                  parameters:@{ @"id": _id }
                     success:^(id value) {
                         NSAssert([[value class] isSubclassOfClass:[NSDictionary class]], @"Received non-Dictionary: %@", value);
                         success((LBPersistedModel*)[self modelWithDictionary:value]);
                     } failure:failure];
}

- (void)allWithSuccess:(LBPersistedModelAllSuccessBlock)success
               failure:(SLFailureBlock)failure {
    [self invokeStaticMethod:@"all"
                  parameters:@{}
                     success:^(id value) {
                         NSAssert([[value class] isSubclassOfClass:[NSArray class]], @"Received non-Array: %@", value);

                         NSMutableArray *models = [NSMutableArray array];

                         [value enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                             [models addObject:[self modelWithDictionary:obj]];
                         }];

                         success(models);
                     }
                     failure:failure];
}


@end
