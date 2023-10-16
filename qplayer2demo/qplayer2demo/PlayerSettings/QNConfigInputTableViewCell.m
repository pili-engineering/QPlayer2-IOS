//
//  QNConfigInputTableViewCell.m
//  QPlayerKitDemo
//
//  Created by 孙慕 on 2022/6/9.
//  Copyright © 2022 Aaron. All rights reserved.
//

#import "QNConfigInputTableViewCell.h"

@implementation QNConfigInputTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        _mConfigLabel = [[UILabel alloc] initWithFrame:CGRectMake(28, 15, PL_SCREEN_WIDTH - 56, 30)];
        _mConfigLabel.numberOfLines = 0;
        _mConfigLabel.textAlignment = NSTextAlignmentLeft;
        _mConfigLabel.font = PL_FONT_LIGHT(14);
        [self.contentView addSubview:_mConfigLabel];
        
        _mLineView = [[UIView alloc] initWithFrame:CGRectMake(28, 98, PL_SCREEN_WIDTH - 56, 0.5)];
        _mLineView.backgroundColor = PL_LINE_COLOR;
        [self.contentView addSubview:_mLineView];
    }
    return self;
}

- (void)configureSegmentCellWithConfigureModel:(PLConfigureModel *)configureModel {
    _mConfigureModel = configureModel;
    _mConfigLabel.text = configureModel.mConfiguraKey;
    
    [_mTextField removeFromSuperview];
    UITextField *tf = [[UITextField alloc] init];
    tf.backgroundColor = [UIColor whiteColor];
    tf.tintColor = PL_COLOR_RGB(16, 169, 235, 1);
    tf.keyboardType = UIKeyboardTypeNumberPad;
    tf.delegate = self;
    _mTextField = tf;
    _mTextField.text = [NSString stringWithFormat:@"%d",[configureModel.mConfiguraValue[0] intValue]];
    [self.contentView addSubview:_mTextField];

    CGRect bounds = [configureModel.mConfiguraKey boundingRectWithSize:CGSizeMake(PL_SCREEN_WIDTH - 56, 1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:[NSDictionary dictionaryWithObject:PL_FONT_LIGHT(14) forKey:NSFontAttributeName] context:nil];
    if (bounds.size.height > 30) {
        _mConfigLabel.frame = CGRectMake(28, 15, PL_SCREEN_WIDTH - 56, bounds.size.height);
        _mTextField.frame = CGRectMake(28, 60 + bounds.size.height - 30, PL_SCREEN_WIDTH - 56, 30);
        _mLineView.frame = CGRectMake(28, 98 + bounds.size.height - 30, PL_SCREEN_WIDTH - 56, 0.5);
    } else{
        _mTextField.frame = CGRectMake(28, 60, PL_SCREEN_WIDTH - 56, 30);
    }
}

+ (CGFloat)configureSegmentCellHeightWithString:(NSString *)string {
    CGRect bounds = [string boundingRectWithSize:CGSizeMake(PL_SCREEN_WIDTH - 56, 1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:[NSDictionary dictionaryWithObject:PL_FONT_LIGHT(14) forKey:NSFontAttributeName] context:nil];
    if (bounds.size.height > 30) {
        return 99 + bounds.size.height - 30;
    } else{
        return 99;
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


-(BOOL)textFieldShouldReturn:(UITextField *)textField
{

    [_mConfigureModel.mConfiguraValue replaceObjectAtIndex:0 withObject:@([textField.text intValue])];
    
[textField resignFirstResponder]; //回收键盘
return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    [_mConfigureModel.mConfiguraValue replaceObjectAtIndex:0 withObject:@([textField.text intValue])];
}


@end
