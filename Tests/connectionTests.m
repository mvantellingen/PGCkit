#import "connectionTests.h"
#import "PGCconnection.h"
#import "PGCcursor.h"


@implementation PGconnectionTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testConnect
{
    NSError *error = nil;
    PGCconnection *conn = [[PGCconnection alloc] init];
    
    [conn connect:@"dbname=pgview_tests host=127.0.0.1 user=postgres" 
            error:&error];     
    STAssertNil(error, @"Unable to connect");
    STAssertFalse(conn.closed, @"Error");
    [conn close];
}

- (void)testConnectTo
{
    NSError *error = nil;
    PGCconnection *conn = [[PGCconnection alloc] init];
    
    [conn connect: @"127.0.0.1" port: 5432 user: @"postgres"
         password: nil database: @"postgres" error:&error];
    STAssertNil(error, @"Unable to connect");
    STAssertFalse(conn.closed, @"Error");
    [conn close];
}

- (void)testConnectError
{
    NSError *error = nil;
    
    PGCconnection *conn = [[PGCconnection alloc] init];
            
    [conn connect:@"dbname=pgview_tests host=127.0.0.1 user=nonexistant" error:&error];     
    STAssertNotNil(error, @"User should be invalid");
    STAssertTrue(conn.closed, @"Error");
    [conn close];
}

- (void)testNotices
{
    NSError *error = nil;
    PGCconnection *conn = [[PGCconnection alloc] init];
                           
    [conn connect:@"dbname=pgview_tests host=127.0.0.1 user=postgres" error:&error];     
    
    PGCcursor *cursor = [conn cursor];

    [cursor execute:@"CREATE TEMP TABLE notice_test_1 (id SERIAL);"
                     "CREATE TEMP TABLE notice_test_2 (id SERIAL);"
              error:&error];
    
    STAssertTrue([conn.notices count] == 2, @"conn.notices has %d notices",
                 [conn.notices count]);

    [conn close];
}
@end
