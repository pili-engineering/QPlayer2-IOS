//
//  PLPlayeConfigViewController.m
//  QPlayerKitDemo
//
//  Created by 冯文秀 on 2017/10/18.
//  Copyright © 2017年 qiniu. All rights reserved.
//

#import "QNPlayerConfigViewController.h"


#import "QNConfigSegTableViewCell.h"
#import "QNPlayerViewController.h"
#import "QNConfigInputTableViewCell.h"
#import "QDataHandle.h"

@interface QNPlayerConfigViewController ()
<
UITableViewDelegate,
UITableViewDataSource
>

@property (nonatomic, strong) UITableView *mPlayerConfigTableView;
@property (nonatomic, strong) NSArray<QNClassModel*> *mPlayerConfigArray;

@end

@implementation QNPlayerConfigViewController
static NSString *sSegmentIdentifier = @"segmentCell";
static NSString *sListIdentifier = @"listCell";

- (void)dealloc {
    NSLog(@"QNPlayerConfigViewController - dealloc");
}
-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self saveConfigurations];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self layoutPlayerConfigView];
    
    self.mPlayerConfigArray =  [QDataHandle shareInstance].mPlayerConfigArray;
}


#pragma mark - 标题

- (void)layoutPlayerConfigView {
    UILabel *titleLab = [[UILabel alloc] init];
    titleLab.font = PL_FONT_MEDIUM(16);
    titleLab.text = @"PLPlayer 点播设置";

    [self.view addSubview:titleLab];
    [titleLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(200, 34));
        make.leftMargin.mas_equalTo(PL_SCREEN_WIDTH/2 - 100);
        CGFloat topSpace = 20;
        if (PL_iPhoneX ||PL_iPhoneXR || PL_iPhoneXSMAX) {
            topSpace = 9;
        }
        make.topMargin.mas_equalTo(topSpace);
    }];
    titleLab.textAlignment = NSTextAlignmentCenter;
    
    UIButton *closeButton = [[UIButton alloc] init];
    closeButton.layer.cornerRadius = 17;
    closeButton.backgroundColor = PL_BUTTON_BACKGROUNDCOLOR;
    [closeButton addTarget:self action:@selector(closeButtonAction) forControlEvents:UIControlEventTouchDown];
    [closeButton setImage:[UIImage imageNamed:@"pl_back"] forState:UIControlStateNormal];
    [self.view addSubview:closeButton];
    [closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(100, 34));
        make.left.mas_equalTo(8);
        CGFloat topSpace = 20;
        if (PL_HAS_NOTCH) {
            topSpace = 8;
        }
        make.topMargin.mas_equalTo(topSpace);
    }];
    
    self.mPlayerConfigTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 78, PL_SCREEN_WIDTH, PL_SCREEN_HEIGHT - 78) style:UITableViewStylePlain];
    self.mPlayerConfigTableView.backgroundColor = [UIColor whiteColor];
    self.mPlayerConfigTableView.delegate = self;
    self.mPlayerConfigTableView.dataSource = self;
    self.mPlayerConfigTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.mPlayerConfigTableView registerClass:[QNConfigSegTableViewCell class] forCellReuseIdentifier:sSegmentIdentifier];
    [self.mPlayerConfigTableView registerClass:[QNConfigInputTableViewCell class] forCellReuseIdentifier:sListIdentifier];
    [self.view addSubview:_mPlayerConfigTableView];
    
    UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeKeyboard:)];
    singleTapGesture.numberOfTapsRequired = 1;
    singleTapGesture.cancelsTouchesInView = NO;
    [self.mPlayerConfigTableView addGestureRecognizer:singleTapGesture];
}


#pragma mark - gesture actions
- (void)closeKeyboard:(UITapGestureRecognizer *)recognizer {
     //在对应的手势触发方法里面让键盘失去焦点
    [self.view endEditing:YES];
 }


#pragma mark - tableview delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _mPlayerConfigArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    QNClassModel *classModel = _mPlayerConfigArray[section];
    NSArray *array = classModel.classValue;
    return array.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {    
    QNClassModel *classModel = _mPlayerConfigArray[indexPath.section];
    NSArray *array = classModel.classValue;
    PLConfigureModel *configureModel = array[indexPath.row];
    NSArray *rowArray = configureModel.mConfiguraValue;
    if (indexPath.row != 0) {
        QNConfigSegTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:sSegmentIdentifier forIndexPath:indexPath];
        [cell configureSegmentCellWithConfigureModel:configureModel];
        cell.mSegmentControl.tag = 100 * indexPath.section + indexPath.row;
        [cell.mSegmentControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    } else{
        QNConfigInputTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:sListIdentifier forIndexPath:indexPath];
        [cell configureSegmentCellWithConfigureModel:configureModel];
        cell.mTextField.tag = 100 * indexPath.section + indexPath.row;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    QNClassModel *classModel = _mPlayerConfigArray[indexPath.section];
    NSArray *array = classModel.classValue;
    PLConfigureModel *configureModel = array[indexPath.row];
    return [QNConfigSegTableViewCell configureSegmentCellHeightWithString:configureModel.mConfiguraKey];
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40.0f;
}

#pragma mark - segment action

- (void)segmentAction:(UISegmentedControl *)segment {
    NSInteger section = segment.tag / 100;
    NSInteger row = segment.tag % 100;
    QNClassModel *classModel = _mPlayerConfigArray[section];
    NSArray *array = classModel.classValue;
    PLConfigureModel *configureModel = array[row];
    
    [self controlPropertiesWithIndex:segment.selectedSegmentIndex configureModel:configureModel classModel:classModel];
}

- (void)controlPropertiesWithIndex:(NSInteger)index configureModel:(PLConfigureModel *)configureModel classModel:(QNClassModel *)classModel {
    configureModel.mSelectedNum = [NSNumber numberWithInteger:index];
    [_mPlayerConfigTableView reloadData];
    
    
}

- (void)closeButtonAction {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - 数据保存

- (void)saveConfigurations {
    NSMutableArray *dataArr = [NSMutableArray array];
    for (QNClassModel * classModel in _mPlayerConfigArray) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:classModel];
        [dataArr addObject:data];
    }
    NSUserDefaults *userdafault = [NSUserDefaults standardUserDefaults];
    [userdafault setObject:[NSArray arrayWithArray:dataArr] forKey:@"PLPlayer_settings"];
    [userdafault synchronize];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
