#import "PGCcursor.h"
#import "PGCconnection.h"
#import "PGCdescription.h"
#import "PGCadapters.h"

#import <libpq-fe.h>

@implementation PGCcursor

@synthesize rowcount;
@synthesize fields;

- (id) init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


- (void) dealloc
{
    if (pgres != NULL) {
        PQclear(pgres);
    }
}

- (PGCcursor *)initWithConnection:(PGCconnection *)connection
{
    self = [self init];
    conn = connection;
    return self;
}

- (void)execute:(NSString *)statement error:(NSError **)error
{
    ExecStatusType pgstatus;
    
    pgres = PQexec(conn.pgconn, [statement UTF8String]);

    pgstatus = PQresultStatus(pgres);    
    if (pgstatus == PGRES_TUPLES_OK) {
        rowcount = PQntuples(pgres);
        [self createFieldDescriptions];
    }
    else {
        [conn create_error:error];
    }
}

/**
 * Use the various adapters to convert the paramaters to strings and combine
 * the querystring with the parameters.
 *
 * Format is "SELECT %s, %s"
 */
- (void)execute:(NSString *)statement withParams:(NSArray *)params error:(NSError **)error;
{
    NSString *formattedStatement;
    
    formattedStatement = [self formatStatement:statement withParams:params error:error];

}

- (NSString *)formatStatement:(NSString *)statement withParams:(NSArray *)params 
                        error:(NSError **)error
{
    NSInteger bytes, index;
    const char *start, *c;
    char *p;

    NSMutableArray *quotedParams = [[NSMutableArray alloc] 
                                    initWithCapacity:[params count]];    
    NSMutableArray *stringParts = [[NSMutableArray alloc] init];
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    NSString *stringPart;    
    
    // loop through params, getquoted save as array.
    for (id param in params) {
        [quotedParams addObject:
         [AdapterManager getQuoted: param withConnection:conn]];
    }
    
    start = c = [statement UTF8String];      
    while (1) {

            
        if (*c != 0 && *c != '$') {
            c++;
            continue;
        }
        c++;
        
        // Allocate memory for part of the string
        bytes = c - start;
        p = malloc(bytes);
        strncpy(p, start, bytes - 1);
        p[bytes - 1] = 0;
        
        stringPart = [NSString stringWithCString:p encoding:NSUTF8StringEncoding];
        free(p);
        [stringParts addObject:stringPart];
    
        if (*c == 0) {
            break;
        }

        // Extract placeholder
        index = 0;
        while((int)*c >= 48 && (int)*c <= 57) {
            index += (index * 10) + ((int)*c - 48);
            c++;
        }
        
        // Params index is 0 based
        index--;        
        start = c;
        
        // Validate that the given parameter placeholder is valid
        if (index > [quotedParams count]) {
            [errorDetail 
             setValue:[NSString stringWithFormat:@"No paramter for $%d", index]
             forKey:NSLocalizedDescriptionKey];
            
            *error = [NSError errorWithDomain:@"PGC" code:1 userInfo:errorDetail];
            return nil;
        }
        
        [stringParts addObject:[quotedParams objectAtIndex:index]];
    };
    return [stringParts componentsJoinedByString:@""];
}


/**
 * Create a PGKDescription object for each column in the result
 */
- (void)createFieldDescriptions
{
    int i;
    NSMutableArray *tmp;
    PGCdescription *field;
    
    numFields = PQnfields(pgres);    
    tmp = [NSMutableArray arrayWithCapacity:numFields];
    
    for(i = 0; i < numFields; i++) {
        field = [[PGCdescription alloc] initWithResult: pgres index: i];
        [tmp insertObject:field atIndex:i];
    }
    
    fields = [NSArray arrayWithArray:tmp];
}

/**
 * Return an NSArray with all the rows
 */
- (NSArray *)fetchAll
{
    int i;
    NSMutableArray *rows = [[NSMutableArray alloc] initWithCapacity:rowcount];
    
    for (i = 0; i < rowcount; i++) {
        [rows addObject:(id)[self buildRow:i]];
    }
    return rows;
}

/**
 * Create an NSArray with the values for the given row number
 */
- (NSArray *)buildRow:(int)row
{
    int i, length;
    char *c_val;
    NSObject *object;
    NSMutableArray *objects = [[NSMutableArray alloc] initWithCapacity:numFields];
    
    for (i = 0; i < numFields; i++) {
        c_val = PQgetvalue(pgres, row, i);
        if (PQgetisnull(pgres, row, i)) {
            [objects addObject:[NSNull null]];
        }
        else {
            length = PQgetlength(pgres, row, i);
            
            // Typecast value
            object = [NSString stringWithCString:c_val encoding:conn.encoding];
            [objects addObject:object];
        }
    }
    return objects;
}

@end
