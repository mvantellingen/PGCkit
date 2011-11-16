#import "PGCadapters.h"
#import "PGCconnection.h"

static AdapterManager *adapterSingleton;


@implementation AdapterManager
+ (void)initialize
{
    static BOOL initialized = NO;
    if(!initialized)
    {
        initialized = YES;
        adapterSingleton = [[AdapterManager alloc] init];
    }
}

- (id)init
{
    self = [super init];
    if (self) {
        adapters = [[NSMutableDictionary alloc] init];
        
        // Register all the classes
        [self registerAdapter: [PGCNumberAdapter class] forClass: [NSNumber class]];
        [self registerAdapter: [PGCStringAdapter class] forClass: [NSString class]];
        [self registerAdapter: [PGCDateAdapter class] forClass: [NSDate class]];
    }
    return self;
}

+ (NSString *)getQuoted: (id)theValue withConnection:(PGCconnection *)theConnection
{
    Class adapterClass;
    id adapter;
    
    
    adapterClass = [adapterSingleton.adapters objectForKey: [theValue class]];
    if (adapterClass == nil) {
        for (id key in adapterSingleton.adapters) {
            if ([theValue isKindOfClass:key]) {
                adapterClass =[adapterSingleton.adapters objectForKey: key];
                break;
            }
        }
        
        if (adapterClass == nil) {
            [NSException raise:@"FOO" format:@"No adapter found for class %s", 
             [[theValue className] UTF8String]];        
        }
    }
    
    adapter = [[adapterClass alloc] initWithValue: theValue 
                                       connection: theConnection];
    return [adapter getQuoted];
}

- (NSMutableDictionary *)adapters
{
    return adapters;
}

- (void)registerAdapter: (Class)theAdapter forClass: (Class)theClass
{
    [adapters setObject: theAdapter forKey: theClass];
}

@end



@implementation PGCbaseAdapter

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (id)initWithValue: (id)theValue connection:(PGCconnection *)theConnection
{
    [self init];
    value = theValue;
    conn = theConnection;
    return self;
}

- (NSString *)getQuoted
{
    NSAssert(NO, @"Not implemented");
    return nil;
}

@end


@implementation PGCNumberAdapter : PGCbaseAdapter
- (NSString *)getQuoted 
{
    NSNumber *theValue = (NSNumber *)value;
    return [theValue stringValue];
}
@end

@implementation PGCStringAdapter : PGCbaseAdapter
 - (NSString *)getQuoted 
{
    NSInteger length = [value length];
    NSString *result;
    int error;
    char *buffer = malloc((length * 2) + 1);
    const char *val;
    
    
    if (conn == nil) {
        val = [value cStringUsingEncoding:NSUTF8StringEncoding];
        PQescapeString(buffer, val, length);
        result = [NSString stringWithFormat:@"'%s'", buffer];        
        
    }
    else {
        val = [value cStringUsingEncoding:conn.encoding];

        PQescapeStringConn(conn.pgconn, buffer, val, length, &error);
        if (error != 0) {
            free(buffer);
            NSException *theException = [NSException
                                         exceptionWithName:@"EscapeError"
                                         reason:@"Unable to escape"
                                         userInfo:nil];
            @throw theException;
        }
        
        if (conn.use_equote) {
            result = [NSString stringWithFormat:@"E'%s'", buffer];        
        }
        else {
            result = [NSString stringWithFormat:@"'%s'", buffer];        
        }
    }
    

    free(buffer);
    return result;
}
@end


@implementation PGCDateAdapter : PGCbaseAdapter
- (NSString *)getQuoted 
{
    NSString *result;
    NSDate *theValue = (NSDate *)value;
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyy-MM-dd"];

    result = [NSString stringWithFormat:@"'%@'::date", 
              [format stringFromDate:theValue]];
    
    return result;
}
@end


