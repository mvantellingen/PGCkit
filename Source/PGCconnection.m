#import <libpq-fe.h>
#import "PGCconnection.h"
#import "PGCcursor.h"

@implementation PGCconnection

@synthesize closed;
@synthesize use_equote;
@synthesize encoding;
@synthesize notices;
@synthesize pgconn;

static void notice_processor(void *arg, const char *message)
{
    [(PGCconnection *)arg processNotice:message];


}
                              
- (id)init
{
    self = [super init];
    if (self) {
        closed = true;
        encodingName = @"UTF8";
        encoding = NSUTF8StringEncoding;
        notices = [[NSMutableArray alloc] initWithCapacity:50];
        use_equote = true;        
    }
    
    return self;
}

- (void)dealloc
{
    if (!closed) {
        [self close];
    }
}

/**
 * Connect to the server via a dsn string
 */
- (BOOL)connect:(NSString *)dsn error:(NSError **)error
{    
    pgconn = PQconnectdb([dsn UTF8String]);
    if (!pgconn) {
        *error = [NSError errorWithDomain:@"pgkit" code:-1 userInfo:nil];
        return false;
    }
    
    if (PQstatus(pgconn) == CONNECTION_BAD) {
        [self create_error:error];
        return false;
    }
    
    closed = false;
    [self setup];
    return true;
}

/**
 * Connect to server via arguments.
 *
 * This method builds a dsn string and calls [self connect:dsn]
 */
- (BOOL)connect:(NSString *)host port:(int)port user:(NSString *)user
       password:(NSString *)password database:(NSString *)database
          error: (NSError **)error
{
    NSString *dsn;
    NSMutableArray *dsn_parts = [[NSMutableArray alloc] init];
    
    if (host != nil) {
        [dsn_parts addObject:[NSString stringWithFormat:@"host=%@", host]];
    }
    if (port != NULL) {
        [dsn_parts addObject:[NSString stringWithFormat:@"port=%d", port]];        
    }
    if (user != nil) {
        [dsn_parts addObject:[NSString stringWithFormat:@"user=%@", user]];
    }
    if (password != nil) {
        [dsn_parts addObject:[NSString stringWithFormat:@"password=%@", password]];
    }
    if (database != nil) {
        [dsn_parts addObject:[NSString stringWithFormat:@"dbname=%@", database]];
    }
 
    dsn = [dsn_parts componentsJoinedByString:@" "];
    return [self connect:dsn error:error];
}

- (void)close
{
    PQfinish(pgconn);
    closed = true;
}

-(void)create_error:(NSError **)error
{
    const char * message = PQerrorMessage(pgconn);
    
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail 
        setValue:[NSString stringWithUTF8String:message] 
        forKey:NSLocalizedDescriptionKey];
    *error = [NSError errorWithDomain:@"pgkit" code:-2 userInfo: errorDetail];    
}

/**
 * Setup the connection. 
 */
-(void)setup
{
    const char *res;
    
    // Register the notice processor
    PQsetNoticeProcessor(pgconn, notice_processor, self);
    
    // Find out if standard conforming strings are enabled. Otherwise we need to
    // use the E'' query syntax.
    res = PQparameterStatus(pgconn, "standard_conforming_strings");
    use_equote = (res && strncmp(res, "off", 3) == 0);

    // Get the client encoding value
    res = PQparameterStatus(pgconn, "client_encoding");
    encodingName = [NSString stringWithUTF8String:res];
    encoding = [self getClientEncoding:res];
}

/**
 * Return the NSStringEncoding for the postgresql client encoding value
 * 
 * TODO: Most encodings are still missing
 */
-(NSStringEncoding)getClientEncoding:(const char *)name
{
    if (strcmp(name, "UTF8") == 0) {
        return NSUTF8StringEncoding;
    }
    if (strcmp(name, "LATIN1") == 0) {
        return NSISOLatin1StringEncoding;
    }
    
    // throw exception
    return 0;
}

/**
 * Store the given message in the notices array. At most 50 items are kept.
 * This method is called by the c callback function notice_processor
 */
- (void)processNotice:(const char *)message
{
    NSString *theMessage = [NSString stringWithCString:message 
                                              encoding:encoding];
    
    // Don't store more then 50 notices
    while ([notices count] >= 50) {
        [notices removeObjectAtIndex:0];
    }
    [notices addObject:theMessage];
}

-(PGCcursor *)cursor
{
    return [[PGCcursor alloc] initWithConnection:self];
}
@end
