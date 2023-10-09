//
//  QNURLListTableViewCell.m
//  QPlayerKitDemo
//
//  Created by 冯文秀 on 2017/10/11.
//  Copyright © 2017年 qiniu. All rights reserved.
//

#import "QNURLListTableViewCell.h"

@implementation QNURLListTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.contentView.backgroundColor = PL_LINE_COLOR;
        
        self.mCellBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, PL_SCREEN_WIDTH, 34)];
        self.mCellBgView.backgroundColor = PL_BACKGROUND_COLOR;
        [self.contentView addSubview:self.mCellBgView];
        
        self.mNumberLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 2, 60, 30)];
        self.mNumberLabel.font = PL_FONT_LIGHT(13);
        self.mNumberLabel.textColor = PL_DARKRED_COLOR;
        self.mNumberLabel.textAlignment = NSTextAlignmentLeft;
        [self.mCellBgView addSubview:self.mNumberLabel];
        
        self.mUrlLabel = [[UILabel alloc] initWithFrame:CGRectMake(65, 2, PL_SCREEN_WIDTH - 41, 30)];
        self.mUrlLabel.numberOfLines = 0;
        self.mUrlLabel.font = PL_FONT_LIGHT(14);
        self.mUrlLabel.textColor = PL_DARK_COLOR;
        self.mUrlLabel.textAlignment = NSTextAlignmentLeft;
        [self.mCellBgView addSubview:self.mUrlLabel];
        
        self.mDeleteButton = [[UIButton alloc] initWithFrame:CGRectMake(PL_SCREEN_WIDTH - 31, 5, 26, 24)];
        self.mDeleteButton.userInteractionEnabled = YES;
        [self.mDeleteButton setImage:[UIImage imageNamed:@"pl_delete"] forState:UIControlStateNormal];
        [self.mCellBgView addSubview:self.mDeleteButton];
    }
    return self;
}

- (void)configureListURLString:(NSString *)urlString index:(NSInteger)index{
    self.mNumberLabel.text = [NSString stringWithFormat:@"No.%ld", index + 1];
    CGRect numberBounds = [self.mNumberLabel.text boundingRectWithSize:CGSizeMake(10000, 30) options:NSStringDrawingUsesLineFragmentOrigin attributes:[NSDictionary dictionaryWithObject:PL_FONT_LIGHT(13) forKey:NSFontAttributeName] context:nil];
    self.mUrlLabel.text = urlString;
    CGRect bounds = [self.mUrlLabel.text boundingRectWithSize:CGSizeMake(PL_SCREEN_WIDTH - 46 - numberBounds.size.width, 10000) options:NSStringDrawingUsesLineFragmentOrigin attributes:[NSDictionary dictionaryWithObject:PL_FONT_MEDIUM(14) forKey:NSFontAttributeName] context:nil];
    if (bounds.size.height > 30) {
        self.mUrlLabel.frame = CGRectMake(10 + numberBounds.size.width, 2, PL_SCREEN_WIDTH - 46 - numberBounds.size.width, bounds.size.height);
        self.mNumberLabel.frame = CGRectMake(5, bounds.size.height/2 - 13, numberBounds.size.width, 30);
        self.mDeleteButton.frame = CGRectMake(PL_SCREEN_WIDTH - 31, bounds.size.height/2 - 10, 26, 24);
        self.mCellBgView.frame = CGRectMake(0, 0, PL_SCREEN_WIDTH, bounds.size.height + 4);
    } else{
        self.mUrlLabel.frame = CGRectMake(10 + numberBounds.size.width, 2, PL_SCREEN_WIDTH - 46 - numberBounds.size.width, 30);
        self.mNumberLabel.frame = CGRectMake(5, 2, numberBounds.size.width, 30);
        self.mDeleteButton.frame = CGRectMake(PL_SCREEN_WIDTH - 31, 5, 26, 24);
        self.mCellBgView.frame = CGRectMake(0, 0, PL_SCREEN_WIDTH, 34);
    }
}

+ (CGFloat)configureListCellHeightWithURLString:(NSString *)urlString index:(NSInteger)index {
    NSString *numberString = [NSString stringWithFormat:@"No.%ld", index];
    CGRect numberBounds = [numberString boundingRectWithSize:CGSizeMake(10000, 30) options:NSStringDrawingUsesLineFragmentOrigin attributes:[NSDictionary dictionaryWithObject:PL_FONT_LIGHT(13) forKey:NSFontAttributeName] context:nil];
    
    CGRect bounds = [urlString boundingRectWithSize:CGSizeMake(PL_SCREEN_WIDTH - 46 - numberBounds.size.width, 10000) options:NSStringDrawingUsesLineFragmentOrigin attributes:[NSDictionary dictionaryWithObject:PL_FONT_MEDIUM(14) forKey:NSFontAttributeName] context:nil];
    
    if (bounds.size.height > 30) {
        return bounds.size.height + 4.5;
    } else{
        return 34.5;
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

@end
