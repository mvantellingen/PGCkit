#import "cursorTests.h"
#import "PGCconnection.h"
#import "PGCdescription.h"

@implementation PGcursorTests

- (void)setUp
{
    [super setUp];
    
    NSError *error = nil;
    conn = [[PGCconnection alloc] init];
    [conn connect:@"host=127.0.0.1 dbname=pgview_tests" error:&error];
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
    
    [conn close];
}

- (void)testExecute
{
    PGCcursor *cursor = [conn cursor];
    NSError *error = nil;
    
    [cursor execute:@"SELECT 1" error:&error];
    STAssertNil(error, @"Error check");
    STAssertEquals(cursor.rowcount, 1, @"Rowcount test");
}

- (void)testExecuteWithParams
{
    PGCcursor *cursor = [conn cursor];
    NSError *error = nil;
    
    NSMutableArray *params = [[NSMutableArray alloc] init];
    [params addObject:@"1"];
    [params addObject:@"foobar"];
    [params addObject:[NSDate date]];


    [cursor execute:@"SELECT $1, $2, $5123" withParams: params error:&error];
    
}

- (void)testDescription
{
    PGCcursor *cursor = [conn cursor];
    PGCdescription *field;
    NSError *error = nil;
    NSString *column;
    
    [cursor execute:@"SELECT 1 AS column_1, 2 AS column_2, 3 AS column_3" error:&error];
    STAssertEquals([cursor.fields count], (NSUInteger)3 , @"3 fields");

    for(int i = 0; i < 3; i++) {
        field = [cursor.fields objectAtIndex: i];
        column = [NSString stringWithFormat:@"column_%d", i + 1];
        
        STAssertEqualObjects(column, field.name, @"name mismatch");
        STAssertEquals((NSUInteger)23, field.type_code, @"Typecode incorrect");
    }
}

- (void)testFetchAll
{
    PGCcursor *cursor = [conn cursor];
    NSError *error = nil;
    NSArray *rows;
    NSArray *row;
    NSString *expected;
    
    [cursor execute:@"SELECT 'foo', s.a, s.a * 2 FROM generate_series(0, 100) AS s(a)" 
              error:&error];
    rows = [cursor fetchAll];
    STAssertNil(error, @"Error in select");
    
    for (int i = 0; i < 100; i++) {
        row = [rows objectAtIndex: i];
        
        STAssertEqualObjects([row objectAtIndex: 0], @"foo", @"Not equal");
        
        expected = [NSString stringWithFormat:@"%d", i];
        STAssertEqualObjects([row objectAtIndex: 1], expected, @"Not equal");

        expected = [NSString stringWithFormat:@"%d", i * 2];
        STAssertEqualObjects([row objectAtIndex: 2], expected, @"Not equal");
    }
}

- (void)testFormatStatement
{
    PGCcursor *cursor = [conn cursor];
    NSError *error = nil;

    NSMutableArray *params = [[NSMutableArray alloc] init];
    [params addObject:[NSNumber numberWithInt:1]];
    [params addObject:@"foobar"];
    [params addObject:[[NSDate alloc] initWithString:@"2010-12-31 00:00:00 +0100"]];
    [params addObject:[NSNumber numberWithFloat:1.234]];
    
    NSString *query = [cursor 
                       formatStatement: @"SELECT $1, $2, $4, 'foo', $3 FROM foo" 
                       withParams: params 
                       error:&error];    
    

    STAssertEqualObjects(query, @"SELECT 1, E'foobar', 1.234, 'foo', '2010-12-31'::date FROM foo", @"ok");
}

@end
