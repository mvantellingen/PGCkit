#import "PGCdescription.h"
#import <libpq-fe.h>

@implementation PGCdescription

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (PGCdescription *)initWithResult: (PGresult *)pgres index: (int)index
{
    [self init];
    
    name = [NSString stringWithUTF8String:PQfname(pgres, index)];
    internal_size = (NSUInteger)PQfsize(pgres, index);
    type_code = (NSUInteger)PQftype(pgres, index);
    
    return self;
}

- (NSString *)name
{
    return name;
}

- (NSUInteger)internal_size
{
    return internal_size;
}

- (NSUInteger)type_code
{
    return type_code;
}

@end
