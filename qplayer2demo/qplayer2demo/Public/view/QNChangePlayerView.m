//
//  StretchingPlayerView2.m
//  QPlay2-wang
//
//  Created by 王声禄 on 2022/7/6.
//

#import "QNChangePlayerView.h"

@implementation QNChangePlayerView{
    
    NSMutableArray * mButtonArray;
    NSMutableArray * mLabelArray;
    UIImage * mSelectedImage;
    UIImage * mNotSelectedImage;
    UIColor * mSelectedColor;
    UIColor * mNotSelectedColor;
    UIFont * mFont;
    UILabel * mTitleLabel;
}
-(instancetype)initWithFrame:(CGRect)frame backgroudColor:(UIColor*)color{
    self = [super initWithFrame:frame];
    if (self) {
        mButtonArray = [NSMutableArray array];
        mLabelArray = [NSMutableArray array];
        mSelectedImage = [UIImage imageNamed:@"selected"];
        mNotSelectedImage = [UIImage imageNamed:@"notSelected"];
        mNotSelectedColor = [UIColor whiteColor];
        mSelectedColor = [UIColor redColor];
        mFont = [UIFont systemFontOfSize:12.0f];
        self.backgroundColor = color;
        
    }
    return self;
}
-(void)setTitleLabelText:(NSString *)text frame:(CGRect)frame textColor:(UIColor *)textColor{
    if (mTitleLabel) {
        mTitleLabel.frame = frame;
        mTitleLabel.text = text;
        mTitleLabel.textColor =textColor;
    }
    else{
        
        mTitleLabel = [[UILabel alloc]initWithFrame:frame];
        mTitleLabel.text = text;
        mTitleLabel.textColor =textColor;
        [self addSubview:mTitleLabel];
    }
}
-(void)setDefault:(ChangeButtonType)type{
    for (UIButton *btn in mButtonArray) {
        if (btn.tag == type) {
            [btn setImage:mSelectedImage forState:UIControlStateNormal];
            btn.selected = YES;
        }
        else{
            [btn setImage:mNotSelectedImage forState:UIControlStateNormal];
            btn.selected = NO;
        }
    }
    for (UILabel *lab in mLabelArray) {
        if (lab.tag == type) {
            lab.textColor = mSelectedColor;
            
        }
        else{
            lab.textColor = mNotSelectedColor;
        }
    }
}
-(void)addButtonText:(NSString *)text frame:(CGRect)frame type:(ChangeButtonType)type target:(id)target selector:(SEL)selector selectorTag:(SEL)selectorTag{
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.height, frame.size.height)];
    UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(btn.frame.size.width +btn.frame.origin.x + 3, frame.origin.y, frame.size.width - frame.size.height -6, frame.size.height)];
    bool isExist = false;
    
    for (UIButton *arrbtn in mButtonArray) {
        if (arrbtn.tag == type) {
            btn = arrbtn;
            isExist = true;
            break;
        }
    }
    if (isExist) {
        for (UILabel *arrlab in mLabelArray) {
            if(arrlab.tag == type){
                lab = arrlab;
                break;
            }
        }
    }
    
    [btn setBackgroundColor:[UIColor clearColor]];
    [btn setImage:mNotSelectedImage forState:UIControlStateNormal];
    btn.selected = NO;
    btn.tag = type;
    [btn addTarget:self action:@selector(Click:) forControlEvents:UIControlEventTouchUpInside];
    [btn addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    lab.backgroundColor = [UIColor clearColor];
    lab.text = text;
    lab.textColor = mNotSelectedColor;
    lab.tag = type;
    lab.font = mFont;
    lab.userInteractionEnabled =YES;
    UITapGestureRecognizer *tag = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(GestureClick:)];
    [tag addTarget:target action:selectorTag];
    
    if (!isExist) {
        [lab addGestureRecognizer:tag];
        
        [mButtonArray addObject:btn];
        [mLabelArray addObject:lab];
        [self addSubview:btn];
        [self addSubview:lab];
    }
}
-(void)GestureClick:(UITapGestureRecognizer *)tap{

    for (int i = 0; i < mButtonArray.count; i++) {
        UIButton *midBtn = mButtonArray[i];
        UILabel *midlab = mLabelArray[i];
        if (midBtn.tag == tap.view.tag) {
            if ((ChangeButtonType)midBtn.tag == BUTTON_TYPE_SEI_DATA || (ChangeButtonType)midBtn.tag == BUTTON_TYPE_AUTHENTICATION || (ChangeButtonType)midBtn.tag == BUTTON_TYPE_BACKGROUND_PLAY) {
                if (midBtn.selected) {
                    midBtn.selected = NO;
                    [midBtn setImage:mNotSelectedImage forState:UIControlStateNormal];
                    midlab.textColor = mNotSelectedColor;
                }else{
                    midBtn.selected = YES;
                    [midBtn setImage:mSelectedImage forState:UIControlStateNormal];
                    midlab.textColor = mSelectedColor;
                }
                return;
            }
            else{
                
                [midBtn setImage:mSelectedImage forState:UIControlStateNormal];
                midlab.textColor = mSelectedColor;
                midBtn.selected = YES;
            }
        }
        else{
            [midBtn setImage:mNotSelectedImage forState:UIControlStateNormal];
            midlab.textColor = mNotSelectedColor;
            midBtn.selected = NO;
        }
    }
}
-(void)Click:(UIButton *)btn{
    for (int i = 0; i < mButtonArray.count; i++) {
        UIButton *midBtn = mButtonArray[i];
        UILabel *midlab = mLabelArray[i];
        if (midBtn.tag == btn.tag) {
            if ((ChangeButtonType)btn.tag == BUTTON_TYPE_SEI_DATA || (ChangeButtonType)btn.tag == BUTTON_TYPE_AUTHENTICATION || (ChangeButtonType)btn.tag == BUTTON_TYPE_BACKGROUND_PLAY) {
                if (midBtn.selected) {
                    midBtn.selected = NO;
                    [midBtn setImage:mNotSelectedImage forState:UIControlStateNormal];
                    midlab.textColor = mNotSelectedColor;
                }else{
                    midBtn.selected = YES;
                    [midBtn setImage:mSelectedImage forState:UIControlStateNormal];
                    midlab.textColor = mSelectedColor;
                }
                return;
            }

            [midBtn setImage:mSelectedImage forState:UIControlStateNormal];
            midlab.textColor = mSelectedColor;
            midBtn.selected = YES;
        }
        else{
            [midBtn setImage:mNotSelectedImage forState:UIControlStateNormal];
            midlab.textColor = mNotSelectedColor;
            midBtn.selected = NO;
        }
    }
}
-(void)setButtonFrame:(CGRect)frame type:(ChangeButtonType)type{
    BOOL success = false;
    for (UIButton *btn in mButtonArray) {
        if (btn.tag == type) {
            success = true;
            btn.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.height, frame.size.height);
        }
    }
    for (UILabel *lab in mLabelArray) {
        if (lab.tag == type) {
            success = true;
            lab.frame = CGRectMake(frame.origin.x + frame.size.height + 3, frame.origin.y, frame.size.width - frame.size.height -3, frame.size.height);
        }
    }
    if (!success) {
        NSLog(@"StretchingPlayerView 设置button失败，不存在改button。");
    }
}
-(void)setButtonTitle:(NSString *)title type:(ChangeButtonType)type{
    BOOL success = false;
    for (UILabel *lab in mLabelArray) {
        if (lab.tag == type) {
            success = true;
            lab.text = title;
        }
    }
    if (!success) {
        NSLog(@"StretchingPlayerView 设置button失败，不存在改button。");
    }
}
-(void)setButtonFont:(UIFont *)myfont{
    mFont = myfont;
    for (UILabel  *lab in mLabelArray) {
        lab.font = myfont;
    }
}
-(void)setButtonNotSelectedTitleColor:(UIColor *)titleColor{

    mNotSelectedColor = titleColor;
    for (UILabel *lab in mLabelArray) {
        lab.textColor = mNotSelectedColor;
    }
}

-(void)setButtonSelectedTitleColor:(UIColor *)titleColor{
    mSelectedColor = titleColor;
}


-(void)deleteButton:(ChangeButtonType)type{
    BOOL success = false;
    NSMutableArray *arr = [NSMutableArray array];
    NSMutableArray *arrlab = [NSMutableArray array];
    for (int i =0 ; i < mButtonArray.count; i++) {
        UIButton * btn = mButtonArray[i];
        UILabel *lab = mLabelArray [i];
        if (btn.tag == type) {
            [btn removeFromSuperview];
            [lab removeFromSuperview];
            success = true;
        }else{
            [arr addObject:btn];
            [arrlab addObject:lab];
        }
    }
    
    
    if (!success) {
        NSLog(@"StretchingPlayerView 删除button失败，不存在改button。");
    }else{
        mButtonArray = arr;
        mLabelArray = arrlab;
    }
}



-(void)setButtonNotSelectedImage:(UIImage *)Image{
    mNotSelectedImage = Image;
    for (UIButton *btn in mButtonArray) {
        [btn setImage:mNotSelectedImage forState:UIControlStateNormal];
    }
}
-(void)setButtonSelectedImage:(UIImage *)Image{
    mSelectedImage = Image;
}

-(BOOL)getButtonSelected:(ChangeButtonType)type{
    for (UIButton *midBtn in mButtonArray) {
        if (midBtn.tag == type) {
            return midBtn.selected;
        }
    }
    return NO;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
