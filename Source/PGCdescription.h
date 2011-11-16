#import <Foundation/Foundation.h>
#import <libpq-fe.h>

@interface PGCdescription : NSObject {
    NSString *name;
    NSUInteger type_code;
    NSUInteger internal_size;
    
}

- (PGCdescription *)initWithResult: (PGresult *)pgres index: (int)index;
- (NSString *)name;
- (NSUInteger)type_code;
- (NSUInteger)internal_size;
@end
