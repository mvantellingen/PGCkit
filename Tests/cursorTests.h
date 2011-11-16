#import <SenTestingKit/SenTestingKit.h>
#import "PGCconnection.h"


@interface PGcursorTests : SenTestCase {
    PGCconnection *conn;
}

- (void)testExecute;

@end