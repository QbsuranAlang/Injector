//
//  IJTPickerView.m
//  Injector
//
//  Created by 聲華 陳 on 2015/8/24.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTPickerView.h"

@implementation IJTPickerView

+ (CZPickerView *)pickerViewTitle: (NSString *)title target: (id)target {
    CZPickerView *picker = [[CZPickerView alloc] initWithHeaderTitle:title cancelButtonTitle:@"Cancel" confirmButtonTitle:@"Confirm"];
    picker.headerBackgroundColor = [UIColor darkGrayColor];
    picker.confirmButtonBackgroundColor = [UIColor darkGrayColor];
    picker.delegate = target;
    picker.dataSource = target;
    picker.needFooterView = YES;
    return picker;
}
@end
