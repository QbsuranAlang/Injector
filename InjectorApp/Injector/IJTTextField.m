//
//  IJTTextField.m
//  Injector
//
//  Created by 聲華 陳 on 2015/8/25.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTTextField.h"
#import "IJTBaseViewController.h"
@implementation IJTTextField

+ (FUITextField *)baseTextFieldWithTarget:(id)target {
    FUITextField *textField = [[FUITextField alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 44)];
    textField.keyboardType = UIKeyboardTypeASCIICapable;
    textField.returnKeyType = UIReturnKeyNext;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.delegate = target;
    textField.adjustsFontSizeToFitWidth = YES;
    return textField;
}
@end
