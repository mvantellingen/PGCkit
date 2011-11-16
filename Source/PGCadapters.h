#import <Foundation/Foundation.h>
#import "PGCconnection.h"


@interface AdapterManager : NSObject
{
    NSMutableDictionary *adapters;
}

+ (void)initialize;
+ (NSString *)getQuoted: (id)theValue withConnection:(PGCconnection *)theConnection;
- (id)init;
- (void)registerAdapter: (Class)theAdapter forClass: (Class)theClass;
- (NSMutableDictionary *)adapters;
@end


@interface PGCbaseAdapter : NSObject {
    id value;
    PGCconnection *conn;
}

- (id)initWithValue: (id)theValue connection:(PGCconnection *)conn;
- (NSString *)getQuoted;
@end


@interface PGCNumberAdapter : PGCbaseAdapter
@end


@interface PGCStringAdapter : PGCbaseAdapter
@end


@interface PGCDateAdapter : PGCbaseAdapter
@end



