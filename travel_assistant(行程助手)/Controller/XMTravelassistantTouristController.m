//
//  XMTravelassistantTouristController.m
//  旅游箱
//
//  Created by 梁亦明 on 15/4/8.
//  Copyright (c) 2015年 xiaoming. All rights reserved.
//

#import "XMTravelassistantTouristController.h"
#import "XMTravelassistantDb.h"
#import "XMTravelassistantSetView.h"
#import "XMTravelassistantNewTourist.h"
#import "XMTravelassistantTouristCell.h"
#import "UIView+XM.h"
#import "XMTravelassistantTouristButtomView.h"

#define viewHeight self.view.frame.size.height
#define viewWidth self.view.frame.size.width

@interface XMTravelassistantTouristController ()<XMTravelassistantSetViewDelegate,UITableViewDataSource,UITableViewDelegate,XMTravelassistantNewTouristDelegate>
/** 数据库*/
@property (nonatomic,strong) XMTravelassistantDb *db;
/** 新建景点*/
@property (nonatomic,weak) XMTravelassistantSetView *setView;
/** 景点数组*/
@property (nonatomic,strong) NSMutableArray *touristArray;
/** tableView*/
@property (nonatomic,weak) UITableView *centerView;
@end

@implementation XMTravelassistantTouristController
-(NSMutableArray *)touristArray
{
    if (!_touristArray) _touristArray = [self.db selectTouristAllDataWithCityType:self.cityType];
    return _touristArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"景点规划";
    self.view.backgroundColor = [UIColor colorWithRed:247/255.0 green:247/255.0 blue:247/255.0 alpha:1];
    //判断当前数据库是否有记录
    XMTravelassistantDb *db = [[XMTravelassistantDb alloc] init];
    self.db = db;
    if (![db selectTableWithTableName:touristTableName] || ![db selectTableDataWithTableName:touristTableName]) {
        //如果表不存在或者表的数据为空
        [self showTouristView];
    } else {
        //显示tableView
        [self showTableView];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.touristArray = [self.db selectTouristAllDataWithCityType:self.cityType];
    [self.centerView reloadData];
}

-(void)showTouristView
{
    XMTravelassistantSetView *setView = [XMTravelassistantSetView setViewWithCenterImg:[UIImage imageNamed:@"viewpoint_nodata"] buttonNomalImg:[UIImage imageNamed:@"viewpoint_page_add_viewpoint_normal"] buttonHigImg:[UIImage imageNamed:@"viewpoint_page_add_viewpoint_press"]];
    setView.frame = self.view.frame;
    setView.delegate = self;
    self.setView = setView;
    [self.view addSubview:setView];
}


-(void)showTableView
{
    //添加底部按钮
    CGFloat buttomViewH = 50;
    XMTravelassistantTouristButtomView *buttomView = [[XMTravelassistantTouristButtomView alloc] initWithFrame:CGRectMake(0, viewHeight - buttomViewH, viewWidth, buttomViewH)];
    [buttomView OnViewClickListener:self action:@selector(travelassistantSetViewButtonClick)];
    [self.view addSubview:buttomView];
    
    //添加tableView
    UITableView *centerView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, viewWidth, viewHeight-buttomViewH-64)];
    centerView.allowsSelection = NO;
    centerView.rowHeight = 75;
    centerView.delegate = self;
    centerView.dataSource = self;
    centerView.backgroundColor = [UIColor clearColor];
    centerView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.centerView = centerView;
    [self.view addSubview:centerView];
    
}

#pragma mark - 点击添加景点
-(void)travelassistantSetViewButtonClick
{
    XMTravelassistantNewTourist *newTouristController = [[XMTravelassistantNewTourist alloc] init];
    newTouristController.delegate = self;
    newTouristController.date = self.date;
    newTouristController.cityType = self.cityType;
    [self.navigationController pushViewController:newTouristController animated:YES];
}

#pragma mark - tableView代理
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.touristArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XMTravelassistantTouristCell *cell = [XMTravelassistantTouristCell cellWithTableView:tableView];
    cell.model = self.touristArray[indexPath.row];
    cell.row = indexPath.row + 1;
    return cell;
}

-(void)travelassistantNewTouristCallBack
{
    if (self.centerView) {
        self.touristArray = [self.db selectTouristAllDataWithCityType:self.cityType];
        [self.centerView reloadData];
    } else {
        self.setView.hidden = YES;
        [self showTableView];
    }
}
@end
