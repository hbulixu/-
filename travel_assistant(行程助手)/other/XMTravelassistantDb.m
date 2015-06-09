//
//  XMTravelassistantDb.m
//  旅游箱
//
//  Created by 梁亦明 on 15/4/5.
//  Copyright (c) 2015年 xiaoming. All rights reserved.

#import "XMTravelassistantDb.h"
#import "FMDB.h"
#import "XMTravelassistantModel.h"
#import "XMTravelassistantNoteModel.h"
#import "XMTravelassistantTouristModel.h"

@interface XMTravelassistantDb ()
@property (nonatomic,strong) FMDatabaseQueue *queue;
@end

@implementation XMTravelassistantDb
- (instancetype)init
{
    self = [super init];
    if (self) {
        //获取数据库对象
        NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"tour.sqlite"];
        self.queue = [FMDatabaseQueue databaseQueueWithPath:path];
    }
    return self;
}
/** 查询当前旅游城市和日期*/
-(NSDictionary *)selectTourDate
{
    NSString *cityData = @"SELECT * FROM startTour";
    __block NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [self.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *set = [db executeQuery:cityData];
        while (set.next) {
            dict[@"startDate"] = [set stringForColumn:@"startDate"];
            dict[@"endDate"] = [set stringForColumn:@"endFromDate"];
        }
    }];
    return dict;
}

-(BOOL) isSetupCity
{
    NSString *sql = @"SELECT * FROM startTour";
    __block BOOL flag = false;
    [self.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *set = [db executeQuery:sql];
        if (set.next) {
            flag = true;
        }
    }];
    return flag;
}


-(NSString *)selectRateWithCode:(NSString *)code
{
    NSString *selectSql = @"SELECT rate FROM exrate WHERE code = ?";
    __block NSString *rate = nil;
    [self.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *set = [db executeQuery:selectSql,code];
        while (set.next) {
            rate = [set stringForColumn:@"rate"];
        }
    }];
    return rate;
}


-(NSMutableArray *) selectAccountData:(NSString *)date
{
    __block NSMutableArray *array = [NSMutableArray array];
    NSString *sql = @"SELECT exrate,money FROM accounts WHERE date = ?";
    [self.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *set = [db executeQuery:sql,date];
        while (set.next) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            dict[@"exrate"] = [set stringForColumn:@"exrate"];
            dict[@"money"] = [set stringForColumn:@"money"];
            [array addObject:dict];
        }
    }];
    return array;
}

-(NSMutableArray *) selectTravelassistantData
{
    NSString *sql = @"SELECT * FROM travelassistant";
    __block NSMutableArray *array = [NSMutableArray array];
    [self.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *set = [db executeQuery:sql];
        while (set.next) {
            XMTravelassistantModel *model = [[XMTravelassistantModel alloc] init];
            model.city = [set stringForColumn:@"city"];
            model.time = [set stringForColumn:@"time"];
            model.money = [set stringForColumn:@"money"];
            model.noteCount = [set intForColumn:@"noteCount"];
            model.touristCount = [set intForColumn:@"touristCount"];
            model.hotel = [set stringForColumn:@"hotel"];
            model.diary = [set intForColumn:@"diary"];
            model.cityType = [set stringForColumn:@"cityType"];
            [array addObject:model];
        }
    }];
    return array;
}
-(int)selectTravelassistantDataWithCityType:(NSString *)cityType colmnName:(NSString *)colmnName
{
    NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM travelassistant WHERE cityType = ?",colmnName];
    __block int count;
    [self.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *set = [db executeQuery:sql,cityType];
        while (set.next) {
            count = [set intForColumn:colmnName];
        }
    }];
    return count;
}

-(void)upDateTravelassistantWithMoney:(NSString *)money cityType:(NSString *)cityType
{
    NSString *sql = @"UPDATE travelassistant SET money = ? WHERE cityType = ?";
    [self.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:sql,[NSString stringWithFormat:@"¥ %@",money],cityType];
    }];
}

-(void)upDateTravelassistantWithCity:(NSString *)city time:(NSString *)time cityType:(NSString *)cityType
{
    NSString *sql = @"UPDATE travelassistant SET city = ?,time = ? WHERE cityType = ?";
    [self.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:sql,city,time,cityType];
    }];
}

-(void)upDateTravelassistantWithColmnName:(NSString *)colmnName colmnValue:(int)colmnValue cityType:(NSString *)cityType
{
    NSString *sql = [NSString stringWithFormat:@"UPDATE travelassistant SET %@ = ? WHERE cityType = ?",colmnName];
    [self.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:sql,[NSNumber numberWithInt:colmnValue],cityType];
    }];
}

-(BOOL)selectTableWithTableName:(NSString *)tableName
{
    __block BOOL flag = false;
    NSString *sql = @"SELECT COUNT(*) AS 'count' from sqlite_master where type ='table' and name = ?";
    [self.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *set = [db executeQuery:sql,tableName];
        while (set.next) {
            NSInteger count = [set intForColumn:@"count"];
            flag = count == 0 ? false:true;
        }
    }];
    return flag;
}

-(BOOL)selectTableDataWithTableName:(NSString *)tableName
{
    __block BOOL flag = false;
    NSString *sql = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@",tableName];
    [self.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *set = [db executeQuery:sql,tableName];
        while (set.next) {
            NSInteger count = [set intForColumnIndex:0];
            flag = count == 0 ? false:true;
        }
    }];
    return flag;
}


-(void)createNoteTable
{
    NSString *sql = @"CREATE TABLE IF NOT EXISTS note(id INTEGER PRIMARY KEY AUTOINCREMENT,noteText TEXT,noteTime Text,cityType Text)";
    [self.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:sql];
    }];
}

-(void)insertNoteWithModel:(XMTravelassistantNoteModel *)model
{
    NSString *sql = @"INSERT INTO note (noteText,noteTime,cityType) VALUES (?,?,?)";
    [self.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:sql,model.noteText,model.noteTime,model.cityType];
    }];
}
-(NSMutableArray *)selectNoteAllDataWithCityType:(NSString *) cityType
{
    NSString *sql = @"SELECT * FROM note WHERE cityType = ?";
    __block NSMutableArray *array = [NSMutableArray array];
    [self.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *set = [db executeQuery:sql,cityType];
        while (set.next) {
            XMTravelassistantNoteModel *model = [[XMTravelassistantNoteModel alloc] init];
            model.noteText = [set stringForColumn:@"noteText"];
            model.noteTime = [set stringForColumn:@"noteTime"];
            model.cityType = [set stringForColumn:@"cityType"];
            [array addObject:model];
        }
    }];
    return array;
}
-(void)deleteNoteDataWithNoteModel:(XMTravelassistantNoteModel *)model
{
    NSString *sql = @"DELETE FROM note WHERE noteText = ? AND noteTime = ?";
    [self.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:sql,model.noteText,model.noteTime];
    }];
}

-(void)createTouristTable
{
    NSString *sql = @"CREATE TABLE IF NOT EXISTS tourist(id INTEGER PRIMARY KEY AUTOINCREMENT,tourName TEXT,tourLocation Text,cityType Text,tourMoney TEXT,tourExrate TEXT)";
    [self.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:sql];
    }];
}

-(void)insertTouristWithModel:(XMTravelassistantTouristModel *)model
{
    NSString *sql = @"INSERT INTO tourist(tourName,tourLocation,cityType,tourMoney,tourExrate) VALUES (?,?,?,?,?)";
    [self.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:sql,model.tourName,model.tourLocation,model.cityType,model.tourMoney,model.tourExrate];
    }];
}

-(NSMutableArray *)selectTouristAllDataWithCityType:(NSString *)cityType
{
    __block NSMutableArray *array = [NSMutableArray array];
    NSString *sql = @"SELECT * FROM tourist WHERE cityType = ?";
    [self.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *set = [db executeQuery:sql,cityType];
        while (set.next) {
            XMTravelassistantTouristModel *model = [[XMTravelassistantTouristModel alloc] init];
            model.tourName = [set stringForColumn:@"tourName"];
            model.tourLocation = [set stringForColumn:@"tourLocation"];
            model.cityType = [set stringForColumn:@"cityType"];
            model.tourMoney = [set stringForColumn:@"tourMoney"];
            model.tourExrate = [set stringForColumn:@"tourExrate"];
            [array addObject:model];
        }
    }];
    return array;
}
@end
