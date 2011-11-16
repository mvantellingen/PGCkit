#import <Foundation/Foundation.h>
#import <libpq-fe.h>


@class PGCconnection;

@interface PGCcursor : NSObject {
    PGCconnection *conn;
    PGresult *pgres;
    NSInteger numFields;
}

@property (readonly) NSArray *fields;
@property (readonly) int rowcount;


- (PGCcursor *)initWithConnection:(PGCconnection *)connection;

- (void)execute:(NSString *)statement error:(NSError **)error;
- (void)execute:(NSString *)statement withParams:(NSArray *)params 
          error:(NSError **)error;
- (void)createFieldDescriptions;
- (NSArray *)buildRow:(int)row;
- (NSArray *)fetchAll;
- (NSString *)formatStatement:(NSString *)statement withParams:(NSArray *)params 
                        error:(NSError **)error;
@end
