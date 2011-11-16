#import <Foundation/Foundation.h>
#import <libpq-fe.h>
#import "PGCcursor.h"

@interface PGCconnection : NSObject {

    PGconn *pgconn;
    NSString *encodingName;
}

@property (readonly) BOOL closed;
@property (readonly) BOOL use_equote;
@property (readonly) NSStringEncoding encoding;
@property (readonly) PGconn *pgconn;
@property (retain) NSMutableArray *notices;


- (NSStringEncoding)getClientEncoding:(const char *)name;
- (BOOL)connect:(NSString *)dsn error:(NSError **)error;
- (BOOL)connect:(NSString *)host port:(int)port user:(NSString *)user
       password:(NSString *)password database:(NSString *)database
          error: (NSError **)error;

- (void)close;
- (void)create_error:(NSError **)error;
- (void)setup;
- (void)processNotice:(const char *)message;
- (PGCcursor *)cursor;
@end
